import AccountContext
import Display
import ExteraSettings
import ItemListUI
import PresentationDataUtils
import SwiftSignalKit

func exteraMotionController(context: AccountContext) -> ViewController {
    let store = ExteraSettingsStore.shared
    weak var controller: ItemListController?
    let action: (Int, Bool?) -> Void = { id, flag in
        let strings = ExteraStrings(languageCode: context.sharedContext.currentPresentationData.with { $0 }.strings.baseLanguageCode)
        func choose(_ title: String, values: [Int], text: [String], preference: ExteraPreference<Int>) {
            controller?.push(exteraChoiceController(context: context, title: title,
                selectedIndex: { values.firstIndex(of: store.value(for: preference)) }, titles: text, preview: { .motion(ExteraMotion(store: store)) },
                select: { store.set(values[$0], for: preference) }))
        }
        if let flag, let target = ExteraMotionTarget(rawValue: id - 10) {
            var targets = store.value(for: ExteraPreferences.motionTargets)
            if flag { targets.insert(target) } else { targets.remove(target) }
            store.set(targets, for: ExteraPreferences.motionTargets)
            return
        }
        switch id {
        case 0:
            let styles = ExteraMotionStyle.allCases
            choose(strings.text("Animation style", "Стиль анимации"), values: styles.map(\.rawValue), text: styles.map { $0.title(strings) }, preference: ExteraPreferences.transitionAnimation)
        case 1:
            let speeds = [60, 80, 100, 120, 140, 160]
            choose(strings.text("Speed", "Скорость"), values: speeds, text: speeds.map { "\($0)%" }, preference: ExteraPreferences.motionSpeed)
        case 2:
            let levels = [0, 25, 50, 75, 100]
            choose(strings.text("Spring strength", "Интенсивность пружины"), values: levels, text: levels.map { "\($0)%" }, preference: ExteraPreferences.motionSpring)
        default: break
        }
    }
    let state = combineLatest(context.sharedContext.presentationData, store.changes)
    |> map { presentation, _ -> (ItemListControllerState, (ItemListNodeState, (Int, Bool?) -> Void)) in
        let strings = ExteraStrings(languageCode: presentation.strings.baseLanguageCode)
        let data = ItemListPresentationData(presentation)
        let config = ExteraNavigationAppearance(store: store, previewingBoth: true)
        var rows = [
            SettingsRow(stableId: -1, section: 0, title: "", kind: .preview(.motion(config.motion))),
            SettingsRow(stableId: 0, section: 1, title: strings.text("Animation style", "Стиль анимации"), kind: .disclosure(config.motion.style.title(strings))),
        ]
        if config.motion.style != .minimal {
            rows.append(SettingsRow(stableId: 1, section: 1, title: strings.text("Speed", "Скорость"), kind: .disclosure("\(config.motion.speed)%")))
        }
        if config.motion.style == .spring {
            rows.append(SettingsRow(stableId: 2, section: 1, title: strings.text("Spring strength", "Интенсивность пружины"), kind: .disclosure("\(config.motion.springStrength)%")))
        }
        rows += ExteraMotionTarget.allCases.map { target in
            SettingsRow(stableId: 10 + target.rawValue, section: 2, title: target.title(strings), kind: .toggle(config.motion.targets.contains(target)))
        }
        rows.append(SettingsRow(stableId: 30, section: 3, title: strings.text("Navigation keeps native swipe gestures. Scale applies to the side menu. iOS Reduce Motion takes priority.", "Навигация сохраняет штатные жесты. Масштабирование применяется к боковому меню. Системное уменьшение движения имеет приоритет."), kind: .note))
        return (ItemListControllerState(presentationData: data, title: .text(strings.text("Animations", "Анимации")),
            leftNavigationButton: nil, rightNavigationButton: nil, backNavigationButton: ItemListBackButton(title: presentation.strings.Common_Back)),
            (ItemListNodeState(presentationData: data, entries: rows, style: .blocks, animateChanges: false), action))
    }
    let result = ExteraSettingsListController(context: context, state: state)
    controller = result
    return result
}
