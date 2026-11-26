import AccountContext
import AppBundle
import Display
import ExteraSettings
import Foundation
import ItemListUI
import PresentationDataUtils
import SwiftSignalKit
import TelegramPresentationData
import TranslateUI
import UIKit

private struct SettingsRow: ItemListNodeEntry {
    enum Kind: Equatable {
        case header
        case toggle(Bool)
        case disclosure(String)
        case language(Bool)
        case action
        case note
    }

    let stableId: Int
    let section: ItemListSectionId
    let title: String
    let kind: Kind

    static func < (lhs: SettingsRow, rhs: SettingsRow) -> Bool {
        return lhs.stableId < rhs.stableId
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let action = arguments as! (Int, Bool?) -> Void
        switch self.kind {
        case .header:
            return ItemListSectionHeaderItem(presentationData: presentationData, text: self.title, sectionId: self.section)
        case let .toggle(value):
            return ItemListSwitchItem(
                presentationData: presentationData, systemStyle: .glass, title: self.title,
                value: value, sectionId: self.section, style: .blocks,
                updated: { action(self.stableId, $0) }
            )
        case let .disclosure(label):
            return ItemListDisclosureItem(
                presentationData: presentationData, systemStyle: .glass, title: self.title,
                label: label, sectionId: self.section, style: .blocks,
                action: { action(self.stableId, nil) }
            )
        case let .language(selected):
            return ItemListCheckboxItem(
                presentationData: presentationData, systemStyle: .glass, title: self.title,
                style: .right, checked: selected, zeroSeparatorInsets: false,
                sectionId: self.section, action: { action(self.stableId, nil) }
            )
        case .action:
            return ItemListActionItem(
                presentationData: presentationData, systemStyle: .glass, title: self.title,
                kind: .generic, alignment: .natural, sectionId: self.section, style: .blocks,
                action: { action(self.stableId, nil) }
            )
        case .note:
            return ItemListTextItem(presentationData: presentationData, text: .plain(self.title), sectionId: self.section)
        }
    }
}

private enum RowID: Int {
    case generalHeader, translation, targetLanguage, reset, appearanceHeader, appearance
    case stories, counters, callsTab, premium, animatedEmoji, avatarCorners, stickerSize, tail, edited, search, centerTitle, dividers, privateReactions, channelReactions, groupReactions
    case chatsHeader, details, hideShare, confirmSticker, confirmGif, confirmCall, hideVideoRecording, showUserId, doubleTapIncoming, doubleTapOutgoing, swipe, pluginsHeader, plugins, otherHeader, about
}

private func appearanceToggle(_ id: RowID, _ strings: ExteraStrings) -> (String, ExteraPreference<Bool>)? {
    switch id {
    case .stories: return (strings.text("Hide chat list stories", "Скрыть истории в списке чатов"), ExteraPreferences.hideStories)
    case .callsTab: return (strings.text("Hide the Calls tab", "Скрыть вкладку «Звонки»"), ExteraPreferences.hideCallsTab)
    case .premium: return (strings.text("Hide Premium badges in chats", "Скрыть значки Premium в чатах"), ExteraPreferences.hidePremiumBadges)
    case .animatedEmoji: return (strings.text("Freeze large animated emoji", "Остановить анимацию крупных эмодзи"), ExteraPreferences.hideAnimatedEmoji)
    case .tail: return (strings.text("Hide message tails", "Скрыть хвостики сообщений"), ExteraPreferences.removeMessageTail)
    case .edited: return (strings.text("Show an icon for edited messages", "Показывать значок у изменённых сообщений"), ExteraPreferences.replaceEditedWithIcon)
    case .centerTitle: return (strings.text("Keep the chat list title centered", "Центрировать заголовок списка чатов"), ExteraPreferences.centerTitle)
    case .search: return (strings.text("Hide the chat list search bar", "Скрыть строку поиска в списке чатов"), ExteraPreferences.hideDialogsSearchBar)
    case .privateReactions: return (strings.text("Hide reactions in private chats", "Скрыть реакции в личных чатах"), ExteraPreferences.hideReactionsInPrivateChats)
    case .channelReactions: return (strings.text("Hide reactions in channels", "Скрыть реакции в каналах"), ExteraPreferences.hideReactionsInChannels)
    case .groupReactions: return (strings.text("Hide reactions in groups", "Скрыть реакции в группах"), ExteraPreferences.hideReactionsInGroups)
    default: return nil
    }
}

private func gestureRowTitle(_ row: RowID, _ strings: ExteraStrings) -> String {
    switch row {
    case .doubleTapIncoming: return strings.text("Double tap on incoming messages", "Двойное нажатие на входящих")
    case .doubleTapOutgoing: return strings.text("Double tap on outgoing messages", "Двойное нажатие на исходящих")
    default: return strings.text("Message swipe", "Свайп по сообщению")
    }
}

private func languageName(_ code: String, locale: Locale, strings: ExteraStrings) -> String {
    if code.isEmpty {
        return strings.text("App language", "Язык приложения")
    }
    return locale.localizedString(forLanguageCode: code)?.localizedCapitalized ?? code
}

/// The settings entry point used by Telegram's Settings tab and iPad sidebar.
public func exteraSettingsController(context: AccountContext, makeAppearanceController: @escaping () -> ViewController) -> ViewController {
    let store = ExteraSettingsStore.shared
    weak var settingsController: ItemListController?
    let action: (Int, Bool?) -> Void = { id, value in
        guard let row = RowID(rawValue: id) else { return }
        let strings = ExteraStrings(languageCode: context.sharedContext.currentPresentationData.with { $0 }.strings.baseLanguageCode)
        if let value, let (_, preference) = appearanceToggle(row, strings) {
            store.set(value, for: preference)
            return
        }
        switch row {
        case .counters:
            if let value { store.set(value ? 2 : 0, for: ExteraPreferences.tabCounterMode) }
        case .dividers:
            if let value { store.set(value ? 0 : 1, for: ExteraPreferences.dividerStyle) }
        case .avatarCorners:
            settingsController?.push(exteraSliderController(context: context, title: strings.text("Chat list avatar rounding", "Скругление аватарок в списке чатов"),
                preference: ExteraPreferences.avatarCorners, limits: 0...28, rangeLabels: ("0%", "100%")))
        case .stickerSize:
            settingsController?.push(exteraSliderController(context: context, title: strings.text("Sticker size", "Размер стикеров"),
                preference: ExteraPreferences.stickerSize, limits: 4...20,
                rangeLabels: (strings.text("Smaller", "Меньше"), strings.text("Larger", "Больше"))))
        case .confirmSticker:
            if let value { store.set(value, for: ExteraPreferences.confirmStickerSend) }
        case .confirmGif:
            if let value { store.set(value, for: ExteraPreferences.confirmGifSend) }
        case .confirmCall:
            if let value { store.set(value, for: ExteraPreferences.confirmCall) }
        case .hideVideoRecording:
            if let value { store.set(value, for: ExteraPreferences.hideVideoRecording) }
        case .showUserId:
            if let value { store.set(value ? 1 : 0, for: ExteraPreferences.showIdAndDc) }
        case .doubleTapIncoming, .doubleTapOutgoing:
            let outgoing = row == .doubleTapOutgoing
            let preference = outgoing ? ExteraPreferences.doubleTapActionOutOwner : ExteraPreferences.doubleTapAction
            let choices = ExteraMessageGestureAction.allCases.filter { outgoing || $0 != .edit }
            settingsController?.push(exteraChoiceController(context: context, title: gestureRowTitle(row, strings),
                selectedIndex: { choices.firstIndex(of: .doubleTap(setting: store.value(for: preference), outgoing: outgoing)) },
                titles: choices.map { $0.title(strings) },
                select: { store.set(choices[$0].doubleTapSetting(outgoing: outgoing), for: preference) }))
        case .swipe:
            settingsController?.push(exteraSwipeController(context: context))
        case .translation:
            if let value { store.set(value, for: ExteraPreferences.translateDrafts) }
        case .targetLanguage:
            settingsController?.push(exteraLanguageController(context: context))
        case .appearance:
            settingsController?.push(makeAppearanceController())
        case .details:
            if let value { store.set(value, for: ExteraPreferences.showDetailsButton) }
        case .hideShare:
            if let value { store.set(value, for: ExteraPreferences.hideShareButton) }
        case .reset:
            let presentation = context.sharedContext.currentPresentationData.with { $0 }
            let strings = ExteraStrings(languageCode: presentation.strings.baseLanguageCode)
            settingsController?.present(textAlertController(
                context: context,
                title: strings.text("Reset exteraGram settings?", "Сбросить настройки exteraGram?"),
                text: strings.text("Only the exteraGram settings will be reset. Your accounts and chats are kept.", "Будут сброшены только настройки exteraGram. Аккаунты и переписки сохранятся."),
                actions: [
                    TextAlertAction(type: .genericAction, title: presentation.strings.Common_Cancel, action: {}),
                    TextAlertAction(type: .destructiveAction, title: strings.text("Reset", "Сбросить"), action: { store.reset() }),
                ]
            ), in: .window(.root))
        case .about:
            settingsController?.push(exteraAboutController(context: context))
        default:
            break
        }
    }
    let state = combineLatest(context.sharedContext.presentationData, store.changes)
    |> map { presentationData, _ -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let code = presentationData.strings.baseLanguageCode
        let strings = ExteraStrings(languageCode: code)
        let locale = Locale(identifier: code)
        func row(_ id: RowID, _ section: ExteraSettingsCategory, _ title: String, _ kind: SettingsRow.Kind) -> SettingsRow {
            return SettingsRow(stableId: id.rawValue, section: section.rawValue, title: title, kind: kind)
        }
        let appearanceRows: [RowID] = [.stories, .counters, .callsTab, .premium, .animatedEmoji, .avatarCorners, .stickerSize, .tail, .edited, .search, .centerTitle, .dividers, .privateReactions, .channelReactions, .groupReactions]
        let appearanceItems = appearanceRows.compactMap { id -> SettingsRow? in
            if let (title, preference) = appearanceToggle(id, strings) {
                return row(id, .appearance, title, .toggle(store.value(for: preference)))
            }
            switch id {
            case .counters:
                return row(id, .appearance, strings.text("Hide unread counters", "Скрыть счётчики непрочитанных"), .toggle(ExteraAppearance.hidesUnreadCounters))
            case .dividers:
                return row(id, .appearance, strings.text("Hide chat list dividers", "Скрыть разделители списка чатов"), .toggle(ExteraAppearance.hidesDividers))
            case .avatarCorners:
                return row(id, .appearance, strings.text("Chat list avatar rounding", "Скругление аватарок в списке чатов"), .disclosure("\(Int(ExteraAppearance.avatarCornerFraction * 200))%"))
            case .stickerSize:
                return row(id, .appearance, strings.text("Sticker size", "Размер стикеров"), .disclosure("\(Int((ExteraAppearance.stickerScale * 100).rounded()))%"))
            default: return nil
            }
        }
        let rows = [
            row(.generalHeader, .general, strings.category(.general), .header),
            row(.translation, .general, strings.text("Translate before sending", "Перевод перед отправкой"), .toggle(store.value(for: ExteraPreferences.translateDrafts))),
            row(.targetLanguage, .general, strings.text("Translation language", "Язык перевода"), .disclosure(languageName(store.value(for: ExteraPreferences.targetLang), locale: locale, strings: strings))),
            row(.reset, .general, strings.text("Reset exteraGram settings", "Сбросить настройки exteraGram"), .action),
            row(.appearanceHeader, .appearance, strings.category(.appearance), .header),
            row(.appearance, .appearance, presentationData.strings.Settings_Appearance, .disclosure("")),
        ] + appearanceItems + [
            row(.chatsHeader, .chats, strings.category(.chats), .header),
            row(.details, .chats, strings.messageDetails, .toggle(store.value(for: ExteraPreferences.showDetailsButton))),
            row(.hideShare, .chats, strings.text("Hide share button", "Скрыть кнопку «Поделиться»"), .toggle(store.value(for: ExteraPreferences.hideShareButton))),
            row(.confirmSticker, .chats, strings.text("Confirm sticker sends", "Подтверждать отправку стикеров"), .toggle(store.value(for: ExteraPreferences.confirmStickerSend))),
            row(.confirmGif, .chats, strings.text("Confirm GIF sends", "Подтверждать отправку GIF"), .toggle(store.value(for: ExteraPreferences.confirmGifSend))),
            row(.confirmCall, .chats, strings.text("Confirm calls", "Подтверждать звонки"), .toggle(store.value(for: ExteraPreferences.confirmCall))),
            row(.hideVideoRecording, .chats, strings.text("Hide video message recording", "Скрыть запись видеосообщений"), .toggle(store.value(for: ExteraPreferences.hideVideoRecording))),
            row(.showUserId, .chats, strings.text("Show copyable user IDs", "Показывать ID пользователя для копирования"), .toggle(store.value(for: ExteraPreferences.showIdAndDc) != 0)),
            row(.doubleTapIncoming, .chats, gestureRowTitle(.doubleTapIncoming, strings),
                .disclosure(ExteraMessageGestureAction.doubleTap(setting: store.value(for: ExteraPreferences.doubleTapAction), outgoing: false).title(strings))),
            row(.doubleTapOutgoing, .chats, gestureRowTitle(.doubleTapOutgoing, strings),
                .disclosure(ExteraMessageGestureAction.doubleTap(setting: store.value(for: ExteraPreferences.doubleTapActionOutOwner), outgoing: true).title(strings))),
            row(.swipe, .chats, gestureRowTitle(.swipe, strings),
                .disclosure(exteraSwipeValue(store, strings))),
            row(.pluginsHeader, .plugins, strings.category(.plugins), .header),
            row(.plugins, .plugins, strings.text("Android plugins are unavailable in the iOS port.", "Плагины Android недоступны в iOS-порте."), .note),
            row(.otherHeader, .other, strings.category(.other), .header),
            row(.about, .other, strings.text("About", "О приложении"), .disclosure("")),
        ]
        let data = ItemListPresentationData(presentationData)
        return (
            ItemListControllerState(presentationData: data, title: .text("exteraGram"), leftNavigationButton: nil, rightNavigationButton: nil, backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back)),
            (ItemListNodeState(presentationData: data, entries: rows, style: .blocks, animateChanges: false), action)
        )
    }
    let controller = ItemListController(context: context, state: state)
    settingsController = controller
    return controller
}

private struct AboutRow: ItemListNodeEntry {
    let stableId: Int
    let title: String
    let value: String
    let section: ItemListSectionId = 0

    static func < (lhs: AboutRow, rhs: AboutRow) -> Bool { lhs.stableId < rhs.stableId }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let openRepository = arguments as! () -> Void
        if self.stableId == 2 {
            return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass,
                title: self.title, label: self.value, sectionId: self.section, style: .blocks, action: openRepository)
        }
        return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass,
            icon: self.stableId == 0 ? generateScaledImage(image: UIImage(bundleImageName: "ExteraGramPreview"), size: CGSize(width: 30, height: 30)) : nil,
            title: self.title, label: self.value, sectionId: self.section, style: .blocks, disclosureStyle: .none, action: nil)
    }
}

private func exteraAboutController(context: AccountContext) -> ViewController {
    let bundle = Bundle.main
    let version = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
    let build = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? ""
    let openRepository = {
        context.sharedContext.applicationBindings.openUrl("https://github.com/z7413130-a11y/exteraGram-iOS")
    }
    let state = context.sharedContext.presentationData
    |> map { presentation -> (ItemListControllerState, (ItemListNodeState, () -> Void)) in
        let strings = ExteraStrings(languageCode: presentation.strings.baseLanguageCode)
        let data = ItemListPresentationData(presentation)
        let rows = [
            AboutRow(stableId: 0, title: "exteraGram", value: ""),
            AboutRow(stableId: 1, title: strings.text("Version · Build", "Версия · Сборка"), value: "\(version) · \(build)"),
            AboutRow(stableId: 2, title: strings.text("Project repository", "Репозиторий проекта"), value: "GitHub"),
        ]
        return (ItemListControllerState(presentationData: data, title: .text(strings.text("About", "О приложении")),
            leftNavigationButton: nil, rightNavigationButton: nil, backNavigationButton: ItemListBackButton(title: presentation.strings.Common_Back)),
            (ItemListNodeState(presentationData: data, entries: rows, style: .blocks, animateChanges: false), openRepository))
    }
    return ItemListController(context: context, state: state)
}

private func exteraLanguageController(context: AccountContext) -> ViewController {
    let store = ExteraSettingsStore.shared
    let languageCodes = [""] + supportedTranslationLanguages.sorted()
    let action: (Int, Bool?) -> Void = { id, _ in
        store.set(languageCodes[id], for: ExteraPreferences.targetLang)
    }
    let state = combineLatest(context.sharedContext.presentationData, store.changes)
    |> map { presentationData, _ -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let code = presentationData.strings.baseLanguageCode
        let locale = Locale(identifier: code)
        let strings = ExteraStrings(languageCode: code)
        let selected = store.value(for: ExteraPreferences.targetLang)
        let rows = languageCodes.enumerated().map { id, language in
            SettingsRow(stableId: id, section: 0, title: languageName(language, locale: locale, strings: strings), kind: .language(language == selected))
        }
        let data = ItemListPresentationData(presentationData)
        return (
            ItemListControllerState(presentationData: data, title: .text(strings.text("Translation language", "Язык перевода")), leftNavigationButton: nil, rightNavigationButton: nil, backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back)),
            (ItemListNodeState(presentationData: data, entries: rows, style: .blocks, animateChanges: false), action)
        )
    }
    return ItemListController(context: context, state: state)
}

private func exteraChoiceController(context: AccountContext, title: String, selectedIndex: @escaping () -> Int?, titles: [String], select: @escaping (Int) -> Void) -> ViewController {
    let action: (Int, Bool?) -> Void = { index, _ in
        if titles.indices.contains(index) { select(index) }
    }
    let state = combineLatest(context.sharedContext.presentationData, ExteraSettingsStore.shared.changes)
    |> map { presentation, _ -> (ItemListControllerState, (ItemListNodeState, (Int, Bool?) -> Void)) in
        let data = ItemListPresentationData(presentation)
        let selected = selectedIndex()
        let rows = titles.enumerated().map { index, label in
            SettingsRow(stableId: index, section: 0, title: label, kind: .language(index == selected))
        }
        return (ItemListControllerState(presentationData: data, title: .text(title),
            leftNavigationButton: nil, rightNavigationButton: nil, backNavigationButton: ItemListBackButton(title: presentation.strings.Common_Back)),
            (ItemListNodeState(presentationData: data, entries: rows, style: .blocks, animateChanges: false), action))
    }
    return ItemListController(context: context, state: state)
}

private func exteraSwipeValue(_ store: ExteraSettingsStore, _ strings: ExteraStrings) -> String {
    let actions = ExteraMessageGestureAction.swipeActions(store.value(for: ExteraPreferences.swipeActions))
    if actions.count > 1 { return String(actions.count) }
    return (actions.first ?? .disabled).title(strings)
}

private func exteraSwipeController(context: AccountContext) -> ViewController {
    let store = ExteraSettingsStore.shared
    let action: (Int, Bool?) -> Void = { id, enabled in
        guard let enabled else { return }
        switch id {
        case 100:
            store.set(enabled, for: ExteraPreferences.swipeActionsLoop)
        case 101:
            store.set(enabled, for: ExteraPreferences.swipeActionsReversed)
        default:
            guard let gesture = ExteraMessageGestureAction(rawValue: id), gesture != .disabled else { return }
            var actions = ExteraMessageGestureAction.swipeActions(store.value(for: ExteraPreferences.swipeActions))
            actions.removeAll(where: { $0 == gesture })
            if enabled { actions.append(gesture) }
            store.set(actions.map { String($0.rawValue) }.joined(separator: ","), for: ExteraPreferences.swipeActions)
        }
    }
    let state = combineLatest(context.sharedContext.presentationData, store.changes)
    |> map { presentation, _ -> (ItemListControllerState, (ItemListNodeState, (Int, Bool?) -> Void)) in
        let strings = ExteraStrings(languageCode: presentation.strings.baseLanguageCode)
        let data = ItemListPresentationData(presentation)
        let actions = ExteraMessageGestureAction.swipeActions(store.value(for: ExteraPreferences.swipeActions))
        let rows = [
            SettingsRow(stableId: 0, section: 0, title: strings.text("Enable actions in the order you want them. Swipe left, then move vertically to choose.", "Включай действия в нужном порядке. Проведи влево, затем двигай палец вверх или вниз для выбора."), kind: .note),
        ] + ExteraMessageGestureAction.allCases.filter { $0 != .disabled }.map { gesture in
            let rank = actions.firstIndex(of: gesture)
            let title = rank.map { "\($0 + 1). " } ?? ""
            return SettingsRow(stableId: gesture.rawValue, section: 1, title: title + gesture.title(strings), kind: .toggle(rank != nil))
        } + [
            SettingsRow(stableId: 100, section: 2, title: strings.text("Wrap around", "Листать по кругу"), kind: .toggle(store.value(for: ExteraPreferences.swipeActionsLoop))),
            SettingsRow(stableId: 101, section: 2, title: strings.text("Reverse selection", "Обратный выбор"), kind: .toggle(store.value(for: ExteraPreferences.swipeActionsReversed))),
        ]
        return (ItemListControllerState(presentationData: data, title: .text(gestureRowTitle(.swipe, strings)),
            leftNavigationButton: nil, rightNavigationButton: nil, backNavigationButton: ItemListBackButton(title: presentation.strings.Common_Back)),
            (ItemListNodeState(presentationData: data, entries: rows, style: .blocks, animateChanges: false), action))
    }
    return ItemListController(context: context, state: state)
}
