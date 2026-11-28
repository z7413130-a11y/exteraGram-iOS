import Foundation

public enum ExteraMenuMaterial: Int, CaseIterable, Codable {
    case telegram, frosted, transparent, liquidGlass, automatic

    public func title(_ strings: ExteraStrings) -> String {
        switch self {
        case .telegram: return "Telegram"
        case .automatic: return strings.text("Use interface style", "Как в интерфейсе")
        case .frosted: return strings.text("Frosted glass", "Матовое стекло")
        case .transparent: return strings.text("Clear glass", "Прозрачное стекло")
        case .liquidGlass: return "Liquid Glass"
        }
    }
}

public enum ExteraMenuOutline: Int, CaseIterable, Codable {
    case gleam, solid, hidden, standard

    public func title(_ strings: ExteraStrings) -> String {
        switch self {
        case .gleam: return strings.text("Highlights", "С бликами")
        case .solid: return strings.text("Solid border", "Сплошной контур")
        case .hidden: return strings.text("None", "Без контура")
        case .standard: return strings.text("Standard", "Стандартный")
        }
    }
}

public struct ExteraMenuAppearance: Codable, Equatable {
    public var material: ExteraMenuMaterial = .automatic
    public var radius = 26
    public var opacity = 76
    public var blur = 64
    public var saturation = 60
    public var gleam = 40

    public init() {}

    public func resolved(for style: ExteraSurfaceStyle) -> Self {
        var copy = self.normalized
        if self.material == .automatic {
            switch style {
            case .telegram: copy.material = .telegram
            case .classic: copy.material = .frosted
            case .liquidGlass: copy.material = .liquidGlass
            }
        }
        return copy
    }

    public var normalized: Self {
        var copy = self
        copy.radius = min(36, max(8, self.radius))
        copy.opacity = min(100, max(45, self.opacity))
        copy.blur = min(100, max(0, self.blur))
        copy.saturation = min(100, max(0, self.saturation))
        copy.gleam = min(100, max(0, self.gleam))
        return copy
    }
}
