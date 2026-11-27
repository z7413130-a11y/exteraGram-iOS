public enum ExteraChatListTitle: Int, CaseIterable {
    case brand
    case username
    case account
    case folder
    case chats

    public func title(_ strings: ExteraStrings) -> String {
        switch self {
        case .brand: return "exteraGram"
        case .username: return strings.text("Username", "Имя пользователя")
        case .account: return strings.text("Account name", "Имя аккаунта")
        case .folder: return strings.text("Current folder", "Текущая папка")
        case .chats: return strings.text("Chats", "Чаты")
        }
    }
}

public enum ExteraFolderIcons: Int, CaseIterable {
    case textAndIcons
    case text
    case icons

    public func title(_ strings: ExteraStrings) -> String {
        switch self {
        case .textAndIcons: return strings.text("Text and icons", "Текст и иконки")
        case .text: return strings.text("Text only", "Только текст")
        case .icons: return strings.text("Icons only", "Только иконки")
        }
    }
}

public enum ExteraFolderCounters: Int, CaseIterable {
    case all
    case unmuted
    case hidden

    public func title(_ strings: ExteraStrings) -> String {
        switch self {
        case .all: return strings.text("All unread chats", "Все непрочитанные чаты")
        case .unmuted: return strings.text("Unread chats with notifications", "Непрочитанные чаты с уведомлениями")
        case .hidden: return strings.text("No counters", "Без счётчиков")
        }
    }
}

public enum ExteraHeaderBlur: Int, CaseIterable {
    case standard, progressive, gradient, none

    public func title(_ strings: ExteraStrings) -> String {
        switch self {
        case .standard: return strings.text("Standard", "Стандартное")
        case .progressive: return strings.text("Progressive", "Прогрессивное")
        case .gradient: return strings.text("Gradient tint", "Градиентное")
        case .none: return strings.text("No blur", "Без размытия")
        }
    }
}
