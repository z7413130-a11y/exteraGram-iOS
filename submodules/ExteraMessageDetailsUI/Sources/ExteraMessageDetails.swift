import AccountContext
import Display
import ExteraSettings
import Foundation
import PresentationDataUtils
import TelegramCore

/// Metadata already available in the local message. The details do not fetch
/// more information or expose an edit marker hidden by the server.
public func exteraMessageDetailsController(context: AccountContext, message: EngineRawMessage) -> ViewController {
    let presentation = context.sharedContext.currentPresentationData.with { $0 }
    let strings = ExteraStrings(languageCode: presentation.strings.baseLanguageCode)
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: presentation.strings.baseLanguageCode)
    formatter.dateStyle = .medium
    formatter.timeStyle = .medium

    var lines = [
        strings.text("Message ID", "ID сообщения") + " · " + String(message.id.id),
        strings.text("Sent", "Отправлено") + " · " + formatter.string(from: Date(timeIntervalSince1970: Double(message.timestamp))),
    ]
    if let author = message.author {
        lines.append(strings.text("Sender ID", "ID отправителя") + " · " + String(author.id.id._internalGetInt64Value()))
    }
    for attribute in message.attributes {
        if let edited = attribute as? EditedMessageAttribute, !edited.isHidden, edited.date > 0 {
            lines.append(strings.text("Edited", "Изменено") + " · " + formatter.string(from: Date(timeIntervalSince1970: Double(edited.date))))
        } else if let views = attribute as? ViewCountMessageAttribute {
            lines.append(strings.text("Views", "Просмотры") + " · " + String(views.count))
        } else if let forwards = attribute as? ForwardCountMessageAttribute {
            lines.append(strings.text("Forwards", "Пересылки") + " · " + String(forwards.count))
        } else if let replies = attribute as? ReplyThreadMessageAttribute {
            lines.append(strings.text("Replies", "Ответы") + " · " + String(replies.count))
        }
    }

    return textAlertController(
        context: context, title: strings.messageDetails, text: lines.joined(separator: "\n"),
        actions: [TextAlertAction(type: .defaultAction, title: presentation.strings.Common_OK, action: {})]
    )
}
