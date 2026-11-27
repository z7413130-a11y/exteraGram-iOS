import UIKit

public final class ExteraSnowView: UIView {
    public override class var layerClass: AnyClass { CAEmitterLayer.self }

    private var emitter: CAEmitterLayer { self.layer as! CAEmitterLayer }
    private var active = false

    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.isUserInteractionEnabled = false
        self.accessibilityElementsHidden = true
        self.clipsToBounds = true

        let size = CGSize(width: 4, height: 4)
        let image = UIGraphicsImageRenderer(size: size).image { _ in
            UIColor.white.setFill()
            UIBezierPath(ovalIn: CGRect(origin: .zero, size: size)).fill()
        }
        let cell = CAEmitterCell()
        cell.contents = image.cgImage
        cell.birthRate = 6
        cell.lifetime = 3.8
        cell.velocity = 20
        cell.velocityRange = 10
        cell.emissionLongitude = .pi / 2
        cell.emissionRange = 0.4
        cell.scale = 0.52
        cell.scaleRange = 0.25
        cell.alphaSpeed = -0.07
        cell.color = UIColor.white.withAlphaComponent(0.3).cgColor
        self.emitter.emitterShape = .line
        self.emitter.emitterCells = [cell]
        self.emitter.birthRate = 0
    }

    required init?(coder: NSCoder) { return nil }

    public func update(active: Bool, color: UIColor) {
        self.active = active
        if self.tintColor != color, let cell = self.emitter.emitterCells?.first {
            self.tintColor = color
            cell.color = color.withAlphaComponent(0.3).cgColor
            self.emitter.emitterCells = [cell]
        }
        self.updateEmitter()
    }

    public override func didMoveToWindow() {
        super.didMoveToWindow()
        self.updateEmitter()
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        self.emitter.emitterPosition = CGPoint(x: self.bounds.midX, y: -5)
        self.emitter.emitterSize = CGSize(width: self.bounds.width, height: 1)
    }

    private func updateEmitter() {
        let enabled = self.active && self.window != nil && !UIAccessibility.isReduceMotionEnabled
            && !ProcessInfo.processInfo.isLowPowerModeEnabled
        let birthRate: Float = enabled ? 1 : 0
        if self.emitter.birthRate != birthRate {
            self.emitter.birthRate = birthRate
        }
        self.isHidden = !enabled
    }
}
