import Darwin
import UIKit

/// Displays device-local values. The owner can suspend sampling while its chat list is covered.
public final class ExteraPillStrip: UIView, UIScrollViewDelegate {
    private let scroll = UIScrollView()
    private let track = UIStackView()
    private var stacks: [UIStackView] = []
    private var buttons: [ExteraPill: [UIButton]] = [:]
    private var configuration = ExteraPillConfiguration()
    private var language = "en"
    private var foreground = UIColor.label
    private var accent = UIColor.systemBlue
    private var surface = UIColor.secondarySystemBackground
    private var dark = false
    private var proxyEnabled: Bool?
    private var active = false
    private var selecting: ((ExteraPill) -> Void)?
    private var timer: Timer?
    private var needsLoopPosition = false

    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.scroll.showsHorizontalScrollIndicator = false
        self.scroll.delegate = self
        self.track.spacing = 8
        self.track.alignment = .center
        self.scroll.addSubview(self.track)
        self.track.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.track.leadingAnchor.constraint(equalTo: self.scroll.contentLayoutGuide.leadingAnchor, constant: 12),
            self.track.trailingAnchor.constraint(equalTo: self.scroll.contentLayoutGuide.trailingAnchor, constant: -12),
            self.track.topAnchor.constraint(equalTo: self.scroll.contentLayoutGuide.topAnchor),
            self.track.bottomAnchor.constraint(equalTo: self.scroll.contentLayoutGuide.bottomAnchor),
            self.track.heightAnchor.constraint(equalTo: self.scroll.frameLayoutGuide.heightAnchor),
        ])
        self.addSubview(self.scroll)
    }

    required init?(coder: NSCoder) { return nil }

    deinit { self.timer?.invalidate() }

    public func update(configuration: ExteraPillConfiguration, language: String, foreground: UIColor, accent: UIColor, surface: UIColor, dark: Bool, proxyEnabled: Bool?, active: Bool, selecting: @escaping (ExteraPill) -> Void) {
        let configuration = configuration.normalized
        let appearanceChanged = self.configuration != configuration || self.language != language || self.foreground != foreground
            || self.accent != accent || self.surface != surface || self.dark != dark
        let proxyChanged = self.proxyEnabled != proxyEnabled
        let timerChanged = self.configuration.widgets != configuration.widgets || self.configuration.refreshInterval != configuration.refreshInterval || self.active != active
        self.configuration = configuration
        self.language = language
        self.foreground = foreground
        self.accent = accent
        self.surface = surface
        self.dark = dark
        self.proxyEnabled = proxyEnabled
        self.active = active
        self.selecting = selecting
        if appearanceChanged {
            self.rebuild()
        }
        if proxyChanged || appearanceChanged {
            self.refresh(widget: .proxy)
        }
        if timerChanged {
            self.updateTimer()
        }
    }

    public override func didMoveToWindow() {
        super.didMoveToWindow()
        self.updateTimer()
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        self.scroll.frame = self.bounds
        if self.needsLoopPosition {
            self.needsLoopPosition = false
            if self.stacks.count == 3 {
                self.scroll.layoutIfNeeded()
                self.scroll.contentOffset.x = self.stacks[1].frame.minX
            } else {
                self.scroll.contentOffset.x = 0
            }
        }
    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard self.stacks.count == 3, !self.needsLoopPosition else { return }
        let middle = self.stacks[1].frame.minX
        let period = self.stacks[2].frame.minX - middle
        guard period > 0, self.scroll.contentSize.width > self.scroll.bounds.width + period else { return }
        if scrollView.contentOffset.x < middle - period * 0.5 {
            scrollView.contentOffset.x += period
        } else if scrollView.contentOffset.x > middle + period * 0.5 {
            scrollView.contentOffset.x -= period
        }
    }

    private func rebuild() {
        for stack in self.stacks {
            self.track.removeArrangedSubview(stack)
            stack.removeFromSuperview()
        }
        self.stacks.removeAll()
        self.buttons.removeAll()
        let repeated = self.configuration.loops && self.configuration.widgets.count > 1
        for index in 0..<(repeated ? 3 : 1) {
            let stack = UIStackView()
            stack.spacing = 8
            stack.accessibilityElementsHidden = repeated && index != 1
            for widget in self.configuration.widgets {
                let button = UIButton(type: .system)
                button.tintColor = self.accent
                button.layer.cornerCurve = .continuous
                button.layer.cornerRadius = CGFloat(min(self.configuration.cornerRadius, self.configuration.capsuleHeight / 2))
                button.clipsToBounds = true
                switch self.configuration.material {
                case .telegram:
                    button.backgroundColor = self.surface.withAlphaComponent(CGFloat(self.configuration.opacity) / 100)
                case .classic:
                    button.backgroundColor = self.accent.withAlphaComponent(CGFloat(self.configuration.opacity) / 500)
                    button.layer.borderWidth = 1 / UIScreen.main.scale
                    button.layer.borderColor = self.accent.withAlphaComponent(0.4).cgColor
                case .glass:
                    button.backgroundColor = self.surface.withAlphaComponent(CGFloat(self.configuration.opacity) / 150)
                    if !UIAccessibility.isReduceTransparencyEnabled, !ProcessInfo.processInfo.isLowPowerModeEnabled {
                        let blur = UIVisualEffectView(effect: UIBlurEffect(style: self.dark ? .systemThinMaterialDark : .systemThinMaterialLight))
                        blur.alpha = CGFloat(self.configuration.opacity) / 100
                        blur.isUserInteractionEnabled = false
                        blur.translatesAutoresizingMaskIntoConstraints = false
                        button.insertSubview(blur, at: 0)
                        NSLayoutConstraint.activate([
                            blur.leadingAnchor.constraint(equalTo: button.leadingAnchor),
                            blur.trailingAnchor.constraint(equalTo: button.trailingAnchor),
                            blur.topAnchor.constraint(equalTo: button.topAnchor),
                            blur.bottomAnchor.constraint(equalTo: button.bottomAnchor),
                        ])
                    }
                    button.layer.borderWidth = 1 / UIScreen.main.scale
                    button.layer.borderColor = self.foreground.withAlphaComponent(0.18).cgColor
                }
                button.heightAnchor.constraint(equalToConstant: CGFloat(self.configuration.capsuleHeight)).isActive = true
                button.addAction(UIAction { [weak self] _ in self?.selecting?(widget) }, for: .touchUpInside)
                self.buttons[widget, default: []].append(button)
                stack.addArrangedSubview(button)
            }
            self.track.addArrangedSubview(stack)
            self.stacks.append(stack)
        }
        self.refresh(widget: .memory)
        self.needsLoopPosition = true
        self.setNeedsLayout()
    }

    private func updateTimer() {
        self.timer?.invalidate()
        self.timer = nil
        guard self.window != nil, self.active, self.buttons[.memory] != nil else { return }
        self.refresh(widget: .memory)
        let timer = Timer(timeInterval: TimeInterval(self.configuration.refreshInterval), repeats: true) { [weak self] _ in
            guard let self, self.window?.windowScene?.activationState == .foregroundActive else { return }
            self.refresh(widget: .memory)
        }
        timer.tolerance = TimeInterval(self.configuration.refreshInterval) * 0.2
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    private func refresh(widget: ExteraPill) {
        guard let buttons = self.buttons[widget] else { return }
        let strings = ExteraStrings(languageCode: self.language)
        let value: String
        switch widget {
        case .memory:
            value = self.window != nil && self.active ? Self.memoryValue(strings) : "—"
        case .proxy:
            value = self.proxyEnabled.map { $0 ? strings.text("On", "Вкл.") : strings.text("Off", "Выкл.") } ?? "—"
        }
        for button in buttons {
            var configuration = UIButton.Configuration.plain()
            configuration.image = UIImage(systemName: widget.symbol)
            configuration.imagePadding = 5
            configuration.title = "\(widget.title(strings)) · \(value)"
            configuration.baseForegroundColor = self.foreground
            configuration.contentInsets = NSDirectionalEdgeInsets(top: 2, leading: 10, bottom: 2, trailing: 10)
            configuration.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 12, weight: .semibold)
            configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
                var attributes = attributes
                attributes.font = UIFont.preferredFont(forTextStyle: .caption1)
                return attributes
            }
            button.configuration = configuration
        }
    }

    private static func memoryValue(_ strings: ExteraStrings) -> String {
        var info = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<integer_t>.size)
        let result = withUnsafeMutablePointer(to: &info) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
            }
        }
        guard result == KERN_SUCCESS, info.phys_footprint > 0 else { return "—" }
        return "\(info.phys_footprint / 1_048_576) \(strings.text("MiB", "МиБ"))"
    }
}
