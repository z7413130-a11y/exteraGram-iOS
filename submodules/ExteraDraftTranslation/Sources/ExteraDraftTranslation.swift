import AccountContext
import Display
import ExteraSettings
import Foundation
import PresentationDataUtils
import SwiftSignalKit
import TelegramCore
import TextFormat
import TranslateUI

/// Translates an unsent draft through Telegram after a separate confirmation.
/// Secret chats never use this server translation path.
public func requestExteraDraftTranslation(
    context: AccountContext,
    peerId: EnginePeer.Id,
    draft: NSAttributedString,
    isCurrentDraft: @escaping () -> Bool,
    present: @escaping (ViewController) -> Void,
    replace: @escaping (NSAttributedString) -> Void
) {
    guard peerId.namespace != Namespaces.Peer.SecretChat, isCurrentDraft(),
          !draft.string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
        return
    }

    let presentation = context.sharedContext.currentPresentationData.with { $0 }
    let strings = ExteraStrings(languageCode: presentation.strings.baseLanguageCode)
    let locale = Locale(identifier: presentation.strings.baseLanguageCode)
    let configured = ExteraSettingsStore.shared.value(for: ExteraPreferences.targetLang)
    let candidate = configured.isEmpty ? normalizeTranslationLanguage(presentation.strings.baseLanguageCode) : configured
    let target = supportedTranslationLanguages.contains(candidate) ? candidate : "en"
    let language = locale.localizedString(forLanguageCode: target) ?? target
    let confirm = TextAlertAction(type: .defaultAction, title: strings.text("Translate", "Перевести"), action: {
        guard isCurrentDraft() else { return }
        let _ = (context.engine.messages.translate(
            text: draft.string, toLang: target, entities: generateChatInputTextEntities(draft)
        )
        |> `catch` { _ in Signal<(String, [MessageTextEntity])?, NoError>.single(nil) }
        |> timeout(20.0, queue: .mainQueue(), alternate: .single(nil))
        |> take(1)
        |> deliverOnMainQueue).startStandalone(next: { result in
            guard isCurrentDraft() else { return }
            if let (text, entities) = result, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                replace(chatInputStateStringWithAppliedEntities(text, entities: entities))
            } else {
                present(textAlertController(
                    context: context, title: strings.text("Translation unavailable", "Перевод недоступен"),
                    text: strings.text("Your draft is still in the input field.", "Черновик остался в поле ввода."),
                    actions: [TextAlertAction(type: .defaultAction, title: presentation.strings.Common_OK, action: {})]
                ))
            }
        })
    })
    present(textAlertController(
        context: context, title: strings.translateDraft,
        text: strings.text(
            "Send this draft to Telegram’s translation service to translate it into \(language)? The translated draft stays in the input field until you send it.",
            "Отправить этот черновик сервису перевода Telegram? Язык перевода: \(language). Перевод останется в поле ввода до отправки."
        ),
        actions: [TextAlertAction(type: .genericAction, title: presentation.strings.Common_Cancel, action: {}), confirm]
    ))
}
