import Foundation

public enum ExteraChatTheme: Int, CaseIterable, Codable {
    case inherited, ocean, moss, dusk, graphite

    public func title(_ strings: ExteraStrings) -> String {
        switch self {
        case .inherited: return strings.text("Follow chat appearance", "Как в настройках чата")
        case .ocean: return strings.text("Ocean", "Океан")
        case .moss: return strings.text("Moss", "Мох")
        case .dusk: return strings.text("Dusk", "Сумерки")
        case .graphite: return strings.text("Graphite", "Графит")
        }
    }

    public struct Palette {
        public let accent: UInt32
        public let wallpaper: UInt32
        public let outgoing: UInt32
    }

    public func palette(dark: Bool) -> Palette? {
        switch self {
        case .inherited: return nil
        case .ocean: return dark ? Palette(accent: 0x8DD8FF, wallpaper: 0x122635, outgoing: 0x194B67) :
            Palette(accent: 0x00628F, wallpaper: 0xDCECF4, outgoing: 0xC0E7FF)
        case .moss: return dark ? Palette(accent: 0xABD795, wallpaper: 0x1C2922, outgoing: 0x385348) :
            Palette(accent: 0x3D6645, wallpaper: 0xE0EDDC, outgoing: 0xD1E8C6)
        case .dusk: return dark ? Palette(accent: 0xE7B7FF, wallpaper: 0x2C2334, outgoing: 0x573967) :
            Palette(accent: 0x705089, wallpaper: 0xF4E4F4, outgoing: 0xEFDBFB)
        case .graphite: return dark ? Palette(accent: 0xC1CDE0, wallpaper: 0x21242A, outgoing: 0x3A414D) :
            Palette(accent: 0x4D5D73, wallpaper: 0xEAECEF, outgoing: 0xDBE1EB)
        }
    }

    public static func key(account: Int64, peer: Int64) -> String { "\(account):\(peer)" }
}
