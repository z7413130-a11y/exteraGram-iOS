import Display
import ExteraSettings
import TabBarUI
import TelegramPresentationData
import UIKit

final class ExteraRootTabBarController: TabBarControllerImpl {
    private var appearance: ExteraNavigationAppearance?
    private var tabBarHiddenForDrawer = false
    private var host: ExteraRootDrawerHost?

    func configureDrawer(_ appearance: ExteraNavigationAppearance, tabRoles: [ObjectIdentifier: ExteraTab], theme: PresentationTheme, strings: ExteraStrings, onOpen: @escaping () -> Void, onClose: @escaping () -> Void) {
        self.appearance = appearance
        self.configureExteraTabBar(appearance, roles: tabRoles)
        if appearance.drawerMode == .tabs {
            self.host?.detach()
            self.host = nil
        } else {
            let host = self.host ?? ExteraRootDrawerHost(frame: self.view.bounds)
            if host.superview == nil {
                self.view.addSubview(host)
                host.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                host.attachEdgeGesture(to: self.view)
                self.host = host
            }
            host.configure(appearance, theme: theme, strings: strings, onOpen: onOpen, onClose: onClose)
            self.view.bringSubviewToFront(host)
        }
        let mustHide = appearance.drawerMode == .drawer && self.host != nil
        if self.tabBarHiddenForDrawer != mustHide {
            self.tabBarHiddenForDrawer = mustHide
            self.updateIsTabBarHidden(mustHide, transition: .immediate)
        }
    }

    func updateDrawer(title: String, subtitle: String?, photo: UIImage?, rows: [ExteraDrawerRow]) {
        self.host?.updateContent(title: title, subtitle: subtitle, photo: photo, rows: rows)
    }

    func dismissDrawer() {
        self.host?.setPresented(false)
    }

    override func containerLayoutUpdated(_ layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
        let keyboard = (layout.inputHeight ?? 0) > 0
        var adjusted = layout
        if self.appearance?.drawerMode == .drawer, !keyboard {
            adjusted.intrinsicInsets.bottom = max(adjusted.intrinsicInsets.bottom, layout.safeInsets.bottom + 60)
        }
        super.containerLayoutUpdated(adjusted, transition: transition)
        if let host = self.host {
            host.isHidden = keyboard
            if keyboard { host.setPresented(false, animated: false) }
            host.frame = self.view.bounds
            self.view.bringSubviewToFront(host)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        self.host?.setPresented(false, animated: false)
        super.viewWillDisappear(animated)
    }
}

private final class ExteraRootDrawerHost: UIView, UIGestureRecognizerDelegate {
    private let scrim = UIControl()
    private let blur = UIVisualEffectView()
    private let drawer = ExteraDrawerView(frame: .zero)
    private let launcher = UIButton(type: .system)
    private var edgeGesture: UIScreenEdgePanGestureRecognizer?
    private var appearance: ExteraNavigationAppearance?
    private var theme: PresentationTheme?
    private var strings = ExteraStrings(languageCode: "en")
    private var presented = false
    private var onOpen: (() -> Void)?
    private var onClose: (() -> Void)?
    private var rows: [ExteraDrawerRow] = []
    private var accountTitle = ""
    private var subtitle: String?
    private var photo: UIImage?

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(self.blur)
        self.blur.isUserInteractionEnabled = false
        self.addSubview(self.scrim)
        self.addSubview(self.launcher)
        self.addSubview(self.drawer)
        self.scrim.backgroundColor = UIColor.black.withAlphaComponent(0.28)
        self.scrim.addAction(UIAction { [weak self] _ in self?.setPresented(false) }, for: .touchUpInside)
        self.launcher.setImage(UIImage(systemName: "line.3.horizontal"), for: .normal)
        self.launcher.layer.cornerRadius = 22
        self.launcher.addAction(UIAction { [weak self] _ in self?.setPresented(true) }, for: .touchUpInside)
        let closePan = UIPanGestureRecognizer(target: self, action: #selector(self.pan(_:)))
        closePan.delegate = self
        self.drawer.addGestureRecognizer(closePan)
        self.blur.alpha = 0
        self.scrim.alpha = 0
        self.drawer.isHidden = true
    }

    required init?(coder: NSCoder) { return nil }

    var rtl: Bool { self.effectiveUserInterfaceLayoutDirection == .rightToLeft }

    func attachEdgeGesture(to view: UIView) {
        let edge = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(self.edge(_:)))
        edge.edges = self.rtl ? .right : .left
        edge.cancelsTouchesInView = false
        edge.delegate = self
        view.addGestureRecognizer(edge)
        self.edgeGesture = edge
    }

    func detach() {
        self.setPresented(false, animated: false)
        if let gesture = self.edgeGesture { gesture.view?.removeGestureRecognizer(gesture) }
        self.removeFromSuperview()
    }

    func configure(_ appearance: ExteraNavigationAppearance, theme: PresentationTheme, strings: ExteraStrings, onOpen: @escaping () -> Void, onClose: @escaping () -> Void) {
        self.appearance = appearance
        self.theme = theme
        self.strings = strings
        self.onOpen = onOpen
        self.onClose = onClose
        self.launcher.accessibilityLabel = strings.text("Open navigation menu", "Открыть меню навигации")
        self.launcher.tintColor = theme.list.itemAccentColor
        self.launcher.backgroundColor = theme.list.itemBlocksBackgroundColor
        self.launcher.layer.borderWidth = 1 / UIScreen.main.scale
        self.launcher.layer.borderColor = theme.list.itemAccentColor.withAlphaComponent(0.32).cgColor
        self.blur.effect = UIAccessibility.isReduceTransparencyEnabled || ProcessInfo.processInfo.isLowPowerModeEnabled ? nil : UIBlurEffect(style: theme.overallDarkAppearance ? .systemThinMaterialDark : .systemThinMaterialLight)
        self.renderRows()
        self.setNeedsLayout()
    }

    func updateContent(title: String, subtitle: String?, photo: UIImage?, rows: [ExteraDrawerRow]) {
        self.accountTitle = title
        self.subtitle = subtitle
        self.photo = photo
        self.rows = rows
        self.renderRows()
    }

    private func renderRows() {
        guard let appearance = self.appearance, let theme = self.theme else { return }
        self.drawer.configure(appearance: appearance.interface, geometry: appearance.geometry, sectionRadius: CGFloat(appearance.sectionRadius), fill: theme.list.itemBlocksBackgroundColor,
            foreground: theme.list.itemPrimaryTextColor, accent: theme.list.itemAccentColor, dark: theme.overallDarkAppearance,
            title: self.accountTitle, subtitle: self.subtitle, photo: self.photo,
            closeLabel: self.strings.text("Close menu", "Закрыть меню"), sectionTitle: self.strings.text("Navigation", "Навигация"), items: self.rows, onClose: { [weak self] in self?.setPresented(false) })
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return self.presented ? self.bounds.contains(point) : self.launcher.frame.contains(point)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.blur.frame = self.bounds
        self.scrim.frame = self.bounds
        let safe = self.safeAreaInsets
        let maxWidth = min(450, max(1, self.bounds.width - 30))
        let width = min(maxWidth, floor(self.bounds.width * CGFloat(self.appearance?.interface.drawerWidth ?? 80) / 100))
        let x = self.rtl ? self.bounds.width - width - 5 : 5
        self.drawer.bounds = CGRect(x: 0, y: 0, width: width, height: max(1, self.bounds.height - safe.top - safe.bottom - 12))
        self.drawer.center = CGPoint(x: x + width / 2, y: safe.top + 6 + self.drawer.bounds.height / 2)
        let launcherBottom: CGFloat = self.appearance?.drawerMode == .both ? 82 : 8
        self.launcher.frame = CGRect(x: self.rtl ? self.bounds.width - safe.right - 56 : safe.left + 12,
            y: max(safe.top, self.bounds.height - safe.bottom - launcherBottom - 44), width: 44, height: 44)
        self.edgeGesture?.edges = self.rtl ? .right : .left
    }

    func setPresented(_ value: Bool, animated: Bool = true) {
        guard self.presented != value else { return }
        self.presented = value
        let transition = (self.appearance?.motion ?? ExteraMotion()).forTarget(.menus)
        let motion = animated && transition.allowsMotion
        let shift = self.drawer.bounds.width + 12
        let offscreen = transition.restingOffset(horizontal: self.rtl ? shift : -shift)
        if value {
            self.onOpen?()
            self.layoutIfNeeded()
            self.drawer.isHidden = false
            self.drawer.transform = motion ? offscreen : .identity
            self.drawer.alpha = motion && transition.style == .scale ? 0 : 1
        } else {
            self.onClose?()
        }
        self.accessibilityViewIsModal = value
        let updates = {
            self.drawer.transform = value || !motion ? .identity : offscreen
            self.drawer.alpha = value || transition.style != .scale ? 1 : 0
            self.blur.alpha = value ? 1 : 0
            self.scrim.alpha = value ? 1 : 0
            self.launcher.alpha = value ? 0 : 1
        }
        let completion: (Bool) -> Void = { [weak self] finished in
            guard let self, finished, self.presented == value else { return }
            self.drawer.isHidden = !value
            let target: UIView = value ? self.drawer : self.launcher
            UIAccessibility.post(notification: .screenChanged, argument: target)
        }
        if motion {
            transition.animate(duration: 0.28, updates, completion: completion)
        } else {
            updates()
            completion(true)
        }
    }

    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard !self.isHidden, self.window != nil else { return false }
        if gestureRecognizer === self.edgeGesture { return !self.presented }
        guard self.presented, let gesture = gestureRecognizer as? UIPanGestureRecognizer else { return false }
        let velocity = gesture.velocity(in: self)
        return abs(velocity.x) > abs(velocity.y) && (self.rtl ? velocity.x > 0 : velocity.x < 0)
    }

    @objc private func edge(_ gesture: UIScreenEdgePanGestureRecognizer) {
        if gesture.state == .ended, abs(gesture.translation(in: self).x) > 34 { self.setPresented(true) }
    }

    @objc private func pan(_ gesture: UIPanGestureRecognizer) {
        if gesture.state == .ended, abs(gesture.translation(in: self).x) > 34 { self.setPresented(false) }
    }

    override func accessibilityPerformEscape() -> Bool {
        guard self.presented else { return false }
        self.setPresented(false)
        return true
    }
}
