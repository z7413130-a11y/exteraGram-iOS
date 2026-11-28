import AccountContext
import Display
import ExteraSettings
import ItemListUI
import PresentationDataUtils
import SwiftSignalKit

private enum InterfaceRow: Int {
    case mode, bar, labels, radius, material, width, opacity, drawerItems, useAppBar, useAppDrawer
}

func exteraInterfaceController(context: AccountContext) -> ViewController {
    let store = ExteraSettingsStore.shared
    weak var controller: ItemListController?
    let action: (Int, Bool?) -> Void = { id, enabled in
        guard let row = InterfaceRow(rawValue: id) else { return }
        let text = ExteraStrings(languageCode: context.sharedContext.currentPresentationData.with { $0 }.strings.baseLanguageCode)
        func edit<T: Equatable>(_ title: String, options: [T], keyPath: WritableKeyPath<ExteraInterfaceAppearance, T>, labels: (T) -> String) {
            controller?.push(exteraChoiceController(context: context, title: title, selectedIndex: {
                options.firstIndex(of: store.value(for: ExteraPreferences.interfaceAppearance).normalized[keyPath: keyPath])
            }, titles: options.map(labels), preview: { .interface(ExteraNavigationAppearance(store: store)) }, select: { index in
                var value = store.value(for: ExteraPreferences.interfaceAppearance).normalized
                value[keyPath: keyPath] = options[index]
                store.set(value.normalized, for: ExteraPreferences.interfaceAppearance)
            }))
        }
        switch row {
        case .mode:
            controller?.push(exteraChoiceController(context: context, title: text.text("Navigation mode", "Режим навигации"),
                selectedIndex: { ExteraNavigationAppearance(store: store).drawerMode.rawValue },
                titles: ExteraDrawerMode.allCases.map { $0.title(text) }, preview: { .interface(ExteraNavigationAppearance(store: store)) }, select: { index in
                    guard let mode = ExteraDrawerMode(rawValue: index) else { return }
                    var config = store.value(for: ExteraPreferences.interfaceAppearance).normalized
                    config.drawerOnly = mode == .drawer
                    store.set(config, for: ExteraPreferences.interfaceAppearance)
                    store.set(mode != .tabs, for: ExteraPreferences.navigationDrawer)
                }))
        case .bar:
            edit(text.text("Bottom bar style", "Стиль нижней панели"), options: ExteraBarStyle.allCases, keyPath: \.barStyle, labels: { $0.title(text) })
        case .labels:
            if let enabled { store.set(enabled, for: ExteraPreferences.hideNavigationBarLabels) }
        case .radius:
            edit(text.text("Navigation corner radius", "Скругление панелей"), options: [8, 12, 16, 20, 24, 28, 32], keyPath: \.barRadius, labels: String.init)
        case .material:
            edit(text.text("Drawer material", "Материал бокового меню"), options: ExteraSurfaceStyle.allCases, keyPath: \.surfaceStyle, labels: { $0.title(text) })
        case .width:
            edit(text.text("Side menu width", "Ширина бокового меню"), options: [60, 70, 80, 90], keyPath: \.drawerWidth, labels: { "\($0)%" })
        case .opacity:
            edit(text.text("Side menu opacity", "Непрозрачность бокового меню"), options: [65, 75, 85, 92, 100], keyPath: \.drawerOpacity, labels: { "\($0)%" })
        case .useAppBar, .useAppDrawer:
            guard let enabled else { return }
            var appearance = store.value(for: ExteraPreferences.interfaceAppearance)
            if row == .useAppBar { appearance.inheritBarStyle = enabled } else { appearance.inheritDrawerStyle = enabled }
            store.set(appearance, for: ExteraPreferences.interfaceAppearance)
        case .drawerItems:
            controller?.push(exteraDrawerItemsController(context: context))
        }
    }
    let state = combineLatest(context.sharedContext.presentationData, store.changes)
    |> map { presentation, _ -> (ItemListControllerState, (ItemListNodeState, (Int, Bool?) -> Void)) in
        let text = ExteraStrings(languageCode: presentation.strings.baseLanguageCode)
        let data = ItemListPresentationData(presentation)
        let config = ExteraNavigationAppearance(store: store)
        let appearance = store.value(for: ExteraPreferences.interfaceAppearance)
        let automaticBar = appearance.inheritBarStyle ?? (appearance.barStyle == .telegram)
        let automaticDrawer = appearance.inheritDrawerStyle ?? (appearance.surfaceStyle == .telegram)
        let options: [(InterfaceRow, String, SettingsRow.Kind)] = [
            (.mode, text.text("Navigation mode", "Режим навигации"), .disclosure(config.drawerMode.title(text))),
            (.bar, text.text("Bottom bar style", "Стиль нижней панели"), .disclosure(config.interface.barStyle.title(text))),
            (.labels, text.text("Hide tab labels", "Скрыть подписи вкладок"), .toggle(config.hidesLabels)),
            (.radius, text.text("Navigation corner radius", "Скругление панелей"), .disclosure(String(config.interface.barRadius))),
            (.material, text.text("Drawer material", "Материал бокового меню"), .disclosure(config.interface.surfaceStyle.title(text))),
            (.width, text.text("Side menu width", "Ширина бокового меню"), .disclosure("\(config.interface.drawerWidth)%")),
            (.opacity, text.text("Side menu opacity", "Непрозрачность бокового меню"), .disclosure("\(config.interface.drawerOpacity)%")),
            (.drawerItems, text.text("Side menu items", "Пункты бокового меню"), .disclosure("")),
            (.useAppBar, text.text("Use interface style for bar", "Применять стиль приложения к панели"), .toggle(automaticBar)),
            (.useAppDrawer, text.text("Use interface style for menu", "Применять стиль приложения к боковому меню"), .toggle(automaticDrawer)),
        ]
        let rows = [SettingsRow(stableId: -1, section: 0, title: "", kind: .preview(.interface(config)))] + options.filter {
            ($0.0 != .bar || !automaticBar) && ($0.0 != .material || !automaticDrawer)
        }.map { row, title, kind in
            SettingsRow(stableId: row.rawValue, section: row.rawValue < 4 ? 1 : 2, title: title, kind: kind)
        }
        return (ItemListControllerState(presentationData: data, title: .text(text.text("Bars and side menu", "Панели и боковое меню")),
            leftNavigationButton: nil, rightNavigationButton: nil, backNavigationButton: ItemListBackButton(title: presentation.strings.Common_Back)),
            (ItemListNodeState(presentationData: data, entries: rows, style: .blocks, animateChanges: false), action))
    }
    let result = ExteraSettingsListController(context: context, state: state)
    controller = result
    return result
}

private func exteraDrawerItemsController(context: AccountContext) -> ViewController {
    let store = ExteraSettingsStore.shared
    let items = ExteraDrawerItem.allCases
    let action: (Int, Bool?) -> Void = { id, enabled in
        var config = store.value(for: ExteraPreferences.interfaceAppearance).normalized
        if let enabled, items.indices.contains(id), !items[id].locked {
            if enabled { config.hiddenDrawerItems.remove(items[id]) } else { config.hiddenDrawerItems.insert(items[id]) }
        } else if items.indices.contains(id - 20) {
            config.moveUp(items[id - 20])
        } else if id == 100 {
            config.drawerOrder = items
            config.hiddenDrawerItems = []
        } else {
            return
        }
        store.set(config.normalized, for: ExteraPreferences.interfaceAppearance)
    }
    let state = combineLatest(context.sharedContext.presentationData, store.changes)
    |> map { presentation, _ -> (ItemListControllerState, (ItemListNodeState, (Int, Bool?) -> Void)) in
        let text = ExteraStrings(languageCode: presentation.strings.baseLanguageCode)
        let data = ItemListPresentationData(presentation)
        let config = ExteraNavigationAppearance(store: store)
        var rows = [SettingsRow(stableId: -1, section: 0, title: "", kind: .preview(.interface(config)))]
        for (id, item) in items.enumerated() where !item.locked {
            rows.append(SettingsRow(stableId: id, section: 1, title: item.title(text), kind: .toggle(!config.interface.hiddenDrawerItems.contains(item))))
        }
        for (id, item) in items.enumerated() {
            let name = item.title(text)
            let position = (config.interface.drawerOrder.firstIndex(of: item) ?? id) + 1
            let title = text.text("\(position). Move \(name) up", "\(position). Поднять «\(name)»")
            rows.append(SettingsRow(stableId: id + 20, section: 2, title: title, kind: .action))
        }
        rows.append(SettingsRow(stableId: 100, section: 3, title: text.text("Restore default menu", "Восстановить меню"), kind: .action))
        return (ItemListControllerState(presentationData: data, title: .text(text.text("Side menu items", "Пункты бокового меню")),
            leftNavigationButton: nil, rightNavigationButton: nil, backNavigationButton: ItemListBackButton(title: presentation.strings.Common_Back)),
            (ItemListNodeState(presentationData: data, entries: rows, style: .blocks, animateChanges: false), action))
    }
    return ExteraSettingsListController(context: context, state: state)
}
