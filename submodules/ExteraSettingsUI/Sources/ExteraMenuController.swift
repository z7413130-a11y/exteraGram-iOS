import AccountContext
import Display
import ExteraSettings
import ItemListUI
import PresentationDataUtils
import SwiftSignalKit

private enum MenuRow: Int, CaseIterable {
    case material, opacity, blur, radius, saturation, gleam, outline

    func title(_ strings: ExteraStrings) -> String {
        switch self {
        case .material: return strings.text("Menu material", "Материал меню")
        case .opacity: return strings.text("Opacity", "Непрозрачность")
        case .blur: return strings.text("Blur strength", "Интенсивность размытия")
        case .radius: return strings.text("Corner radius", "Радиус скругления")
        case .saturation: return strings.text("Tint saturation", "Насыщенность оттенка")
        case .gleam: return strings.text("Highlight strength", "Выраженность блика")
        case .outline: return strings.text("Outline", "Контур")
        }
    }
}

func exteraMenuController(context: AccountContext) -> ViewController {
    let store = ExteraSettingsStore.shared
    weak var controller: ItemListController?
    let action: (Int, Bool?) -> Void = { id, _ in
        guard let row = MenuRow(rawValue: id) else { return }
        let strings = ExteraStrings(languageCode: context.sharedContext.currentPresentationData.with { $0 }.strings.baseLanguageCode)
        let preview: () -> ExteraLivePreview = {
            let menu = store.value(for: ExteraPreferences.menuAppearance).resolved(for: store.value(for: ExteraPreferences.interfaceStyle))
            let outline = ExteraMenuOutline(rawValue: store.value(for: ExteraPreferences.glassOutlineStyle)) ?? .standard
            return .menu(menu, outline)
        }
        if row == .outline {
            controller?.push(exteraChoiceController(context: context, title: row.title(strings),
                selectedIndex: { store.value(for: ExteraPreferences.glassOutlineStyle) },
                titles: ExteraMenuOutline.allCases.map { $0.title(strings) }, preview: preview,
                select: { store.set($0, for: ExteraPreferences.glassOutlineStyle) }))
            return
        }
        func choose<T: Equatable>(_ options: [T], _ key: WritableKeyPath<ExteraMenuAppearance, T>, format: (T) -> String) {
            controller?.push(exteraChoiceController(context: context, title: row.title(strings), selectedIndex: {
                options.firstIndex(of: store.value(for: ExteraPreferences.menuAppearance).normalized[keyPath: key])
            }, titles: options.map(format), preview: preview, select: { index in
                var config = store.value(for: ExteraPreferences.menuAppearance).normalized
                config[keyPath: key] = options[index]
                store.set(config, for: ExteraPreferences.menuAppearance)
            }))
        }
        switch row {
        case .material: choose(ExteraMenuMaterial.allCases, \.material, format: { $0.title(strings) })
        case .opacity: choose([45, 55, 65, 76, 85, 100], \.opacity, format: { "\($0)%" })
        case .blur: choose([0, 25, 50, 64, 80, 100], \.blur, format: { "\($0)%" })
        case .radius: choose([8, 12, 16, 22, 26, 30, 36], \.radius, format: String.init)
        case .saturation: choose([0, 20, 40, 60, 80, 100], \.saturation, format: { "\($0)%" })
        case .gleam: choose([0, 20, 40, 60, 80, 100], \.gleam, format: { "\($0)%" })
        case .outline: break
        }
    }
    let state = combineLatest(context.sharedContext.presentationData, store.changes)
    |> map { presentation, _ -> (ItemListControllerState, (ItemListNodeState, (Int, Bool?) -> Void)) in
        let strings = ExteraStrings(languageCode: presentation.strings.baseLanguageCode)
        let data = ItemListPresentationData(presentation)
        let config = store.value(for: ExteraPreferences.menuAppearance).normalized
        let effective = config.resolved(for: store.value(for: ExteraPreferences.interfaceStyle))
        let outline = ExteraMenuOutline(rawValue: store.value(for: ExteraPreferences.glassOutlineStyle)) ?? .standard
        let values = [config.material.title(strings), "\(config.opacity)%", "\(config.blur)%", String(config.radius),
            "\(config.saturation)%", "\(config.gleam)%", outline.title(strings)]
        let applicable = MenuRow.allCases.filter { row in
            if effective.material == .telegram { return row == .material }
            if row == .gleam { return effective.material == .liquidGlass || outline == .gleam }
            return true
        }
        let rows = [SettingsRow(stableId: -1, section: 0, title: "", kind: .preview(.menu(effective, outline)))] + applicable.map { row in
            SettingsRow(stableId: row.rawValue, section: 1, title: row.title(strings), kind: .disclosure(values[row.rawValue]))
        }
        return (ItemListControllerState(presentationData: data, title: .text(strings.text("Glass and context menus", "Стекло и контекстные меню")),
            leftNavigationButton: nil, rightNavigationButton: nil, backNavigationButton: ItemListBackButton(title: presentation.strings.Common_Back)),
            (ItemListNodeState(presentationData: data, entries: rows, style: .blocks, animateChanges: false), action))
    }
    let result = ExteraSettingsListController(context: context, state: state)
    controller = result
    return result
}
