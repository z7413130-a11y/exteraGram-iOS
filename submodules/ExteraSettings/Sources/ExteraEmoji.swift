import CoreText
import UIKit

public enum ExteraEmojiStyle: Int, CaseIterable, Codable {
    case system, noto

    public func title(_ strings: ExteraStrings) -> String {
        switch self {
        case .system: return strings.text("iOS emoji", "Эмодзи iOS")
        case .noto: return strings.text("Noto Emoji (monochrome)", "Noto Emoji (монохромные)")
        }
    }

    private static let font: (name: String, coverage: CharacterSet)? = {
        guard let url = Bundle.main.url(forResource: "ExteraNotoEmoji", withExtension: "ttf"),
              let provider = CGDataProvider(url: url as CFURL),
              let graphicsFont = CGFont(provider),
              let name = graphicsFont.postScriptName as String? else { return nil }
        _ = CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        guard let font = UIFont(name: name, size: 16) else { return nil }
        let coreTextFont = CTFontCreateWithName(font.fontName as CFString, 16, nil)
        return (font.fontName, CTFontCopyCharacterSet(coreTextFont) as CharacterSet)
    }()

    public func applying(to text: NSAttributedString, keepingAttribute: NSAttributedString.Key? = nil) -> NSAttributedString {
        guard self == .noto, let face = Self.font else { return text }
        var result: NSMutableAttributedString?
        var offset = 0
        for character in text.string.prefix(256) {
            let range = NSRange(location: offset, length: String(character).utf16.count)
            offset += range.length
            guard character.unicodeScalars.count == 1, let scalar = character.unicodeScalars.first,
                  scalar.properties.isEmojiPresentation, face.coverage.contains(scalar),
                  keepingAttribute.map({ text.attribute($0, at: range.location, effectiveRange: nil) == nil }) ?? true,
                  let current = text.attribute(.font, at: range.location, effectiveRange: nil) as? UIFont,
                  let font = UIFont(name: face.name, size: current.pointSize) else { continue }
            if result == nil { result = NSMutableAttributedString(attributedString: text) }
            result?.addAttribute(.font, value: font, range: range)
        }
        return result ?? text
    }
}
