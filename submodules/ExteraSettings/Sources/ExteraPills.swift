import Foundation

public enum ExteraPill: String, CaseIterable, Codable {
    case memory
    case proxy

    public func title(_ strings: ExteraStrings) -> String {
        switch self {
        case .memory: return strings.text("App memory", "Память приложения")
        case .proxy: return strings.text("Proxy", "Прокси")
        }
    }

    public var symbol: String {
        switch self {
        case .memory: return "memorychip"
        case .proxy: return "shield"
        }
    }
}

public struct ExteraPillConfiguration: Codable, Equatable {
    public enum Material: Int, CaseIterable, Codable {
        case telegram
        case classic
        case glass

        public func title(_ strings: ExteraStrings) -> String {
            switch self {
            case .telegram: return "Telegram"
            case .classic: return "Classic iOS"
            case .glass: return strings.text("Glass", "Стекло")
            }
        }
    }

    public static let refreshIntervals = [15, 30, 60, 300]

    public var widgets: [ExteraPill] = []
    public var refreshInterval = 30
    public var capsuleHeight = 34
    public var cornerRadius = 16
    public var opacity = 90
    public var material: Material = .telegram
    public var aboveFolders = false
    public var loops = false

    public init() {}

    public var normalized: Self {
        var result = self
        var used = Set<ExteraPill>()
        result.widgets = self.widgets.filter { used.insert($0).inserted }
        result.refreshInterval = Self.refreshIntervals.contains(self.refreshInterval) ? self.refreshInterval : 30
        result.capsuleHeight = min(46, max(30, self.capsuleHeight))
        result.cornerRadius = min(23, max(0, self.cornerRadius))
        result.opacity = min(100, max(30, self.opacity))
        return result
    }

    public mutating func setEnabled(_ enabled: Bool, widget: ExteraPill) {
        if enabled {
            if !self.widgets.contains(widget) {
                self.widgets.append(widget)
            }
        } else {
            self.widgets.removeAll { $0 == widget }
        }
    }

    public mutating func moveUp(_ widget: ExteraPill) {
        guard let index = self.widgets.firstIndex(of: widget), index > 0 else { return }
        self.widgets.swapAt(index - 1, index)
    }
}
