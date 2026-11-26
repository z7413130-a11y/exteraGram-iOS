public struct ExteraStrings {
    private let russian: Bool

    public init(languageCode: String) {
        let language = languageCode.split(whereSeparator: { $0 == "-" || $0 == "_" }).first?.lowercased()
        self.russian = language == "ru"
    }

    public func text(_ english: String, _ russian: String) -> String {
        return self.russian ? russian : english
    }

    public func category(_ category: ExteraSettingsCategory) -> String {
        switch category {
        case .general: return self.text("General", "Общие")
        case .appearance: return self.text("Appearance", "Оформление")
        case .chats: return self.text("Chats", "Чаты")
        case .plugins: return self.text("Plugins", "Плагины")
        case .other: return self.text("Other", "Прочее")
        }
    }

    public var translateDraft: String {
        return self.text("Translate draft", "Перевести черновик")
    }

    public var messageDetails: String {
        return self.text("Message details", "Сведения о сообщении")
    }
}
