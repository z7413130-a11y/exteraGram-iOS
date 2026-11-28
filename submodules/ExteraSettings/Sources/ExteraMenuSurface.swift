import UIKit

public final class ExteraMenuSurface: UIView {
    private let effect = UIVisualEffectView()
    private let fillView = UIView()
    private let gleam = CAGradientLayer()
    private var cachedEffectStyle: UIBlurEffect.Style?

    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.clipsToBounds = true
        self.isUserInteractionEnabled = false
        self.layer.cornerCurve = .continuous
        self.addSubview(self.effect)
        self.addSubview(self.fillView)
        self.layer.addSublayer(self.gleam)
        self.gleam.startPoint = CGPoint(x: 0.08, y: 0)
        self.gleam.endPoint = CGPoint(x: 0.9, y: 1)
    }

    required init?(coder: NSCoder) { return nil }

    public override func layoutSubviews() {
        super.layoutSubviews()
        self.effect.frame = self.bounds
        self.fillView.frame = self.bounds
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        self.gleam.frame = self.bounds
        CATransaction.commit()
    }

    public func configure(_ appearance: ExteraMenuAppearance, outline: ExteraMenuOutline, base: UIColor, accent: UIColor, dark: Bool) {
        let style = appearance.resolved(for: .telegram)
        let reduced = UIAccessibility.isReduceTransparencyEnabled || ProcessInfo.processInfo.isLowPowerModeEnabled
        let custom = style.material != .telegram
        self.layer.cornerRadius = CGFloat(style.radius)
        var blurStyle: UIBlurEffect.Style?
        if custom && !reduced && style.blur > 0 {
            switch style.material {
            case .telegram, .automatic: break
            case .frosted:
                blurStyle = style.blur >= 64 ? (dark ? .systemMaterialDark : .systemMaterialLight) : (dark ? .systemThinMaterialDark : .systemThinMaterialLight)
            case .transparent:
                blurStyle = dark ? .systemUltraThinMaterialDark : .systemUltraThinMaterialLight
            case .liquidGlass:
                blurStyle = dark ? .systemThinMaterialDark : .systemThinMaterialLight
            }
        }
        if self.cachedEffectStyle != blurStyle {
            self.cachedEffectStyle = blurStyle
            self.effect.effect = blurStyle.map { UIBlurEffect(style: $0) }
        }
        self.effect.alpha = CGFloat(style.blur) / 100
        self.effect.isHidden = blurStyle == nil
        let tintWeight: CGFloat = CGFloat(style.saturation) / 100 * (dark ? 0.14 : 0.10)
        let opacity = reduced || !custom ? 1 : CGFloat(style.opacity) / 100 * (style.material == .transparent ? 0.72 : 1)
        self.fillView.backgroundColor = Self.mix(base, accent, tintWeight: custom ? tintWeight : 0).withAlphaComponent(opacity)
        let hasGleam = custom && !reduced && (style.material == .liquidGlass || outline == .gleam)
        self.gleam.colors = hasGleam ? [UIColor.white.withAlphaComponent(CGFloat(style.gleam) * 0.004).cgColor, UIColor.clear.cgColor] : nil
        self.layer.borderWidth = outline == .hidden ? 0 : (outline == .solid ? 1.5 : 1) / UIScreen.main.scale
        self.layer.borderColor = (outline == .gleam ? UIColor.white : accent).withAlphaComponent(dark ? 0.34 : 0.23).cgColor
    }

    private static func mix(_ base: UIColor, _ accent: UIColor, tintWeight: CGFloat) -> UIColor {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        var tr: CGFloat = 0, tg: CGFloat = 0, tb: CGFloat = 0, ta: CGFloat = 0
        guard base.getRed(&r, green: &g, blue: &b, alpha: &a), accent.getRed(&tr, green: &tg, blue: &tb, alpha: &ta) else { return base }
        return UIColor(red: r * (1 - tintWeight) + tr * tintWeight, green: g * (1 - tintWeight) + tg * tintWeight,
            blue: b * (1 - tintWeight) + tb * tintWeight, alpha: a)
    }
}
