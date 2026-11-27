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

    public init(store: ExteraSettingsStore = .shared) {
        self.order = Self.completeOrder(store.value(for: ExteraPreferences.rootTabOrder))
        self.hidesCalls = store.value(for: ExteraPreferences.hideCallsTab)
        self.hidesNews = store.value(for: ExteraPreferences.hideNewsTab)
    }

    public static func completeOrder(_ order: [ExteraTab]) -> [ExteraTab] {
        var seen = Set<ExteraTab>()
        return (order + ExteraTab.allCases).filter { seen.insert($0).inserted }
    }
}
