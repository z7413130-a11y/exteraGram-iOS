import ExteraSettings
import ItemListUI
import UIKit

final class ExteraInterfacePreviewView: UIView {
    private let bar = UIView()
    private let barMaterial = ExteraMaterialView(frame: .zero)
    private let launcher = UIButton(type: .system)
    private let caption = UILabel()
    private let drawer = ExteraDrawerView(frame: .zero)
    private var config: ExteraNavigationAppearance?
    private var shown = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.clipsToBounds = true
        self.addSubview(self.caption)
        self.addSubview(self.barMaterial)
        self.addSubview(self.bar)
        self.addSubview(self.launcher)
        self.addSubview(self.drawer)
        self.caption.numberOfLines = 0
        self.caption.textAlignment = .center
        self.caption.font = .preferredFont(forTextStyle: .caption1)
        self.launcher.setImage(UIImage(systemName: "line.3.horizontal"), for: .normal)
        self.launcher.addAction(UIAction { [weak self] _ in self?.toggleDrawer() }, for: .touchUpInside)
        self.drawer.isHidden = true
    }

    required init?(coder: NSCoder) { return nil }

    func configure(config: ExteraNavigationAppearance, data: ItemListPresentationData, strings: ExteraStrings) {
        self.config = config
        let theme = data.theme
        let tabs = config.order.filter { ($0 != .calls || !config.hidesCalls) && ($0 != .news || !config.hidesNews) }
        self.caption.text = strings.text("Tap the menu or choose a tab", "Нажми на меню или выбери вкладку")
        self.caption.textColor = theme.list.itemPrimaryTextColor
        self.launcher.tintColor = theme.list.itemAccentColor
        self.launcher.accessibilityLabel = strings.text("Preview side menu", "Предпросмотр бокового меню")
        let style: ExteraSurfaceStyle = config.interface.barStyle == .glass ? .liquidGlass : config.interface.barStyle == .floating ? .classic : .telegram
        self.barMaterial.update(style: style, fill: theme.list.itemBlocksBackgroundColor, tint: theme.list.itemAccentColor,
            dark: theme.overallDarkAppearance, radius: CGFloat(config.interface.barRadius))
        let items = UIStackView()
        items.distribution = .fillEqually
        let active = config.order.first(where: { tabs.contains($0) })
        for tab in tabs {
            let button = UIButton(type: .system)
            var content = UIButton.Configuration.plain()
            content.image = config.iconPack.image(tab) ?? UIImage(systemName: tab.symbol)
            content.title = config.hidesLabels ? nil : tab.title(strings)
            content.imagePlacement = .top
            content.imagePadding = 2
            content.baseForegroundColor = tab == active ? theme.list.itemAccentColor : theme.list.itemSecondaryTextColor
            content.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
                var attributes = attributes
                attributes.font = UIFont.systemFont(ofSize: 9)
                return attributes
            }
            content.titleLineBreakMode = .byWordWrapping
            content.contentInsets = .zero
            button.configuration = content
            button.accessibilityLabel = tab.title(strings)
            button.addAction(UIAction { [weak self, weak button] _ in
                self?.caption.text = tab.title(strings)
                for view in button?.superview?.subviews ?? [] {
                    if let item = view as? UIButton {
                        item.configuration?.baseForegroundColor = item === button ? theme.list.itemAccentColor : theme.list.itemSecondaryTextColor
                    }
                }
            }, for: .touchUpInside)
            items.addArrangedSubview(button)
        }
        self.bar.subviews.forEach { $0.removeFromSuperview() }
        items.frame = self.bar.bounds
        items.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.bar.addSubview(items)
        self.bar.isHidden = config.drawerMode == .drawer
        self.barMaterial.isHidden = self.bar.isHidden
        self.drawer.configure(appearance: config.interface, geometry: config.geometry, sectionRadius: CGFloat(config.sectionRadius), fill: theme.list.itemBlocksBackgroundColor,
            foreground: theme.list.itemPrimaryTextColor, accent: theme.list.itemAccentColor, dark: theme.overallDarkAppearance,
            title: strings.text("Preview account", "Пример аккаунта"), subtitle: nil, photo: nil,
            closeLabel: strings.text("Close menu", "Закрыть меню"), sectionTitle: strings.text("Navigation", "Навигация"),
            items: config.interface.drawerOrder.filter { !config.interface.hiddenDrawerItems.contains($0) }.map { item in
                ExteraDrawerRow(title: item.title(strings), symbol: item.symbol, image: config.iconPack.image(item), selected: item == .chats, action: { [weak self] in
                    self?.caption.text = item.title(strings)
                    self?.toggleDrawer()
                })
            }, onClose: { [weak self] in self?.toggleDrawer() })
        self.setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.launcher.frame = CGRect(x: 4, y: 0, width: 44, height: 44)
        self.caption.frame = CGRect(x: 44, y: 49, width: max(1, self.bounds.width - 68), height: 46)
        let inset: CGFloat = self.config?.interface.barStyle == .floating ? 16 : 3
        let height: CGFloat = self.config?.hidesLabels == true ? 43 : 51
        self.bar.frame = CGRect(x: inset, y: self.bounds.height - height - inset,
            width: max(1, self.bounds.width - inset * 2), height: height)
        self.barMaterial.frame = self.bar.frame
        self.drawer.frame = CGRect(x: 0, y: 0, width: max(1, self.bounds.width * CGFloat(self.config?.interface.drawerWidth ?? 80) / 100),
            height: self.bounds.height)
    }

    private func toggleDrawer() {
        self.shown.toggle()
        let shown = self.shown
        if shown { self.drawer.isHidden = false }
        let motion = (self.config?.motion ?? ExteraMotion()).forTarget(.menus)
        let offset = motion.restingOffset(horizontal: -self.drawer.bounds.width)
        if shown { self.drawer.transform = offset }
        motion.animate(duration: 0.28, {
            self.drawer.transform = shown ? .identity : offset
            self.drawer.alpha = shown ? 1 : 0
        }, completion: { [weak self] finished in
            if finished && self?.shown == shown { self?.drawer.isHidden = !shown }
        })
    }
}
