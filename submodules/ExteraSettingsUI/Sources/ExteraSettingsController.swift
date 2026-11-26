import AccountContext
import Display
import ExteraSettings
import Foundation
import ItemListUI
import PresentationDataUtils
import SwiftSignalKit
import TelegramPresentationData
import TranslateUI

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
    case generalHeader, translation, targetLanguage, appearanceHeader, appearance
    case chatsHeader, details, hideShare, pluginsHeader, plugins, otherHeader, reset, about
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
        switch RowID(rawValue: id) {
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
            store.set(ExteraPreferences.translateDrafts.defaultValue, for: ExteraPreferences.translateDrafts)
            store.set(ExteraPreferences.targetLang.defaultValue, for: ExteraPreferences.targetLang)
            store.set(ExteraPreferences.showDetailsButton.defaultValue, for: ExteraPreferences.showDetailsButton)
            store.set(ExteraPreferences.hideShareButton.defaultValue, for: ExteraPreferences.hideShareButton)
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
        let rows = [
            row(.generalHeader, .general, strings.category(.general), .header),
            row(.translation, .general, strings.text("Translate before sending", "Перевод перед отправкой"), .toggle(store.value(for: ExteraPreferences.translateDrafts))),
            row(.targetLanguage, .general, strings.text("Translation language", "Язык перевода"), .disclosure(languageName(store.value(for: ExteraPreferences.targetLang), locale: locale, strings: strings))),
            row(.appearanceHeader, .appearance, strings.category(.appearance), .header),
            row(.appearance, .appearance, presentationData.strings.Settings_Appearance, .disclosure("")),
            row(.chatsHeader, .chats, strings.category(.chats), .header),
            row(.details, .chats, strings.messageDetails, .toggle(store.value(for: ExteraPreferences.showDetailsButton))),
            row(.hideShare, .chats, strings.text("Hide share button", "Скрыть кнопку «Поделиться»"), .toggle(store.value(for: ExteraPreferences.hideShareButton))),
            row(.pluginsHeader, .plugins, strings.category(.plugins), .header),
            row(.plugins, .plugins, strings.text("Android plugins are unavailable in the iOS port.", "Плагины Android недоступны в iOS-порте."), .note),
            row(.otherHeader, .other, strings.category(.other), .header),
            row(.reset, .other, strings.text("Reset exteraGram settings", "Сбросить настройки exteraGram"), .action),
            row(.about, .other, strings.text("exteraGram iOS Port is an unofficial port based on Telegram for iOS and inspired by exteraGram for Android.", "exteraGram iOS Port — неофициальный порт на базе Telegram для iOS, вдохновлённый exteraGram для Android."), .note),
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
