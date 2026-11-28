import AccountContext
import Display
import ExteraSettings
import ItemListUI
import PresentationDataUtils
import SwiftSignalKit
import TelegramPresentationData
import UIKit

private enum PillRow: Int {
    case refresh = 20
    case height
    case radius
    case opacity
    case material
    case aboveFolders
    case loop
    case external, city, sources

    func title(_ strings: ExteraStrings) -> String {
        switch self {
        case .refresh: return strings.text("Refresh interval", "Интервал обновления")
        case .height: return strings.text("Capsule height", "Высота капсул")
        case .radius: return strings.text("Corner radius", "Радиус скругления")
        case .opacity: return strings.text("Opacity", "Непрозрачность")
        case .material: return strings.text("Capsule style", "Стиль капсул")
        case .aboveFolders: return strings.text("Place above chat folders", "Разместить над папками чатов")
        case .loop: return strings.text("Continuous horizontal scrolling", "Непрерывная горизонтальная прокрутка")
        case .external: return strings.text("Allow weather and market requests", "Разрешить запросы погоды и курсов")
        case .city: return strings.text("Weather city", "Город для погоды")
        case .sources: return strings.text("Data sources", "Источники данных")
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
        let strings = ExteraStrings(languageCode: context.sharedContext.currentPresentationData.with { $0 }.strings.baseLanguageCode)
        if ExteraPill.customSlots.indices.contains(id - 40) {
            let slot = ExteraPill.customSlots[id - 40]
            let alert = UIAlertController(title: slot.title(strings), message: strings.text("Up to 48 characters. Stored only on this device.", "До 48 символов. Текст хранится на этом устройстве."), preferredStyle: .alert)
            alert.addTextField { $0.text = store.value(for: ExteraPreferences.pillStack).text(for: slot) }
            alert.addAction(UIAlertAction(title: strings.text("Cancel", "Отмена"), style: .cancel))
            alert.addAction(UIAlertAction(title: strings.text("Save", "Сохранить"), style: .default) { [weak alert] _ in
                if let text = alert?.textFields?.first?.text { update { $0.setText(text, for: slot) } }
            })
            context.sharedContext.applicationBindings.presentNativeController(alert)
            return
        }
        guard let row = PillRow(rawValue: id) else { return }
        let preview: () -> ExteraLivePreview = {
            var config = store.value(for: ExteraPreferences.pillStack).normalized
            if config.widgets.isEmpty { config.widgets = widgets }
            return .pills(config)
        }
        func choices<T: Equatable>(_ options: [T], keyPath: WritableKeyPath<ExteraPillConfiguration, T>, format: (T) -> String) {
            controller?.push(exteraChoiceController(context: context, title: row.title(strings), selectedIndex: {
                options.firstIndex(of: store.value(for: ExteraPreferences.pillStack).normalized[keyPath: keyPath])
            }, titles: options.map(format), preview: preview, select: { index in
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
        case .external:
            guard let enabled else { return }
            if !enabled {
                update { $0.allowExternalSources = false }
            } else {
                let presentation = context.sharedContext.currentPresentationData.with { $0 }
                controller?.present(textAlertController(context: context, title: row.title(strings),
                    text: strings.text("Coinbase receives a public exchange-rate request. Open-Meteo receives the coordinates of the city you choose. The app sends no device location or account details.",
                        "Coinbase получает публичный запрос курсов. Open-Meteo получает координаты выбранного города. Геопозиция устройства и данные аккаунта не передаются."),
                    actions: [
                        TextAlertAction(type: .genericAction, title: presentation.strings.Common_Cancel, action: {}),
                        TextAlertAction(type: .defaultAction, title: strings.text("Allow", "Разрешить"), action: {
                            update { $0.allowExternalSources = true }
                        }),
                    ]), in: .window(.root))
            }
        case .city:
            let cities = ExteraWeatherCity.allCases
            controller?.push(exteraChoiceController(context: context, title: row.title(strings), selectedIndex: {
                store.value(for: ExteraPreferences.pillStack).weatherCity.flatMap { cities.firstIndex(of: $0) }.map { $0 + 1 } ?? 0
            }, titles: [strings.text("No city", "Город не выбран")] + cities.map { $0.title(strings) }, preview: preview, select: { index in
                update { $0.weatherCity = index == 0 ? nil : cities[index - 1] }
            }))
        case .sources:
            controller?.present(textAlertController(context: context, title: row.title(strings),
                text: strings.text("Temperature data by Open-Meteo. Market rates by Coinbase. GRAM uses the TON rate, as in exteraGram Android. ≈ marks a cached value.",
                    "Температура от Open-Meteo. Курсы от Coinbase. Для GRAM используется курс TON, как в exteraGram Android. ≈ обозначает значение из кеша."),
                actions: [
                    TextAlertAction(type: .genericAction, title: "Open-Meteo", action: { context.sharedContext.applicationBindings.openUrl("https://open-meteo.com/") }),
                    TextAlertAction(type: .genericAction, title: "Coinbase", action: { context.sharedContext.applicationBindings.openUrl("https://www.coinbase.com/") }),
                    TextAlertAction(type: .defaultAction, title: strings.text("Close", "Закрыть"), action: {}),
                ]), in: .window(.root))
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
            (.external, .toggle(config.allowExternalSources == true)),
            (.city, .disclosure(config.weatherCity?.title(strings) ?? strings.text("No city", "Город не выбран"))),
            (.sources, .disclosure("")),
        ]
        rows += options.map { SettingsRow(stableId: $0.0.rawValue, section: 3, title: $0.0.title(strings), kind: $0.1) }
        for (index, slot) in ExteraPill.customSlots.enumerated() where config.widgets.contains(slot) {
            rows.append(SettingsRow(stableId: 40 + index, section: 4, title: slot.title(strings), kind: .disclosure(config.text(for: slot) ?? "")))
        }
        return (ItemListControllerState(presentationData: data, title: .text("Pill Stack"),
            leftNavigationButton: nil, rightNavigationButton: nil, backNavigationButton: ItemListBackButton(title: presentation.strings.Common_Back)),
            (ItemListNodeState(presentationData: data, entries: rows, style: .blocks, animateChanges: false), action))
    }
    let result = ExteraSettingsListController(context: context, state: state)
    controller = result
    return result
}
