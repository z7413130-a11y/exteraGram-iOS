import ExteraSettings
import TelegramPresentationData
import UIKit

enum ExteraAppearancePage: Int, CaseIterable {
    case avatars
    case chatList
    case header
    case folders
    case navigation
    case appIcons
    case messages
    case pills

    func title(_ strings: ExteraStrings) -> String {
        switch self {
        case .avatars: return strings.text("Avatars", "Аватарки")
        case .chatList: return strings.text("Chat list", "Список чатов")
        case .header: return strings.text("Top bar", "Верхняя панель")
        case .folders: return strings.text("Chat folders", "Папки чатов")
        case .navigation: return strings.text("Navigation", "Навигация")
        case .appIcons: return strings.text("App icons", "Иконки приложения")
        case .messages: return strings.text("Messages and stickers", "Сообщения и стикеры")
        case .pills: return "Pill Stack"
        }
    }

    var icon: UIImage? {
        switch self {
        case .avatars: return PresentationResourcesSettings.contacts
        case .chatList: return PresentationResourcesSettings.privateChats
        case .header: return PresentationResourcesSettings.appearance
        case .folders: return PresentationResourcesSettings.chatFolders
        case .navigation: return PresentationResourcesSettings.devices
        case .appIcons: return PresentationResourcesSettings.stories
        case .messages: return PresentationResourcesSettings.stickers
        case .pills: return PresentationResourcesSettings.dataUsage
        }
    }

    func preview(store: ExteraSettingsStore, strings: ExteraStrings) -> ExteraLivePreview? {
        switch self {
        case .avatars:
            return .avatars(ExteraAppearance.avatarCornerFraction,
                store.value(for: ExteraPreferences.singleCornerRadius),
                store.value(for: ExteraPreferences.gooeyAvatarAnimation))
        case .chatList:
            return .chatList(stories: !store.value(for: ExteraPreferences.hideStories),
                search: !store.value(for: ExteraPreferences.hideDialogsSearchBar),
                dividers: !ExteraAppearance.hidesDividers, counters: !ExteraAppearance.hidesUnreadCounters,
                snow: store.value(for: ExteraPreferences.forceSnow))
        case .header:
            let title = ExteraChatListTitle(rawValue: store.value(for: ExteraPreferences.titleText)) ?? .chats
            return .header(title: title.title(strings), centered: store.value(for: ExteraPreferences.centerTitle),
                status: !store.value(for: ExteraPreferences.hideActionBarStatus),
                composeInMenu: store.value(for: ExteraPreferences.hideFloatingButton),
                compactCompose: store.value(for: ExteraPreferences.squareFab),
                blur: ExteraHeaderBlur(rawValue: store.value(for: ExteraPreferences.headerBlurStyle)) ?? .standard)
        case .folders:
            return .folders(ExteraFolderIcons(rawValue: store.value(for: ExteraPreferences.tabIcons)) ?? .text,
                ExteraFolderCounters(rawValue: store.value(for: ExteraPreferences.tabCounterMode)) ?? .all)
        case .navigation:
            let config = ExteraNavigationAppearance(store: store)
            return .navigation(config.order.filter { ($0 != .calls || !config.hidesCalls) && ($0 != .news || !config.hidesNews) })
        case .messages:
            return .messages(scale: ExteraAppearance.stickerScale,
                shape: ExteraStickerShape(rawValue: store.value(for: ExteraPreferences.stickerShape)) ?? .standard,
                time: ExteraStickerTime(rawValue: store.value(for: ExteraPreferences.stickerTimeMode)) ?? .standard,
                tails: !store.value(for: ExteraPreferences.removeMessageTail),
                editedIcon: store.value(for: ExteraPreferences.replaceEditedWithIcon),
                reactions: !store.value(for: ExteraPreferences.hideReactionsInPrivateChats))
        case .appIcons, .pills:
            return nil
        }
    }
}
