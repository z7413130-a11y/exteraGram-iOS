import UIKit

public enum ExteraBuiltInIconPack: Int, CaseIterable {
    case standard, solar, remix

    public func title(_ strings: ExteraStrings) -> String {
        switch self {
        case .standard: return strings.text("Default", "Стандартный")
        case .solar: return "Solar"
        case .remix: return "Remix"
        }
    }
}

public struct ExteraCustomIconPack: Codable, Equatable {
    public let id: UUID
    public let name: String
    public let symbols: [String: String]

    public func validated() -> Self? {
        let name = self.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard (1...36).contains(name.count), name.unicodeScalars.allSatisfy({ !CharacterSet.controlCharacters.contains($0) }),
              !self.symbols.isEmpty, self.symbols.count <= ExteraDrawerItem.allCases.count else { return nil }
        for (role, symbol) in self.symbols {
            guard ExteraDrawerItem(rawValue: role) != nil, (1...64).contains(symbol.utf8.count),
                  symbol.utf8.allSatisfy({ $0 == 46 || (48...57).contains($0) || (97...122).contains($0) }),
                  UIImage(systemName: symbol) != nil else { return nil }
        }
        return Self(id: self.id, name: name, symbols: self.symbols)
    }
}

public enum ExteraIconPack: Equatable {
    case builtIn(ExteraBuiltInIconPack)
    case custom(ExteraCustomIconPack)

    public init(store: ExteraSettingsStore = .shared) {
        if store.value(for: ExteraPreferences.iconPack) == 3,
           let id = store.value(for: ExteraPreferences.activeCustomIconPack),
           let pack = store.value(for: ExteraPreferences.customIconPacks).first(where: { $0.id == id }) {
            self = .custom(pack)
        } else {
            self = .builtIn(ExteraBuiltInIconPack(rawValue: store.value(for: ExteraPreferences.iconPack)) ?? .standard)
        }
    }

    public func image(_ role: ExteraDrawerItem) -> UIImage? {
        let image: UIImage?
        switch self {
        case .builtIn(.standard): return nil
        case .builtIn(.solar): image = UIImage(named: "ExteraSolar-" + role.rawValue)
        case .builtIn(.remix): image = UIImage(named: "ExteraRemix-" + role.rawValue)
        case let .custom(pack):
            image = pack.symbols[role.rawValue].flatMap { UIImage(systemName: $0, withConfiguration: UIImage.SymbolConfiguration(pointSize: 21, weight: .regular)) }
        }
        return image?.withRenderingMode(.alwaysTemplate)
    }

    public func image(_ tab: ExteraTab) -> UIImage? {
        guard let role = ExteraDrawerItem(rawValue: tab.rawValue) else { return nil }
        return self.image(role)
    }
}
