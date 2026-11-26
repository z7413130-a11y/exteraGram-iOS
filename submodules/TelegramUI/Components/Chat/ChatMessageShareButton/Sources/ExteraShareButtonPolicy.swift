import AccountContext
import ExteraSettings
import TelegramCore

/// The side button also opens replies or navigates to a source message.
/// Hide only its ordinary Share role.
public func exteraAllowsShareButton(
    message: EngineMessage,
    chatLocation: ChatLocation,
    subject: ChatControllerSubject?,
    accountPeerId: EnginePeer.Id,
    showsComments: Bool = true
) -> Bool {
    guard ExteraSettingsStore.shared.value(for: ExteraPreferences.hideShareButton) else { return true }
    if message.adAttribute != nil || message.id.peerId.isRepliesOrSavedMessages(accountPeerId: accountPeerId) {
        return true
    }
    if case .pinnedMessages = subject {
        return true
    }
    if case let .customChatContents(contents) = subject, case .hashTagSearch = contents.kind {
        return true
    }
    if let channel = message.peers[message.id.peerId] as? TelegramChannel {
        if channel.isMonoForum, case .peer = chatLocation {
            return true
        }
        if showsComments, case .broadcast = channel.info,
           message.attributes.contains(where: { $0 is ReplyThreadMessageAttribute }) {
            return true
        }
    }
    return false
}
