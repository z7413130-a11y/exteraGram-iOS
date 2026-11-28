import AccountContext
import Display
import ExteraSettings
import ItemListUI
import PresentationDataUtils
import SwiftSignalKit
import UIKit
import UniformTypeIdentifiers

private final class ExteraIconPackPicker: NSObject, UIDocumentPickerDelegate {
    var importPack: ((URL) -> Void)?
    var exportDirectory: URL?

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        if self.exportDirectory != nil {
            self.finishExport()
        } else if let url = urls.first {
            self.importPack?(url)
        }
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        self.finishExport()
    }

    func finishExport() {
        if let exportDirectory = self.exportDirectory {
            try? FileManager.default.removeItem(at: exportDirectory)
            self.exportDirectory = nil
        }
    }
}

func exteraIconPacksController(context: AccountContext) -> ViewController {
    let store = ExteraSettingsStore.shared
    let pickerDelegate = ExteraIconPackPicker()
    weak var controller: ItemListController?

    func showImportError(_ strings: ExteraStrings) {
        let alert = textAlertController(context: context,
            title: strings.text("Icon pack unavailable", "Набор иконок недоступен"),
            text: strings.text("Use a JSON pack exported by exteraGram with valid iOS symbols. Up to 12 custom packs can be installed.", "Используй JSON из exteraGram с системными символами iOS. Можно установить до 12 своих наборов."),
            actions: [TextAlertAction(type: .defaultAction, title: "OK", action: {})])
        controller?.present(alert, in: .window(.root))
    }
    pickerDelegate.importPack = { url in
        let strings = ExteraStrings(languageCode: context.sharedContext.currentPresentationData.with { $0 }.strings.baseLanguageCode)
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        do {
            let file = try FileHandle(forReadingFrom: url)
            defer { try? file.close() }
            guard let bytes = try file.read(upToCount: 12_289), bytes.count <= 12_288,
                  let pack = try JSONDecoder().decode(ExteraCustomIconPack.self, from: bytes).validated() else {
                showImportError(strings)
                return
            }
            var packs = store.value(for: ExteraPreferences.customIconPacks)
            if let existing = packs.firstIndex(where: { $0.id == pack.id }) {
                packs[existing] = pack
            } else if packs.count < 12 {
                packs.append(pack)
            } else {
                showImportError(strings)
                return
            }
            store.set(packs, for: ExteraPreferences.customIconPacks)
            store.set(pack.id, for: ExteraPreferences.activeCustomIconPack)
            store.set(3, for: ExteraPreferences.iconPack)
        } catch {
            showImportError(strings)
        }
    }

    let action: (Int, Bool?) -> Void = { id, _ in
        let current = ExteraIconPack(store: store)
        let packs = store.value(for: ExteraPreferences.customIconPacks)
        let strings = ExteraStrings(languageCode: context.sharedContext.currentPresentationData.with { $0 }.strings.baseLanguageCode)
        if let standard = ExteraBuiltInIconPack(rawValue: id) {
            store.set(standard.rawValue, for: ExteraPreferences.iconPack)
        } else if id == 30 {
            let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.json], asCopy: true)
            picker.delegate = pickerDelegate
            context.sharedContext.applicationBindings.presentNativeController(picker)
        } else if id == 31 {
            let data: Data
            do {
                switch current {
                case let .custom(pack):
                    let encoder = JSONEncoder()
                    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
                    data = try encoder.encode(pack)
                case .builtIn:
                    data = try JSONSerialization.data(withJSONObject: [
                        "id": UUID().uuidString, "name": "exteraGram Symbols",
                        "symbols": ["chats": "bubble.left.and.bubble.right", "calls": "phone", "settings": "gearshape"],
                    ], options: [.prettyPrinted, .sortedKeys])
                }
                pickerDelegate.finishExport()
                let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
                pickerDelegate.exportDirectory = directory
                let url = directory.appendingPathComponent("exteraGram-icons.json")
                try data.write(to: url, options: .atomic)
                let picker = UIDocumentPickerViewController(forExporting: [url], asCopy: true)
                picker.delegate = pickerDelegate
                context.sharedContext.applicationBindings.presentNativeController(picker)
            } catch {
                pickerDelegate.finishExport()
                showImportError(strings)
            }
        } else if id == 32, case let .custom(pack) = current {
            let alert = textAlertController(context: context,
                title: strings.text("Remove icon pack?", "Удалить набор иконок?"), text: pack.name,
                actions: [
                    TextAlertAction(type: .genericAction, title: strings.text("Cancel", "Отмена"), action: {}),
                    TextAlertAction(type: .destructiveAction, title: strings.text("Remove", "Удалить"), action: {
                        store.set(0, for: ExteraPreferences.iconPack)
                        store.set(nil, for: ExteraPreferences.activeCustomIconPack)
                        store.set(store.value(for: ExteraPreferences.customIconPacks).filter { $0.id != pack.id }, for: ExteraPreferences.customIconPacks)
                    }),
                ])
            controller?.present(alert, in: .window(.root))
        } else if (10..<22).contains(id), packs.indices.contains(id - 10) {
            store.set(packs[id - 10].id, for: ExteraPreferences.activeCustomIconPack)
            store.set(3, for: ExteraPreferences.iconPack)
        }
    }

    let state = combineLatest(context.sharedContext.presentationData, store.changes)
    |> map { presentation, _ -> (ItemListControllerState, (ItemListNodeState, (Int, Bool?) -> Void)) in
        let strings = ExteraStrings(languageCode: presentation.strings.baseLanguageCode)
        let data = ItemListPresentationData(presentation)
        let config = ExteraNavigationAppearance(store: store)
        var rows = [SettingsRow(stableId: -1, section: 0, title: "", kind: .preview(.interface(ExteraNavigationAppearance(store: store, previewingBoth: true))))]
        rows += ExteraBuiltInIconPack.allCases.map { pack in
            SettingsRow(stableId: pack.rawValue, section: 1, title: pack.title(strings), kind: .language(config.iconPack == .builtIn(pack)))
        }
        rows += store.value(for: ExteraPreferences.customIconPacks).enumerated().map { index, pack in
            SettingsRow(stableId: index + 10, section: 1, title: pack.name, kind: .language(config.iconPack == .custom(pack)))
        }
        let exportTitle: String
        if case .custom = config.iconPack {
            exportTitle = strings.text("Export selected pack", "Экспортировать выбранный набор")
            rows.append(SettingsRow(stableId: 32, section: 2, title: strings.text("Remove selected pack", "Удалить выбранный набор"), kind: .action))
        } else {
            exportTitle = strings.text("Export JSON template", "Экспортировать шаблон JSON")
        }
        rows.append(SettingsRow(stableId: 30, section: 2, title: strings.text("Import icon pack", "Импортировать набор иконок"), kind: .action))
        rows.append(SettingsRow(stableId: 31, section: 2, title: exportTitle, kind: .action))
        rows.append(SettingsRow(stableId: 33, section: 3, title: "Solar: 480 Design, CC BY 4.0 · Remix: Remix Design, Apache 2.0", kind: .note))
        rows.sort()
        return (ItemListControllerState(presentationData: data, title: .text(strings.text("Icon packs", "Наборы иконок")),
            leftNavigationButton: nil, rightNavigationButton: nil, backNavigationButton: ItemListBackButton(title: presentation.strings.Common_Back)),
            (ItemListNodeState(presentationData: data, entries: rows, style: .blocks, animateChanges: false), action))
    }
    let result = ExteraSettingsListController(context: context, state: state)
    controller = result
    return result
}
