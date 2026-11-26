import AccountContext
import ChatControllerInteraction
import ChatMessageItemCommon
import Display
import ExteraSettings
import Foundation
import PresentationDataUtils
import SwiftSignalKit
import TelegramCore
import TextSelectionNode
import UIKit

extension ChatControllerImpl {
    func installExteraMessageGestures(on interaction: ChatControllerInteraction) {
        let store = ExteraSettingsStore.shared
        interaction.exteraDoubleTap = { [weak self, weak interaction] message in
            guard let self, let interaction else { return false }
            let outgoing = !message.effectivelyIncoming(self.context.account.peerId)
            let setting = store.value(for: outgoing ? ExteraPreferences.doubleTapActionOutOwner : ExteraPreferences.doubleTapAction)
            let action = ExteraMessageGestureAction.doubleTap(setting: setting, outgoing: outgoing)
            // Keep the native double-tap behavior for Telegram's default reaction.
            guard action != .reaction else { return false }
            self.performExteraGesture(action, message: message, interaction: interaction)
            return true
        }
        interaction.exteraSwipe = { [weak self, weak interaction] message in
            guard let self, let interaction else { return .none }
            let configured = ExteraMessageGestureAction.swipeActions(store.value(for: ExteraPreferences.swipeActions))
            if let action = configured.first(where: { self.canPerformExteraGesture($0, message: message, interaction: interaction) }) {
                return action == .reply ? .reply : .extera(action.rawValue, symbol: action.symbol)
            }
            return .none
        }
        interaction.performExteraGesture = { [weak self, weak interaction] id, message in
            guard let self, let interaction, let action = ExteraMessageGestureAction(rawValue: id) else { return }
            self.performExteraGesture(action, message: message, interaction: interaction)
        }
    }

    private func canPerformExteraGesture(_ action: ExteraMessageGestureAction, message: EngineRawMessage, interaction: ChatControllerInteraction) -> Bool {
        if action == .reply {
            return interaction.canSetupReply(message) == .reply
        }
        guard action != .disabled, message.id.namespace == Namespaces.Message.Cloud, message.adAttribute == nil,
              !message.containsSecretMedia, !message.flags.isSending, !message.flags.contains(.Failed),
              !message.media.contains(where: { $0 is TelegramMediaAction || $0 is TelegramMediaExpiredContent }),
              !message.attributes.contains(where: { $0 is EphemeralMessageAttribute }) else {
            return false
        }
        if action == .reaction { return canAddMessageReactions(message: EngineMessage(message)) }
        if action == .edit {
            return !message.effectivelyIncoming(self.context.account.peerId) &&
                !message.media.contains(where: { $0 is TelegramMediaTodo }) &&
                canEditMessage(context: self.context, limitsConfiguration: self.context.currentLimitsConfiguration.with { EngineConfiguration.Limits($0) }, message: message)
        }
        if action == .delete { return true }
        guard !self.presentationInterfaceState.copyProtectionEnabled, !message.isCopyProtected(),
              !message.isRestricted(platform: "ios", contentSettings: self.context.currentContentSettings.with { $0 }) else {
            return false
        }
        switch action {
        case .copy, .translate: return !message.text.isEmpty
        case .repeatText:
            return interaction.canSendMessages() && !message.text.isEmpty && message.media.isEmpty &&
                !message.attributes.contains(where: { $0 is TextEntitiesMessageAttribute || $0 is RichTextMessageAttribute })
        default: return true
        }
    }

    private func performExteraGesture(_ action: ExteraMessageGestureAction, message: EngineRawMessage, interaction: ChatControllerInteraction) {
        guard self.canPerformExteraGesture(action, message: message, interaction: interaction) else { return }
        switch action {
        case .disabled: break
        case .reaction:
            interaction.updateMessageReaction(message, .default, false, nil)
        case .reply:
            interaction.setupReply(message.id)
        case .copy:
            UIPasteboard.general.string = message.text
        case .translate:
            let entities = (message.attributes.first(where: { $0 is TextEntitiesMessageAttribute }) as? TextEntitiesMessageAttribute)?.entities
            interaction.performTextSelectionAction(message, true, NSAttributedString(string: message.text), entities, .translate)
        case .edit:
            self.interfaceInteraction?.setupEditMessage(message.id, { _ in })
        case .delete:
            self.interfaceInteraction?.deleteMessages([message], nil, { _ in })
        case .forward, .save:
            let _ = (self.context.sharedContext.chatAvailableMessageActions(engine: self.context.engine,
                accountPeerId: self.context.account.peerId, messageIds: [message.id], keepUpdated: false)
            |> take(1)
            |> deliverOnMainQueue).startStandalone(next: { [weak self] result in
                guard let self, self.viewIfLoaded?.window != nil, result.options.contains(.forward), !result.isCopyProtected else { return }
                if action == .forward {
                    self.interfaceInteraction?.forwardMessages([message])
                } else {
                    let forward = EnqueueMessage.forward(source: message.id, threadId: nil, grouping: .auto, attributes: [], correlationId: nil)
                    let _ = enqueueMessages(account: self.context.account, peerId: self.context.account.peerId, messages: [forward]).startStandalone()
                }
            })
        case .repeatText:
            self.presentExteraSendConfirmation(english: "Resend this text?", russian: "Отправить этот текст повторно?") { [weak interaction] in
                interaction?.sendMessage(message.text, nil)
            }
        }
    }
}
