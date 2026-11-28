import Foundation

public enum ExteraDrawerMode: Int, CaseIterable, Codable {
    case tabs, drawer, both

    public func title(_ text: ExteraStrings) -> String {
        switch self {
        case .tabs: return text.text("Tab bar", "Нижняя панель")
        case .drawer: return text.text("Side menu", "Боковое меню")
        case .both: return text.text("Tab bar and side menu", "Нижняя панель и боковое меню")
        }
    }
}

public enum ExteraBarStyle: Int, CaseIterable, Codable {
    case telegram, floating, glass

    public func title(_ text: ExteraStrings) -> String {
        switch self {
        case .telegram: return "Telegram"
        case .floating: return text.text("Floating", "Плавающая")
        case .glass: return text.text("Glass", "Стеклянная")
        }
    }
}

public enum ExteraSurfaceStyle: Int, CaseIterable, Codable {
    case telegram, classic, liquidGlass

    public func title(_ text: ExteraStrings) -> String {
        switch self {
        case .telegram: return "Telegram"
        case .classic: return "Classic iOS"
        case .liquidGlass: return "Liquid Glass"
        }
    }
}

public enum ExteraDrawerItem: String, CaseIterable, Codable {
    case chats, newChat, contacts, calls, news, extera, settings, accounts

    public var locked: Bool {
        return self == .chats || self == .extera || self == .settings
    }

    public var symbol: String {
        switch self {
        case .chats: return "bubble.left.and.bubble.right"
        case .newChat: return "square.and.pencil"
        case .contacts: return "person.crop.circle"
        case .calls: return "phone"
        case .news: return "newspaper"
        case .extera: return "paintpalette"
        case .settings: return "gearshape"
        case .accounts: return "person.2"
        }
    }

    public func title(_ text: ExteraStrings) -> String {
        switch self {
        case .chats: return ExteraTab.chats.title(text)
        case .newChat: return text.text("New message", "Новое сообщение")
        case .contacts: return text.text("Contacts", "Контакты")
        case .calls: return ExteraTab.calls.title(text)
        case .news: return ExteraTab.news.title(text)
        case .extera: return "exteraGram"
        case .settings: return ExteraTab.settings.title(text)
        case .accounts: return text.text("Accounts", "Аккаунты")
        }
    }
}

public struct ExteraInterfaceAppearance: Codable, Equatable {
    public var drawerOnly = false
    public var drawerOrder = ExteraDrawerItem.allCases
    public var hiddenDrawerItems: Set<ExteraDrawerItem> = []
    public var drawerWidth = 80
    public var drawerOpacity = 92
    public var barStyle: ExteraBarStyle = .telegram
    public var barRadius = 24
    public var surfaceStyle: ExteraSurfaceStyle = .telegram
    public var inheritBarStyle: Bool?
    public var inheritDrawerStyle: Bool?

    public func resolved(for style: ExteraSurfaceStyle) -> Self {
        var result = self.normalized
        if self.inheritBarStyle ?? (self.barStyle == .telegram) {
            switch style {
            case .telegram: result.barStyle = .telegram
            case .classic: result.barStyle = .floating
            case .liquidGlass: result.barStyle = .glass
            }
        }
        if self.inheritDrawerStyle ?? (self.surfaceStyle == .telegram) { result.surfaceStyle = style }
        return result
    }

    public init() {}

    public var normalized: Self {
        var result = self
        var seen = Set<ExteraDrawerItem>()
        result.drawerOrder = (self.drawerOrder + ExteraDrawerItem.allCases).filter { seen.insert($0).inserted }
        result.hiddenDrawerItems = self.hiddenDrawerItems.filter { !$0.locked }
        result.drawerWidth = min(90, max(60, self.drawerWidth))
        result.drawerOpacity = min(100, max(65, self.drawerOpacity))
        result.barRadius = min(32, max(8, self.barRadius))
        return result
    }

    public func drawerMode(enabled: Bool) -> ExteraDrawerMode {
        if !enabled { return .tabs }
        return self.drawerOnly ? .drawer : .both
    }

    public mutating func moveUp(_ item: ExteraDrawerItem) {
        guard let index = self.drawerOrder.firstIndex(of: item), index > 0 else { return }
        self.drawerOrder.swapAt(index, index - 1)
    }
}
