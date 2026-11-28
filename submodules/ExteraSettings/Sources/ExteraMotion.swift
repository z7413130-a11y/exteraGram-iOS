import UIKit

public enum ExteraMotionStyle: Int, CaseIterable, Codable {
    case telegram = 0
    case smooth = 1
    case spring = 2
    case system = 3
    case scale = 4
    case minimal = 5

    public func title(_ strings: ExteraStrings) -> String {
        switch self {
        case .telegram: return "Telegram"
        case .smooth: return strings.text("Smooth", "Плавная")
        case .spring: return strings.text("Spring", "Пружинная")
        case .system: return strings.text("Native iOS", "Системная iOS")
        case .scale: return strings.text("Scale", "Масштабирование")
        case .minimal: return strings.text("Minimal", "Минимальная")
        }
    }
}

public enum ExteraMotionTarget: Int, CaseIterable, Codable {
    case chatOpen, back, tabs, menus, settings

    public func title(_ strings: ExteraStrings) -> String {
        switch self {
        case .chatOpen: return strings.text("Opening chats", "Открытие чатов")
        case .back: return strings.text("Going back", "Возврат назад")
        case .tabs: return strings.text("Switching tabs", "Переключение вкладок")
        case .menus: return strings.text("Opening the side menu", "Открытие бокового меню")
        case .settings: return strings.text("Opening exteraGram settings", "Открытие настроек exteraGram")
        }
    }
}

public struct ExteraMotion: Equatable {
    public let style: ExteraMotionStyle
    public let speed: Int
    public let springStrength: Int
    public let targets: Set<ExteraMotionTarget>

    public init(style: ExteraMotionStyle, speed: Int, springStrength: Int, targets: Set<ExteraMotionTarget> = Set(ExteraMotionTarget.allCases)) {
        self.style = style
        self.speed = min(160, max(60, speed))
        self.springStrength = min(100, max(0, springStrength))
        self.targets = targets
    }

    public init(store: ExteraSettingsStore = .shared) {
        self.init(style: ExteraMotionStyle(rawValue: store.value(for: ExteraPreferences.transitionAnimation)) ?? .telegram,
            speed: store.value(for: ExteraPreferences.motionSpeed), springStrength: store.value(for: ExteraPreferences.motionSpring),
            targets: store.value(for: ExteraPreferences.motionTargets))
    }

    public func forTarget(_ target: ExteraMotionTarget) -> Self {
        return self.targets.contains(target) ? self : Self(style: .telegram, speed: 100, springStrength: 50, targets: self.targets)
    }

    /// Parameters for Telegram's existing navigation clock. Slides retain their navigation and gesture semantics.
    public func slideTiming(for target: ExteraMotionTarget, interactive: Bool) -> (duration: CGFloat, bounce: CGFloat)? {
        guard self.targets.contains(target), !UIAccessibility.isReduceMotionEnabled else { return nil }
        if self.style == .telegram && self.speed == 100 { return nil }
        switch self.style {
        case .telegram, .system: return (CGFloat(self.duration(0.30)), interactive ? 0.15 : 0)
        case .smooth: return (CGFloat(self.duration(0.36)), 0)
        case .spring: return (CGFloat(self.duration(0.35)), CGFloat(self.springStrength) / 260)
        case .scale: return (CGFloat(self.duration(0.23)), 0)
        case .minimal: return (0.11, 0)
        }
    }

    public var allowsMotion: Bool { self.style != .minimal && !UIAccessibility.isReduceMotionEnabled }
    public func duration(_ base: Double) -> Double { base * 100 / Double(self.speed) }

    public func restingOffset(horizontal: CGFloat) -> CGAffineTransform {
        guard self.allowsMotion else { return .identity }
        if self.style == .scale { return CGAffineTransform(scaleX: 0.90, y: 0.90) }
        return CGAffineTransform(translationX: horizontal, y: 0)
    }

    public func animate(duration base: Double, _ updates: @escaping () -> Void, completion: ((Bool) -> Void)? = nil) {
        guard self.allowsMotion else {
            updates()
            completion?(true)
            return
        }
        let duration = self.duration(base)
        if self.style == .spring {
            UIView.animate(withDuration: duration * 1.6, delay: 0, usingSpringWithDamping: 0.95 - CGFloat(self.springStrength) * 0.005,
                initialSpringVelocity: 0, options: [.beginFromCurrentState, .allowUserInteraction], animations: updates, completion: completion)
        } else {
            let curve: UIView.AnimationOptions = self.style == .smooth ? .curveEaseInOut : .curveEaseOut
            UIView.animate(withDuration: duration, delay: 0, options: [.beginFromCurrentState, .allowUserInteraction, curve],
                animations: updates, completion: completion)
        }
    }
}
