import AccountContext
import Display
import ExteraSettings
import ItemListUI
import PresentationDataUtils
import SwiftSignalKit
import TelegramPresentationData

private func appIconTitle(_ icon: PresentationAppIcon, _ strings: ExteraStrings) -> String {
    switch icon.name {
    case "ExteraGram": return "exteraGram"
    case "BlueIcon": return strings.text("Blue", "Синяя")
    case "BlackIcon": return strings.text("Black", "Чёрная")
    case "BlueClassicIcon": return strings.text("Classic blue", "Классическая синяя")
    case "BlackClassicIcon": return strings.text("Classic black", "Классическая чёрная")
    case "BlueFilledIcon": return strings.text("Filled blue", "Синяя с заливкой")
    case "BlackFilledIcon": return strings.text("Filled black", "Чёрная с заливкой")
    case "New1": return strings.text("Alternate 1", "Вариант 1")
    case "New2": return strings.text("Alternate 2", "Вариант 2")
    default: return icon.name
    }
}

func exteraAppIconsController(context: AccountContext) -> ViewController {
    let bindings = context.sharedContext.applicationBindings
    let icons = bindings.getAvailableAlternateIcons().filter { !$0.isPremium }
    let currentName = bindings.getAlternateIconName()
    let currentIndex = icons.firstIndex(where: { $0.name == currentName || (currentName == nil && $0.isDefault) })
    let initial = currentIndex ?? 0
    let selected = ValuePromise<Int>(initial, ignoreRepeated: true)
    let applied = ValuePromise<Int?>(currentIndex, ignoreRepeated: true)
    let selectedIndex = Atomic(value: initial)
    var isApplying = false
    weak var controller: ItemListController?

    let action: (Int, Bool?) -> Void = { id, _ in
        if icons.indices.contains(id) {
            _ = selectedIndex.swap(id)
            selected.set(id)
            return
        }
        let index = selectedIndex.with { $0 }
        guard id == 100, !isApplying, icons.indices.contains(index) else { return }
        let icon = icons[index]
        let target = icon.isDefault ? nil : icon.name
        guard target != bindings.getAlternateIconName() else { return }
        isApplying = true
        bindings.requestSetAlternateIconName(target) { success in
            Queue.mainQueue().async {
                isApplying = false
                if success {
                    applied.set(index)
                } else {
                    let presentation = context.sharedContext.currentPresentationData.with { $0 }
                    let strings = ExteraStrings(languageCode: presentation.strings.baseLanguageCode)
                    controller?.present(textAlertController(context: context,
                        title: strings.text("Cannot change app icon", "Не удалось сменить иконку"),
                        text: strings.text("This installation did not allow iOS to apply the selected icon.", "iOS не применила иконку для этой установки."),
                        actions: [TextAlertAction(type: .defaultAction, title: presentation.strings.Common_OK, action: {})]), in: .window(.root))
                }
            }
        }
    }

    let state = combineLatest(context.sharedContext.presentationData, selected.get(), applied.get())
    |> map { presentation, selection, installed -> (ItemListControllerState, (ItemListNodeState, (Int, Bool?) -> Void)) in
        let data = ItemListPresentationData(presentation)
        let strings = ExteraStrings(languageCode: presentation.strings.baseLanguageCode)
        var rows: [SettingsRow] = []
        if icons.indices.contains(selection) {
            let current = icons[selection]
            rows.append(SettingsRow(stableId: -1, section: 0, title: "", kind: .preview(.appIcon(imageName: current.imageName,
                title: appIconTitle(current, strings), credit: current.isDefault ? "exteraGram iOS Port" : "Telegram iOS"))))
        }
        rows += icons.enumerated().map { index, icon in
            let title = appIconTitle(icon, strings) + (index == installed ? strings.text(" · Active", " · Активная") : "")
            return SettingsRow(stableId: index, section: 1, title: title, kind: .appIcon(icon.imageName, index == selection))
        }
        if !icons.isEmpty {
            rows.append(SettingsRow(stableId: 100, section: 2, title: strings.text("Apply icon", "Применить иконку"), kind: .action))
        }
        return (ItemListControllerState(presentationData: data, title: .text(ExteraAppearancePage.appIcons.title(strings)),
            leftNavigationButton: nil, rightNavigationButton: nil, backNavigationButton: ItemListBackButton(title: presentation.strings.Common_Back)),
            (ItemListNodeState(presentationData: data, entries: rows, style: .blocks, animateChanges: false), action))
    }
    let result = ItemListController(context: context, state: state)
    controller = result
    return result
}
