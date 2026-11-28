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
    case menuMaterials
    case typography
    case motion
    case icons
    case chatThemes
    case style
    case geometry

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
        case .menuMaterials: return strings.text("Glass and context menus", "Стекло и контекстные меню")
        case .typography: return strings.text("Fonts and emoji", "Шрифты и эмодзи")
        case .motion: return strings.text("Animations", "Анимации")
        case .icons: return strings.text("Icon packs", "Наборы иконок")
        case .chatThemes: return strings.text("Chat themes", "Темы чатов")
        case .style: return strings.text("Interface styles", "Стили интерфейса")
        case .geometry: return strings.text("Interface geometry", "Геометрия интерфейса")
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
        case .menuMaterials: return PresentationResourcesSettings.security
        case .typography: return UIImage(systemName: "textformat")
        case .motion: return UIImage(systemName: "waveform.path")
        case .icons: return UIImage(systemName: "square.grid.2x2")
        case .chatThemes: return UIImage(systemName: "paintpalette")
        case .style: return UIImage(systemName: "square.on.square")
        case .geometry: return UIImage(systemName: "ruler")
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
                snow: store.value(for: ExteraPreferences.forceSnow),
                senderAvatars: store.value(for: ExteraPreferences.senderMiniAvatars))
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
        case .typography: return .typography(store.value(for: ExteraPreferences.typography).normalized)
        case .motion: return .motion(ExteraMotion(store: store))
        case .icons, .style, .geometry: return .interface(ExteraNavigationAppearance(store: store, previewingBoth: true))
        case .chatThemes: return .chatTheme(.inherited)
        case .appIcons, .pills, .menuMaterials:
            return nil
        }
    }
}
