import UIKit

public struct ExteraDrawerRow {
    public let title: String
    public let subtitle: String?
    public let symbol: String
    public let image: UIImage?
    public let selected: Bool
    public let action: () -> Void

    public init(title: String, subtitle: String? = nil, symbol: String, image: UIImage? = nil, selected: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.subtitle = subtitle
        self.symbol = symbol
        self.image = image
        self.selected = selected
        self.action = action
    }
}

/// Shared by the root drawer and its interactive settings preview.
public final class ExteraDrawerView: UIView {
    private let material = ExteraMaterialView(frame: .zero)
    private let scroll = UIScrollView()
    private let list = UIStackView()
    private let top = UIStackView()
    private let avatar = UIImageView()
    private let title = UILabel()
    private let subtitle = UILabel()
    private let close = UIButton(type: .system)
    private let rows = UIStackView()
    private let sectionHeader = UILabel()
    private var horizontalConstraints: [NSLayoutConstraint] = []
    private var closeAction: (() -> Void)?

    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(self.material)
        self.addSubview(self.scroll)
        self.scroll.addSubview(self.list)
        self.scroll.alwaysBounceVertical = false
        self.list.translatesAutoresizingMaskIntoConstraints = false
        self.list.axis = .vertical
        self.list.spacing = 10
        self.horizontalConstraints = [
            self.list.leadingAnchor.constraint(equalTo: self.scroll.frameLayoutGuide.leadingAnchor, constant: 12),
            self.list.trailingAnchor.constraint(equalTo: self.scroll.frameLayoutGuide.trailingAnchor, constant: -12),
        ]
        NSLayoutConstraint.activate(self.horizontalConstraints + [
            self.list.topAnchor.constraint(equalTo: self.scroll.contentLayoutGuide.topAnchor, constant: 12),
            self.list.bottomAnchor.constraint(equalTo: self.scroll.contentLayoutGuide.bottomAnchor, constant: -12),
        ])
        self.top.alignment = .center
        self.top.spacing = 8
        self.avatar.widthAnchor.constraint(equalToConstant: 42).isActive = true
        self.avatar.heightAnchor.constraint(equalToConstant: 42).isActive = true
        self.avatar.layer.cornerRadius = 21
        self.avatar.clipsToBounds = true
        self.avatar.contentMode = .scaleAspectFill
        self.title.numberOfLines = 0
        self.title.font = .preferredFont(forTextStyle: .headline)
        self.subtitle.numberOfLines = 0
        self.subtitle.font = .preferredFont(forTextStyle: .caption1)
        let identity = UIStackView(arrangedSubviews: [self.title, self.subtitle])
        identity.axis = .vertical
        self.close.widthAnchor.constraint(equalToConstant: 44).isActive = true
        self.close.heightAnchor.constraint(equalToConstant: 44).isActive = true
        self.close.setImage(UIImage(systemName: "xmark"), for: .normal)
        self.close.addAction(UIAction { [weak self] _ in self?.closeAction?() }, for: .touchUpInside)
        [self.avatar, identity, self.close].forEach(self.top.addArrangedSubview)
        self.list.addArrangedSubview(self.top)
        self.sectionHeader.font = .preferredFont(forTextStyle: .caption1)
        self.sectionHeader.accessibilityTraits.insert(.header)
        self.sectionHeader.numberOfLines = 0
        self.list.addArrangedSubview(self.sectionHeader)
        self.rows.axis = .vertical
        self.rows.spacing = 4
        self.list.addArrangedSubview(self.rows)
    }

    required init?(coder: NSCoder) { return nil }

    public override func layoutSubviews() {
        super.layoutSubviews()
        self.material.frame = self.bounds
        self.scroll.frame = self.bounds
    }

    public func configure(
        appearance: ExteraInterfaceAppearance, geometry: ExteraGeometry, sectionRadius: CGFloat, fill: UIColor, foreground: UIColor, accent: UIColor, dark: Bool,
        title: String, subtitle: String?, photo: UIImage?, closeLabel: String, sectionTitle: String, items: [ExteraDrawerRow],
        onClose: (() -> Void)?
    ) {
        self.material.update(style: appearance.surfaceStyle, fill: fill, tint: accent,
            dark: dark, radius: sectionRadius, opacity: CGFloat(appearance.drawerOpacity) / 100)
        let geometry = geometry.normalized
        self.horizontalConstraints[0].constant = CGFloat(geometry.insets)
        self.horizontalConstraints[1].constant = -CGFloat(geometry.insets)
        self.list.spacing = CGFloat(geometry.spacing)
        self.rows.spacing = geometry.dividers == .hidden ? 0 : 4
        self.sectionHeader.text = sectionTitle
        self.sectionHeader.textColor = foreground.withAlphaComponent(0.75)
        self.sectionHeader.isHidden = !geometry.sectionHeaders
        self.title.text = title
        self.title.textColor = foreground
        self.subtitle.text = subtitle
        self.subtitle.isHidden = subtitle?.isEmpty != false
        self.subtitle.textColor = foreground.withAlphaComponent(0.75)
        self.avatar.image = photo ?? UIImage(systemName: "person.crop.circle.fill")?.withTintColor(accent, renderingMode: .alwaysOriginal)
        self.close.tintColor = accent
        self.close.isHidden = onClose == nil
        self.close.accessibilityLabel = closeLabel
        self.closeAction = onClose

        for view in self.rows.arrangedSubviews {
            self.rows.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        for (index, row) in items.enumerated() {
            let button = UIButton(type: .system)
            var configuration = UIButton.Configuration.plain()
            configuration.image = row.image ?? UIImage(systemName: row.symbol)
            configuration.title = row.title
            configuration.subtitle = row.subtitle
            configuration.titleLineBreakMode = .byWordWrapping
            configuration.subtitleLineBreakMode = .byWordWrapping
            configuration.imagePadding = 10
            configuration.titleAlignment = .leading
            configuration.contentInsets = NSDirectionalEdgeInsets(top: 7, leading: 10, bottom: 7, trailing: 8)
            configuration.baseForegroundColor = row.selected ? accent : foreground
            if row.selected || geometry.dividers == .segments {
                configuration.background.backgroundColor = accent.withAlphaComponent(row.selected ? 0.18 : 0.08)
                configuration.background.cornerRadius = CGFloat(geometry.buttonRadius)
                if row.selected { button.accessibilityTraits.insert(.selected) }
            }
            button.configuration = configuration
            button.contentHorizontalAlignment = .leading
            button.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
            button.addAction(UIAction { _ in row.action() }, for: .touchUpInside)
            self.rows.addArrangedSubview(button)
            if geometry.dividers == .line && index < items.count - 1 {
                let line = UIView()
                line.backgroundColor = foreground.withAlphaComponent(0.14)
                line.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale).isActive = true
                self.rows.addArrangedSubview(line)
            }
        }
    }
}
