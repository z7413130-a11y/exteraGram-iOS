import Foundation

public enum ExteraTab: String, CaseIterable, Codable {
    case calls, news, chats, settings

    public func title(_ strings: ExteraStrings) -> String {
        switch self {
        case .calls: return strings.text("Calls", "Звонки")
        case .news: return strings.text("News", "Новости")
        case .chats: return strings.text("Chats", "Чаты")
        case .settings: return strings.text("Settings", "Настройки")
        }
    }

    public var symbol: String {
        switch self {
        case .calls: return "phone"
        case .news: return "newspaper"
        case .chats: return "bubble.left.and.bubble.right"
        case .settings: return "gearshape"
        }
    }
}

public struct ExteraNavigationAppearance: Equatable {
    public var order: [ExteraTab]
    public let hidesCalls: Bool
    public let hidesNews: Bool
    public let drawerMode: ExteraDrawerMode
    public let hidesLabels: Bool
    public let iconPack: ExteraIconPack
    public let motion: ExteraMotion
    public let geometry: ExteraGeometry
    public let sectionRadius: Double
    public let interface: ExteraInterfaceAppearance

    public init(store: ExteraSettingsStore = .shared, previewingBoth: Bool = false) {
        self.order = Self.completeOrder(store.value(for: ExteraPreferences.rootTabOrder))
        self.hidesCalls = store.value(for: ExteraPreferences.hideCallsTab)
        self.hidesNews = store.value(for: ExteraPreferences.hideNewsTab)
        self.hidesLabels = store.value(for: ExteraPreferences.hideNavigationBarLabels)
        let appearance = store.value(for: ExteraPreferences.interfaceAppearance).normalized
        self.iconPack = ExteraIconPack(store: store)
        self.motion = ExteraMotion(store: store)
        self.geometry = store.value(for: ExteraPreferences.geometry).normalized
        self.sectionRadius = min(32, max(0, store.value(for: ExteraPreferences.sectionRadius)))
        self.interface = appearance.resolved(for: store.value(for: ExteraPreferences.interfaceStyle))
        self.drawerMode = previewingBoth ? .both : appearance.drawerMode(enabled: store.value(for: ExteraPreferences.navigationDrawer))
    }

    public static func completeOrder(_ order: [ExteraTab]) -> [ExteraTab] {
        var seen = Set<ExteraTab>()
        return (order + ExteraTab.allCases).filter { seen.insert($0).inserted }
    }
}
