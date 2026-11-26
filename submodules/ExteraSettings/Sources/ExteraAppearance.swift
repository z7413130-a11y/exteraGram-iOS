import CoreGraphics

public enum ExteraAppearance {
    public static var hidesUnreadCounters: Bool {
        ExteraSettingsStore.shared.value(for: ExteraPreferences.tabCounterMode) == 2
    }

    public static var hidesDividers: Bool {
        ExteraSettingsStore.shared.value(for: ExteraPreferences.dividerStyle) == 0
    }

    public static var avatarCornerFraction: CGFloat {
        let value = ExteraSettingsStore.shared.value(for: ExteraPreferences.avatarCorners)
        return CGFloat(min(28, max(0, value)) / 56)
    }

    public static var stickerScale: CGFloat {
        let value = ExteraSettingsStore.shared.value(for: ExteraPreferences.stickerSize)
        return CGFloat(1 + (min(18, max(6, value)) - 12) / 24)
    }
}
