import AccountContext
import Display
import ExteraSettings
import ItemListUI
import PresentationDataUtils
import SwiftSignalKit
import TelegramPresentationData

private enum PillRow: Int {
    case refresh = 20
    case height
    case radius
    case opacity
    case material
    case aboveFolders
    case loop

    func title(_ strings: ExteraStrings) -> String {
        switch self {
        case .refresh: return strings.text("Refresh interval", "Интервал обновления")
        case .height: return strings.text("Capsule height", "Высота капсул")
        case .radius: return strings.text("Corner radius", "Радиус скругления")
        case .opacity: return strings.text("Opacity", "Непрозрачность")
        case .material: return strings.text("Capsule style", "Стиль капсул")
        case .aboveFolders: return strings.text("Place above chat folders", "Разместить над папками чатов")
        case .loop: return strings.text("Continuous horizontal scrolling", "Непрерывная горизонтальная прокрутка")
        }
    }
}

func exteraPillSettingsController(context: AccountContext) -> ViewController {
    let store = ExteraSettingsStore.shared
    weak var controller: ItemListController?
    let widgets = ExteraPill.allCases
    func update(_ mutate: (inout ExteraPillConfiguration) -> Void) {
        var config = store.value(for: ExteraPreferences.pillStack).normalized
        mutate(&config)
        store.set(config.normalized, for: ExteraPreferences.pillStack)
    }

    let action: (Int, Bool?) -> Void = { id, enabled in
        if widgets.indices.contains(id), let enabled {
            update { $0.setEnabled(enabled, widget: widgets[id]) }
            return
        }
        if widgets.indices.contains(id - 10) {
            update { $0.moveUp(widgets[id - 10]) }
            return
        }
        guard let row = PillRow(rawValue: id) else { return }
        let strings = ExteraStrings(languageCode: context.sharedContext.currentPresentationData.with { $0 }.strings.baseLanguageCode)
        func choices<T: Equatable>(_ options: [T], keyPath: WritableKeyPath<ExteraPillConfiguration, T>, format: (T) -> String) {
            controller?.push(exteraChoiceController(context: context, title: row.title(strings), selectedIndex: {
                options.firstIndex(of: store.value(for: ExteraPreferences.pillStack).normalized[keyPath: keyPath])
            }, titles: options.map(format), select: { index in
                update { $0[keyPath: keyPath] = options[index] }
            }))
        }
        switch row {
        case .refresh: choices(ExteraPillConfiguration.refreshIntervals, keyPath: \.refreshInterval, format: { "\($0) \(strings.text("s", "с"))" })
        case .height: choices([30, 34, 38, 42, 46], keyPath: \.capsuleHeight, format: String.init)
        case .radius: choices([0, 8, 12, 16, 20, 23], keyPath: \.cornerRadius, format: String.init)
        case .opacity: choices([30, 50, 70, 90, 100], keyPath: \.opacity, format: { "\($0)%" })
        case .material: choices(ExteraPillConfiguration.Material.allCases, keyPath: \.material, format: { $0.title(strings) })
        case .aboveFolders:
            if let enabled { update { $0.aboveFolders = enabled } }
        case .loop:
            if let enabled { update { $0.loops = enabled } }
        }
    }

    let state = combineLatest(context.sharedContext.presentationData, store.changes)
    |> map { presentation, _ -> (ItemListControllerState, (ItemListNodeState, (Int, Bool?) -> Void)) in
        let strings = ExteraStrings(languageCode: presentation.strings.baseLanguageCode)
        let data = ItemListPresentationData(presentation)
        let config = store.value(for: ExteraPreferences.pillStack).normalized
        var preview = config
        if preview.widgets.isEmpty { preview.widgets = widgets }
        var rows = [
            SettingsRow(stableId: -2, section: 0, title: "", kind: .preview(.pills(preview))),
            SettingsRow(stableId: -1, section: 0,
                title: strings.text("Enable widgets to show them in the chat list. Capsule values are read on this device.", "Включённые виджеты появятся в списке чатов. Данные капсул читаются на этом устройстве."),
                kind: .note),
        ]
        for (index, widget) in widgets.enumerated() {
            let order = config.widgets.firstIndex(of: widget)
            let title = order.map { "\($0 + 1). \(widget.title(strings))" } ?? widget.title(strings)
            rows.append(SettingsRow(stableId: index, section: 1, title: title, kind: .toggle(order != nil)))
        }
        for (index, widget) in widgets.enumerated() where (config.widgets.firstIndex(of: widget) ?? 0) > 0 {
            let title = strings.text("Move \(widget.title(strings)) up", "Поднять «\(widget.title(strings))»")
            rows.append(SettingsRow(stableId: 10 + index, section: 2, title: title, kind: .action))
        }
        let options: [(PillRow, SettingsRow.Kind)] = [
            (.refresh, .disclosure("\(config.refreshInterval) \(strings.text("s", "с"))")),
            (.height, .disclosure(String(config.capsuleHeight))),
            (.radius, .disclosure(String(config.cornerRadius))),
            (.opacity, .disclosure("\(config.opacity)%")),
            (.material, .disclosure(config.material.title(strings))),
            (.aboveFolders, .toggle(config.aboveFolders)),
            (.loop, .toggle(config.loops)),
        ]
        rows += options.map { SettingsRow(stableId: $0.0.rawValue, section: 3, title: $0.0.title(strings), kind: $0.1) }
        return (ItemListControllerState(presentationData: data, title: .text("Pill Stack"),
            leftNavigationButton: nil, rightNavigationButton: nil, backNavigationButton: ItemListBackButton(title: presentation.strings.Common_Back)),
            (ItemListNodeState(presentationData: data, entries: rows, style: .blocks, animateChanges: false), action))
    }
    let result = ItemListController(context: context, state: state)
    controller = result
    return result
}
