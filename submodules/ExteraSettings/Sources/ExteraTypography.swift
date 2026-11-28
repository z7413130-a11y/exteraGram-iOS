import UIKit

public enum ExteraTypeface: Int, CaseIterable, Codable {
    case telegram, system, rounded, serif, monospaced

    public func title(_ strings: ExteraStrings) -> String {
        switch self {
        case .telegram: return "Telegram"
        case .system: return strings.text("iOS system", "Системный iOS")
        case .rounded: return strings.text("Rounded", "Скруглённый")
        case .serif: return strings.text("Serif", "С засечками")
        case .monospaced: return strings.text("Monospaced", "Моноширинный")
        }
    }
}

public struct ExteraTypography: Codable, Equatable {
    public var typeface: ExteraTypeface = .telegram
    public var size = 100
    public var heavier = false
    public var emoji: ExteraEmojiStyle?

    public var emojiStyle: ExteraEmojiStyle { self.emoji ?? .system }

    public init() {}

    public var normalized: Self {
        var result = self
        result.size = min(125, max(85, self.size))
        return result
    }

    public func font(_ original: UIFont, weight: UIFont.Weight, italic: Bool = false) -> UIFont {
        let size = original.pointSize * CGFloat(self.normalized.size) / 100
        var font: UIFont
        if self.typeface == .telegram && !self.heavier {
            return abs(size - original.pointSize) < 0.01 ? original : original.withSize(size)
        }
        font = .systemFont(ofSize: size, weight: self.heavier ? (weight == .regular ? .medium : .bold) : weight)
        let design: UIFontDescriptor.SystemDesign
        switch self.typeface {
        case .telegram, .system: design = .default
        case .rounded: design = .rounded
        case .serif: design = .serif
        case .monospaced: design = .monospaced
        }
        if let descriptor = font.fontDescriptor.withDesign(design) {
            font = UIFont(descriptor: descriptor, size: size)
        }
        if italic, let descriptor = font.fontDescriptor.withSymbolicTraits(font.fontDescriptor.symbolicTraits.union(.traitItalic)) {
            font = UIFont(descriptor: descriptor, size: size)
        }
        return font
    }
}
