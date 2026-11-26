import ExteraSettings
import TelegramCore

public func exteraHidesReactions(_ message: EngineRawMessage, accountPeerId: EnginePeer.Id) -> Bool {
    guard !message.areReactionsTags(accountPeerId: accountPeerId) else { return false }
    let store = ExteraSettingsStore.shared
    let peerId = message.id.peerId
    switch peerId.namespace {
    case Namespaces.Peer.CloudUser, Namespaces.Peer.SecretChat:
        return store.value(for: ExteraPreferences.hideReactionsInPrivateChats)
    case Namespaces.Peer.CloudGroup:
        return store.value(for: ExteraPreferences.hideReactionsInGroups)
    case Namespaces.Peer.CloudChannel:
        guard let channel = message.peers[peerId] as? TelegramChannel else { return false }
        if case .broadcast = channel.info {
            return store.value(for: ExteraPreferences.hideReactionsInChannels)
        }
        return store.value(for: ExteraPreferences.hideReactionsInGroups)
    default:
        return false
    }
}

public func exteraVisibleReactions(accountPeerId: EnginePeer.Id, accountPeer: EnginePeer?, message: EngineRawMessage) -> (reactions: [MessageReaction], peers: [(MessageReaction.Reaction, EnginePeer)]) {
    if exteraHidesReactions(message, accountPeerId: accountPeerId) {
        return ([], [])
    }
    return mergedMessageReactionsAndPeers(accountPeerId: accountPeerId, accountPeer: accountPeer, message: message)
}
