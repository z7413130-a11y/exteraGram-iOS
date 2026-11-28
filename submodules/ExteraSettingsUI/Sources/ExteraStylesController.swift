import AccountContext
import Display
import ExteraSettings
import ItemListUI
import PresentationDataUtils
import SwiftSignalKit

func exteraStylesController(context: AccountContext) -> ViewController {
    let store = ExteraSettingsStore.shared
    let action: (Int, Bool?) -> Void = { id, _ in
        if let style = ExteraSurfaceStyle(rawValue: id) { store.set(style, for: ExteraPreferences.interfaceStyle) }
    }
    let state = combineLatest(context.sharedContext.presentationData, store.changes)
    |> map { presentation, _ -> (ItemListControllerState, (ItemListNodeState, (Int, Bool?) -> Void)) in
        let strings = ExteraStrings(languageCode: presentation.strings.baseLanguageCode)
        let data = ItemListPresentationData(presentation)
        let config = ExteraNavigationAppearance(store: store, previewingBoth: true)
        let selected = store.value(for: ExteraPreferences.interfaceStyle)
        let rows = [SettingsRow(stableId: -1, section: 0, title: "", kind: .preview(.interface(config)))] +
            ExteraSurfaceStyle.allCases.map { style in
                SettingsRow(stableId: style.rawValue, section: 1, title: style.title(strings), kind: .language(style == selected))
            } +
            [SettingsRow(stableId: 6, section: 2, title: strings.text("Applies to supported settings rows, context menus and navigation. The bar, drawer and menus can use their own style. Glass uses iOS blur and highlights.", "Стиль применяется к поддерживаемым строкам настроек, контекстным меню и навигации. Панели и меню могут использовать свой стиль. Стекло использует размытие и блики iOS."), kind: .note)]
        return (ItemListControllerState(presentationData: data, title: .text(strings.text("Interface styles", "Стили интерфейса")),
            leftNavigationButton: nil, rightNavigationButton: nil, backNavigationButton: ItemListBackButton(title: presentation.strings.Common_Back)),
            (ItemListNodeState(presentationData: data, entries: rows, style: .blocks, animateChanges: false), action))
    }
    return ExteraSettingsListController(context: context, state: state)
}

private enum GeometryRow: Int, CaseIterable {
    case corner, buttons, spacing, insets, headers, dividers

    func title(_ strings: ExteraStrings) -> String {
        switch self {
        case .corner: return strings.text("Side panel radius", "Скругление боковой панели")
        case .buttons: return strings.text("Button radius", "Скругление кнопок")
        case .spacing: return strings.text("Section spacing", "Расстояние между секциями")
        case .insets: return strings.text("Side insets", "Боковые отступы")
        case .headers: return strings.text("Separate section header", "Отдельный заголовок секции")
        case .dividers: return strings.text("Dividers", "Разделители")
        }
    }
}

func exteraGeometryController(context: AccountContext) -> ViewController {
    let store = ExteraSettingsStore.shared
    weak var controller: ItemListController?
    let action: (Int, Bool?) -> Void = { id, flag in
        guard let row = GeometryRow(rawValue: id) else { return }
        let strings = ExteraStrings(languageCode: context.sharedContext.currentPresentationData.with { $0 }.strings.baseLanguageCode)
        let preview: () -> ExteraLivePreview = { .interface(ExteraNavigationAppearance(store: store, previewingBoth: true)) }
        func choose<T: Equatable>(_ options: [T], _ key: WritableKeyPath<ExteraGeometry, T>, title: (T) -> String) {
            controller?.push(exteraChoiceController(context: context, title: row.title(strings), selectedIndex: {
                options.firstIndex(of: store.value(for: ExteraPreferences.geometry).normalized[keyPath: key])
            }, titles: options.map(title), preview: preview, select: { index in
                var geometry = store.value(for: ExteraPreferences.geometry).normalized
                geometry[keyPath: key] = options[index]
                store.set(geometry, for: ExteraPreferences.geometry)
            }))
        }
        switch row {
        case .corner:
            let values: [Double] = [0, 8, 12, 16, 20, 24, 28, 32]
            controller?.push(exteraChoiceController(context: context, title: row.title(strings), selectedIndex: {
                values.firstIndex(of: store.value(for: ExteraPreferences.sectionRadius))
            }, titles: values.map { String(Int($0)) }, preview: preview, select: { store.set(values[$0], for: ExteraPreferences.sectionRadius) }))
        case .buttons: choose([0, 6, 10, 14, 18, 22], \.buttonRadius, title: String.init)
        case .spacing: choose([4, 8, 10, 12, 16, 20, 24], \.spacing, title: String.init)
        case .insets: choose([8, 12, 16, 20, 24], \.insets, title: String.init)
        case .dividers: choose(ExteraSectionDivider.allCases, \.dividers, title: { $0.title(strings) })
        case .headers:
            guard let flag else { return }
            var geometry = store.value(for: ExteraPreferences.geometry)
            geometry.sectionHeaders = flag
            store.set(geometry, for: ExteraPreferences.geometry)
        }
    }
    let state = combineLatest(context.sharedContext.presentationData, store.changes)
    |> map { presentation, _ -> (ItemListControllerState, (ItemListNodeState, (Int, Bool?) -> Void)) in
        let strings = ExteraStrings(languageCode: presentation.strings.baseLanguageCode)
        let data = ItemListPresentationData(presentation)
        let config = ExteraNavigationAppearance(store: store, previewingBoth: true)
        let options: [SettingsRow.Kind] = [
            .disclosure(String(Int(config.sectionRadius))), .disclosure(String(config.geometry.buttonRadius)),
            .disclosure(String(config.geometry.spacing)), .disclosure(String(config.geometry.insets)),
            .toggle(config.geometry.sectionHeaders), .disclosure(config.geometry.dividers.title(strings))
        ]
        let rows = [SettingsRow(stableId: -1, section: 0, title: "", kind: .preview(.interface(config)))] +
            GeometryRow.allCases.map { row in
                SettingsRow(stableId: row.rawValue, section: 1, title: row.title(strings), kind: options[row.rawValue])
            } +
            [SettingsRow(stableId: 9, section: 2, title: strings.text("Open the preview side menu to test the layout. Bottom bar and menu radius have separate settings.", "Открой боковое меню в предпросмотре и проверь раскладку. Скругление нижней панели и контекстных меню настраивается отдельно."), kind: .note)]
        return (ItemListControllerState(presentationData: data, title: .text(strings.text("Interface geometry", "Геометрия интерфейса")),
            leftNavigationButton: nil, rightNavigationButton: nil, backNavigationButton: ItemListBackButton(title: presentation.strings.Common_Back)),
            (ItemListNodeState(presentationData: data, entries: rows, style: .blocks, animateChanges: false), action))
    }
    let result = ExteraSettingsListController(context: context, state: state)
    controller = result
    return result
}
