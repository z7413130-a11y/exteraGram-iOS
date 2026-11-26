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
        return CGFloat(1 + (min(20, max(4, value)) - 12) / 24)
    }
}

/// The chat uses this value to refresh existing rows only after a visual setting changes.
public struct ExteraChatVisualSettings: Equatable {
    private let hideShare: Bool
    private let hideTail: Bool
    private let editedIcon: Bool
    private let stickerSize: Double
    private let hidePremium: Bool
    private let freezeEmoji: Bool
    private let hideVideoRecording: Bool
    private let hidePrivateReactions: Bool
    private let hideChannelReactions: Bool
    private let hideGroupReactions: Bool

    public init(store: ExteraSettingsStore = .shared) {
        self.hideShare = store.value(for: ExteraPreferences.hideShareButton)
        self.hideTail = store.value(for: ExteraPreferences.removeMessageTail)
        self.editedIcon = store.value(for: ExteraPreferences.replaceEditedWithIcon)
        self.stickerSize = store.value(for: ExteraPreferences.stickerSize)
        self.hidePremium = store.value(for: ExteraPreferences.hidePremiumBadges)
        self.freezeEmoji = store.value(for: ExteraPreferences.hideAnimatedEmoji)
        self.hideVideoRecording = store.value(for: ExteraPreferences.hideVideoRecording)
        self.hidePrivateReactions = store.value(for: ExteraPreferences.hideReactionsInPrivateChats)
        self.hideChannelReactions = store.value(for: ExteraPreferences.hideReactionsInChannels)
        self.hideGroupReactions = store.value(for: ExteraPreferences.hideReactionsInGroups)
    }
}
