import Foundation

public enum ExteraPill: String, CaseIterable, Codable {
    case memory
    case proxy
    case weather, btc, gram, currency, custom, custom2, custom3

    public func title(_ strings: ExteraStrings) -> String {
        switch self {
        case .memory: return strings.text("App memory", "Память приложения")
        case .proxy: return strings.text("Proxy", "Прокси")
        case .weather: return strings.text("Weather", "Погода")
        case .btc: return "BTC"
        case .gram: return "GRAM (TON)"
        case .currency: return "USD / EUR"
        case .custom: return strings.text("Custom 1", "Своя капсула 1")
        case .custom2: return strings.text("Custom 2", "Своя капсула 2")
        case .custom3: return strings.text("Custom 3", "Своя капсула 3")
        }
    }

    public var symbol: String {
        switch self {
        case .memory: return "memorychip"
        case .proxy: return "shield"
        case .weather: return "cloud.sun"
        case .btc: return "bitcoinsign.circle"
        case .gram: return "diamond"
        case .currency: return "eurosign.circle"
        case .custom, .custom2, .custom3: return "text.bubble"
        }
    }

    public static let customSlots: [Self] = [.custom, .custom2, .custom3]

    public var usesNetwork: Bool {
        return self == .weather || self == .btc || self == .gram || self == .currency
    }
}

public enum ExteraWeatherCity: String, Codable, CaseIterable {
    case krasnoyarsk, moscow, london, berlin, newYork, tokyo

    public func title(_ strings: ExteraStrings) -> String {
        switch self {
        case .krasnoyarsk: return strings.text("Krasnoyarsk", "Красноярск")
        case .moscow: return strings.text("Moscow", "Москва")
        case .london: return strings.text("London", "Лондон")
        case .berlin: return strings.text("Berlin", "Берлин")
        case .newYork: return strings.text("New York", "Нью-Йорк")
        case .tokyo: return strings.text("Tokyo", "Токио")
        }
    }

    var coordinates: (String, String) {
        switch self {
        case .krasnoyarsk: return ("56.01", "92.87")
        case .moscow: return ("55.75", "37.62")
        case .london: return ("51.51", "-0.13")
        case .berlin: return ("52.52", "13.41")
        case .newYork: return ("40.71", "-74.01")
        case .tokyo: return ("35.68", "139.69")
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
    public var allowExternalSources: Bool?
    public var weatherCity: ExteraWeatherCity?
    public var customText: String?
    private var additionalCustomText: [String: String]?

    public init() {}

    public var normalized: Self {
        var result = self
        var used = Set<ExteraPill>()
        result.widgets = self.widgets.filter { used.insert($0).inserted }
        result.refreshInterval = Self.refreshIntervals.contains(self.refreshInterval) ? self.refreshInterval : 30
        result.capsuleHeight = min(46, max(30, self.capsuleHeight))
        result.cornerRadius = min(23, max(0, self.cornerRadius))
        result.opacity = min(100, max(30, self.opacity))
        for slot in ExteraPill.customSlots {
            if let value = self.text(for: slot) { result.setText(value, for: slot) }
        }
        return result
    }

    public func text(for widget: ExteraPill) -> String? {
        return widget == .custom ? self.customText : self.additionalCustomText?[widget.rawValue]
    }

    public mutating func setText(_ text: String, for widget: ExteraPill) {
        guard ExteraPill.customSlots.contains(widget) else { return }
        let clean = String(text.trimmingCharacters(in: .whitespacesAndNewlines).prefix(48))
        let value = clean.isEmpty ? nil : clean
        if widget == .custom {
            self.customText = value
        } else {
            var additional = self.additionalCustomText ?? [:]
            additional[widget.rawValue] = value
            self.additionalCustomText = additional.isEmpty ? nil : additional
        }
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
