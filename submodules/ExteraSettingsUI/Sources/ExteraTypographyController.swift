import AccountContext
import Display
import ExteraSettings
import ItemListUI
import PresentationDataUtils
import SwiftSignalKit

func exteraTypographyController(context: AccountContext) -> ViewController {
    let store = ExteraSettingsStore.shared
    weak var controller: ItemListController?
    let action: (Int, Bool?) -> Void = { id, flag in
        let strings = ExteraStrings(languageCode: context.sharedContext.currentPresentationData.with { $0 }.strings.baseLanguageCode)
        let preview: () -> ExteraLivePreview = { .typography(store.value(for: ExteraPreferences.typography).normalized) }
        func choose<T: Equatable>(_ title: String, _ options: [T], _ key: WritableKeyPath<ExteraTypography, T>, titleFor: (T) -> String) {
            controller?.push(exteraChoiceController(context: context, title: title, selectedIndex: {
                options.firstIndex(of: store.value(for: ExteraPreferences.typography).normalized[keyPath: key])
            }, titles: options.map(titleFor), preview: preview, select: { index in
                var current = store.value(for: ExteraPreferences.typography).normalized
                current[keyPath: key] = options[index]
                store.set(current, for: ExteraPreferences.typography)
            }))
        }
        switch id {
        case 0: choose(strings.text("Typeface", "Гарнитура"), ExteraTypeface.allCases, \.typeface, titleFor: { $0.title(strings) })
        case 1: choose(strings.text("Text size", "Размер текста"), [85, 90, 95, 100, 105, 110, 115, 120, 125], \.size, titleFor: { "\($0)%" })
        case 2:
            guard let flag else { return }
            var current = store.value(for: ExteraPreferences.typography)
            current.heavier = flag
            store.set(current, for: ExteraPreferences.typography)
        case 3:
            let styles = ExteraEmojiStyle.allCases
            controller?.push(exteraChoiceController(context: context, title: strings.text("Emoji style", "Стиль эмодзи"),
                selectedIndex: { store.value(for: ExteraPreferences.typography).emojiStyle.rawValue }, titles: styles.map { $0.title(strings) }, preview: preview,
                select: { index in
                    guard let style = ExteraEmojiStyle(rawValue: index) else { return }
                    var typography = store.value(for: ExteraPreferences.typography)
                    typography.emoji = style
                    store.set(typography, for: ExteraPreferences.typography)
                }))
        default: break
        }
    }
    let state = combineLatest(context.sharedContext.presentationData, store.changes)
    |> map { presentation, _ -> (ItemListControllerState, (ItemListNodeState, (Int, Bool?) -> Void)) in
        let strings = ExteraStrings(languageCode: presentation.strings.baseLanguageCode)
        let data = ItemListPresentationData(presentation)
        let config = store.value(for: ExteraPreferences.typography).normalized
        let rows = [
            SettingsRow(stableId: -1, section: 0, title: "", kind: .preview(.typography(config))),
            SettingsRow(stableId: 0, section: 1, title: strings.text("Typeface", "Гарнитура"), kind: .disclosure(config.typeface.title(strings))),
            SettingsRow(stableId: 1, section: 1, title: strings.text("Text size", "Размер текста"), kind: .disclosure("\(config.size)%")),
            SettingsRow(stableId: 2, section: 1, title: strings.text("Heavier text", "Повышенная насыщенность"), kind: .toggle(config.heavier)),
            SettingsRow(stableId: 3, section: 1, title: strings.text("Emoji style", "Стиль эмодзи"), kind: .disclosure(config.emojiStyle.title(strings))),
            SettingsRow(stableId: 4, section: 1, title: strings.text("Applies to titles and previews in the chat list. Complex emoji and missing Noto glyphs use iOS rendering.", "Для заголовков и превью списка чатов. Сложные эмодзи и символы, которых нет в Noto, отображает iOS."), kind: .note),
        ]
        return (ItemListControllerState(presentationData: data, title: .text(strings.text("Fonts and emoji", "Шрифты и эмодзи")),
            leftNavigationButton: nil, rightNavigationButton: nil, backNavigationButton: ItemListBackButton(title: presentation.strings.Common_Back)),
            (ItemListNodeState(presentationData: data, entries: rows, style: .blocks, animateChanges: false), action))
    }
    let result = ExteraSettingsListController(context: context, state: state)
    controller = result
    return result
}
