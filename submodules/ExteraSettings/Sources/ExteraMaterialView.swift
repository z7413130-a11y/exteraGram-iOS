import UIKit

/// The compatible glass surface uses UIKit blur and Core Animation on every supported iOS version.
public final class ExteraMaterialView: UIView {
    private let blur = UIVisualEffectView()
    private let shine = CAGradientLayer()
    private var previous: Palette?

    private struct Palette: Equatable {
        let style: ExteraSurfaceStyle
        let fill: UIColor
        let tint: UIColor
        let dark: Bool
        let opacity: CGFloat
        let radius: CGFloat
        let reduced: Bool
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.isUserInteractionEnabled = false
        self.clipsToBounds = true
        self.layer.cornerCurve = .continuous
        self.addSubview(self.blur)
        self.layer.addSublayer(self.shine)
        self.shine.startPoint = CGPoint(x: 0.15, y: 0)
        self.shine.endPoint = CGPoint(x: 0.85, y: 1)
    }

    required init?(coder: NSCoder) { return nil }

    public override func layoutSubviews() {
        super.layoutSubviews()
        self.blur.frame = self.bounds
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        self.shine.frame = self.bounds
        CATransaction.commit()
    }

    public func update(style: ExteraSurfaceStyle, fill: UIColor, tint: UIColor, dark: Bool, radius: CGFloat, opacity: CGFloat = 1) {
        let reduced = UIAccessibility.isReduceTransparencyEnabled || ProcessInfo.processInfo.isLowPowerModeEnabled
        let opacity = reduced ? 1 : min(1, max(0.65, opacity))
        let palette = Palette(style: style, fill: fill, tint: tint, dark: dark, opacity: opacity, radius: radius, reduced: reduced)
        guard palette != self.previous else { return }
        self.previous = palette
        self.layer.cornerRadius = radius
        self.layer.borderWidth = style == .telegram ? 0 : 1 / UIScreen.main.scale
        self.layer.borderColor = tint.withAlphaComponent(style == .classic ? 0.22 : 0.36).cgColor
        let glass = style == .liquidGlass && !reduced
        self.blur.effect = glass ? UIBlurEffect(style: dark ? .systemMaterialDark : .systemMaterialLight) : nil
        self.blur.isHidden = !glass
        self.backgroundColor = fill.withAlphaComponent(glass ? opacity * 0.40 : opacity)
        self.shine.colors = glass ? [UIColor.white.withAlphaComponent(dark ? 0.16 : 0.27).cgColor,
                                     tint.withAlphaComponent(0.05).cgColor, UIColor.clear.cgColor] : nil
    }
}
