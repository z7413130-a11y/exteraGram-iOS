import Foundation

public enum ExteraSectionDivider: Int, CaseIterable, Codable {
    case standard, hidden, line, segments

    public func title(_ strings: ExteraStrings) -> String {
        switch self {
        case .standard: return strings.text("Standard", "Стандартные")
        case .hidden: return strings.text("Hidden", "Скрытые")
        case .line: return strings.text("Lines", "Линии")
        case .segments: return strings.text("Segments", "Сегменты")
        }
    }
}

public struct ExteraGeometry: Codable, Equatable {
    public var buttonRadius = 10
    public var spacing = 10
    public var insets = 12
    public var sectionHeaders = false
    public var dividers: ExteraSectionDivider = .standard

    public init() {}

    public var normalized: Self {
        var copy = self
        copy.buttonRadius = min(22, max(0, self.buttonRadius))
        copy.spacing = min(24, max(4, self.spacing))
        copy.insets = min(24, max(8, self.insets))
        return copy
    }
}
