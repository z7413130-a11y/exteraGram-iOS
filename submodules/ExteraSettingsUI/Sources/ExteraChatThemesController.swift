import AccountContext
import Display
import ExteraSettings
import ItemListUI
import PresentationDataUtils
import SwiftSignalKit

public func exteraChatThemesController(context: AccountContext, peerId: Int64? = nil) -> ViewController {
    let store = ExteraSettingsStore.shared
    let key = peerId.map { ExteraChatTheme.key(account: context.account.id.int64, peer: $0) }
    let sample = ValuePromise<ExteraChatTheme>(.inherited, ignoreRepeated: true)
    let action: (Int, Bool?) -> Void = { id, _ in
        guard let theme = ExteraChatTheme(rawValue: id) else { return }
        if let key {
            var themes = store.value(for: ExteraPreferences.localChatThemes)
            if theme == .inherited { themes.removeValue(forKey: key) } else { themes[key] = theme }
            store.set(themes, for: ExteraPreferences.localChatThemes)
        } else {
            sample.set(theme)
        }
    }
    let state = combineLatest(context.sharedContext.presentationData, store.changes, sample.get())
    |> map { presentation, _, sample -> (ItemListControllerState, (ItemListNodeState, (Int, Bool?) -> Void)) in
        let strings = ExteraStrings(languageCode: presentation.strings.baseLanguageCode)
        let data = ItemListPresentationData(presentation)
        let theme = key.map { store.value(for: ExteraPreferences.localChatThemes)[$0] ?? .inherited } ?? sample
        let rows = [SettingsRow(stableId: -1, section: 0, title: "", kind: .preview(.chatTheme(theme)))] +
            ExteraChatTheme.allCases.map { choice in
                SettingsRow(stableId: choice.rawValue, section: 1, title: choice.title(strings), kind: .language(theme == choice))
            } +
            [SettingsRow(stableId: 10, section: 2, title: key == nil
                ? strings.text("This is a preview. Touch and hold a chat in the chat list and choose Local chat theme to apply it.", "Это предпросмотр. Зажми чат в списке и выбери «Локальная тема чата», чтобы применить тему.")
                : strings.text("This appearance is saved on this device for this chat.", "Оформление сохраняется на этом устройстве только для этого чата."), kind: .note)]
        return (ItemListControllerState(presentationData: data, title: .text(strings.text("Chat themes", "Темы чатов")),
            leftNavigationButton: nil, rightNavigationButton: nil, backNavigationButton: ItemListBackButton(title: presentation.strings.Common_Back)),
            (ItemListNodeState(presentationData: data, entries: rows, style: .blocks, animateChanges: false), action))
    }
    return ExteraSettingsListController(context: context, state: state)
}
