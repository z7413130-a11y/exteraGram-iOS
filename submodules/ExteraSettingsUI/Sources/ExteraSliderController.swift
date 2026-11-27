import AccountContext
import ComponentFlow
import Display
import ExteraSettings
import ItemListUI
import ListItemSliderSelectorComponent
import PresentationDataUtils
import SwiftSignalKit
import UIKit

private struct SliderRow: Equatable {
    let section: ItemListSectionId = 0
    let title: String
    let value: Double
    let limits: ClosedRange<Double>
    let lowerLabel: String
    let upperLabel: String

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let select = arguments as! (Double) -> Void
        let fraction = (min(self.limits.upperBound, max(self.limits.lowerBound, self.value)) - self.limits.lowerBound) /
            (self.limits.upperBound - self.limits.lowerBound)
        return SliderItem(component: ListItemSliderSelectorComponent(theme: presentationData.theme,
            content: .continuous(.init(value: CGFloat(fraction), lowerBoundTitle: self.lowerLabel,
                upperBoundTitle: self.upperLabel, title: self.title, valueUpdated: { progress in
                    let value = self.limits.lowerBound + Double(progress) * (self.limits.upperBound - self.limits.lowerBound)
                    select(min(self.limits.upperBound, max(self.limits.lowerBound, value.rounded())))
                })), preferNative: true, accessibilityLabel: self.title),
            color: presentationData.theme.list.itemBlocksBackgroundColor)
    }
}

private enum SliderEntry: ItemListNodeEntry {
    case preview(ExteraLivePreview)
    case slider(SliderRow)

    var section: ItemListSectionId { 0 }
    var stableId: Int {
        switch self {
        case .preview: return 0
        case .slider: return 1
        }
    }

    static func < (lhs: Self, rhs: Self) -> Bool { lhs.stableId < rhs.stableId }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        switch self {
        case let .preview(snapshot): return ExteraAppearancePreviewItem(preview: snapshot, presentationData: presentationData)
        case let .slider(row): return row.item(presentationData: presentationData, arguments: arguments)
        }
    }
}

private final class SliderItem: ListViewItem {
    let neighborDescriptor: AnyEquatable = .noNeighborInfluence
    let approximateHeight: CGFloat = 88
    let component: ListItemSliderSelectorComponent
    let color: UIColor

    init(component: ListItemSliderSelectorComponent, color: UIColor) {
        self.component = component
        self.color = color
    }

    private func layout(_ params: ListViewItemLayoutParams) -> ListViewItemNodeLayout {
        ListViewItemNodeLayout(contentSize: CGSize(width: params.width, height: self.approximateHeight), insets: .zero)
    }

    func nodeConfiguredForParams(async: @escaping (@escaping () -> Void) -> Void, params: ListViewItemLayoutParams, synchronousLoads: Bool, neighbors: ListViewItemNeighbors, completion: @escaping (ListViewItemNode, @escaping () -> (Signal<Void, NoError>?, (ListViewItemApply) -> Void)) -> Void) {
        let layout = self.layout(params)
        Queue.mainQueue().async {
            let node = SliderNode()
            node.contentSize = layout.contentSize
            node.insets = layout.insets
            completion(node, { (nil, { _ in node.apply(self, params: params) }) })
        }
    }

    func updateNode(async: @escaping (@escaping () -> Void) -> Void, node: @escaping () -> ListViewItemNode, params: ListViewItemLayoutParams, neighbors: ListViewItemNeighbors, animation: ListViewItemUpdateAnimation, completion: @escaping (ListViewItemNodeLayout, @escaping (ListViewItemApply) -> Void) -> Void) {
        Queue.mainQueue().async {
            completion(self.layout(params), { _ in (node() as? SliderNode)?.apply(self, params: params) })
        }
    }
}

private final class SliderNode: ListViewItemNode {
    private let slider = ComponentView<Empty>()

    init() { super.init(layerBacked: false) }

    func apply(_ item: SliderItem, params: ListViewItemLayoutParams) {
        self.backgroundColor = item.color
        let size = self.slider.update(transition: .immediate, component: AnyComponent(item.component), environment: {},
            containerSize: CGSize(width: max(0, params.width - params.leftInset - params.rightInset), height: item.approximateHeight))
        if let view = self.slider.view {
            if view.superview == nil { self.view.addSubview(view) }
            view.frame = CGRect(origin: CGPoint(x: params.leftInset, y: 0), size: size)
        }
    }
}

func exteraSliderController(context: AccountContext, title: String, preference: ExteraPreference<Double>, limits: ClosedRange<Double>, rangeLabels: (String, String), preview: ExteraAppearancePage) -> ViewController {
    let store = ExteraSettingsStore.shared
    let select: (Double) -> Void = { value in
        if store.value(for: preference) != value { store.set(value, for: preference) }
    }
    let state = combineLatest(context.sharedContext.presentationData, store.changes)
    |> map { presentation, _ -> (ItemListControllerState, (ItemListNodeState, (Double) -> Void)) in
        let data = ItemListPresentationData(presentation)
        let row = SliderRow(title: title, value: store.value(for: preference), limits: limits, lowerLabel: rangeLabels.0, upperLabel: rangeLabels.1)
        let strings = ExteraStrings(languageCode: presentation.strings.baseLanguageCode)
        var rows: [SliderEntry] = [.slider(row)]
        if let snapshot = preview.preview(store: store, strings: strings) {
            rows.insert(.preview(snapshot), at: 0)
        }
        return (ItemListControllerState(presentationData: data, title: .text(title),
            leftNavigationButton: nil, rightNavigationButton: nil, backNavigationButton: ItemListBackButton(title: presentation.strings.Common_Back)),
            (ItemListNodeState(presentationData: data, entries: rows, style: .blocks, animateChanges: false), select))
    }
    return ItemListController(context: context, state: state)
}
