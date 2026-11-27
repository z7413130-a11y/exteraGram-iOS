import AccountContext
import Display
import ExteraSettings
import ItemListUI
import PresentationDataUtils
import SwiftSignalKit

func exteraTabOrderController(context: AccountContext) -> ViewController {
    let store = ExteraSettingsStore.shared
    let tabs = ExteraTab.allCases
    let action: (Int, Bool?) -> Void = { id, _ in
        if id == 100 {
            store.set(tabs, for: ExteraPreferences.rootTabOrder)
        } else if tabs.indices.contains(id) {
            var order = ExteraNavigationAppearance(store: store).order
            if let index = order.firstIndex(of: tabs[id]), index > 0 {
                order.swapAt(index, index - 1)
                store.set(order, for: ExteraPreferences.rootTabOrder)
            }
        }
    }
    let state = combineLatest(context.sharedContext.presentationData, store.changes)
    |> map { presentation, _ -> (ItemListControllerState, (ItemListNodeState, (Int, Bool?) -> Void)) in
        let strings = ExteraStrings(languageCode: presentation.strings.baseLanguageCode)
        let data = ItemListPresentationData(presentation)
        let config = ExteraNavigationAppearance(store: store)
        var rows = [
            SettingsRow(stableId: -2, section: 0, title: "", kind: .preview(.navigation(config.order))),
            SettingsRow(stableId: -1, section: 0,
                title: strings.text("Tap a tab to move it up. Calls and News appear only when available.",
                    "Нажми на вкладку, чтобы поднять её. Вкладки «Звонки» и «Новости» появляются, когда они доступны."),
                kind: .note),
        ]
        rows += tabs.enumerated().map { id, tab in
            let position = (config.order.firstIndex(of: tab) ?? id) + 1
            return SettingsRow(stableId: id, section: 1, title: "\(position). \(tab.title(strings))", kind: .action)
        }
        rows.append(SettingsRow(stableId: 100, section: 2, title: strings.text("Restore tab order", "Восстановить порядок вкладок"), kind: .action))
        return (ItemListControllerState(presentationData: data, title: .text(strings.text("Tab order", "Порядок вкладок")),
            leftNavigationButton: nil, rightNavigationButton: nil, backNavigationButton: ItemListBackButton(title: presentation.strings.Common_Back)),
            (ItemListNodeState(presentationData: data, entries: rows, style: .blocks, animateChanges: false), action))
    }
    return ItemListController(context: context, state: state)
}
