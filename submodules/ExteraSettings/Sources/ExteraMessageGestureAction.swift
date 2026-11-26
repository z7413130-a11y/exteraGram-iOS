import Foundation

public enum ExteraMessageGestureAction: Int, CaseIterable {
    case disabled = 0, reaction, reply, copy, forward, edit, save, repeatText, delete, translate

    public static func doubleTap(setting: Int, outgoing: Bool) -> Self {
        guard (0...(outgoing ? 9 : 8)).contains(setting) else { return .disabled }
        let actionId = !outgoing && (5...8).contains(setting) ? setting + 1 : setting
        return Self(rawValue: actionId) ?? .disabled
    }

    public func doubleTapSetting(outgoing: Bool) -> Int {
        return !outgoing && self.rawValue > 5 ? self.rawValue - 1 : self.rawValue
    }

    public static func swipeActions(_ encoded: String) -> [Self] {
        var seen = Set<Self>()
        return encoded.split(separator: ",").compactMap { raw in
            guard let id = Int(raw.trimmingCharacters(in: .whitespaces)), let action = Self(rawValue: id),
                  action != .disabled, seen.insert(action).inserted else {
                return nil
            }
            return action
        }
    }

    public func title(_ strings: ExteraStrings) -> String {
        switch self {
        case .disabled: return strings.text("Disabled", "Отключено")
        case .reaction: return strings.text("Quick reaction", "Быстрая реакция")
        case .reply: return strings.text("Reply", "Ответить")
        case .copy: return strings.text("Copy text", "Копировать текст")
        case .forward: return strings.text("Forward", "Переслать")
        case .edit: return strings.text("Edit", "Изменить")
        case .save: return strings.text("Save to Saved Messages", "Сохранить в Избранное")
        case .repeatText: return strings.text("Resend text", "Отправить текст повторно")
        case .delete: return strings.text("Delete", "Удалить")
        case .translate: return strings.text("Translate", "Перевести")
        }
    }

    public var symbol: String {
        switch self {
        case .disabled: return "xmark"
        case .reaction: return "heart"
        case .reply: return "arrowshape.turn.up.left"
        case .copy: return "doc.on.doc"
        case .forward: return "arrowshape.turn.up.right"
        case .edit: return "pencil"
        case .save: return "bookmark"
        case .repeatText: return "repeat"
        case .delete: return "trash"
        case .translate: return "text.bubble"
        }
    }
}
