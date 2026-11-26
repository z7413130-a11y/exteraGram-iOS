import Display
import ExteraSettings
import PresentationDataUtils

extension ChatControllerImpl {
    func withExteraPaidMediaConfirmation(_ preference: ExteraPreference<Bool>, english: String, russian: String, completion: @escaping (Bool) -> Void) {
        self.withExteraMediaConfirmation(preference, english: english, russian: russian) { [weak self] in
            self?.presentPaidMessageAlertIfNeeded(completion: completion)
        }
    }

    func withExteraMediaConfirmation(_ preference: ExteraPreference<Bool>, english: String, russian: String, send: @escaping () -> Void) {
        guard ExteraSettingsStore.shared.value(for: preference) else {
            send()
            return
        }
        self.presentExteraSendConfirmation(english: english, russian: russian, send: send)
    }

    func presentExteraSendConfirmation(english: String, russian: String, send: @escaping () -> Void) {
        let location = self.chatLocation
        let strings = ExteraStrings(languageCode: self.presentationData.strings.baseLanguageCode)
        self.present(textAlertController(context: self.context, title: strings.text(english, russian), text: "",
            actions: [
                TextAlertAction(type: .genericAction, title: self.presentationData.strings.Common_Cancel, action: {}),
                TextAlertAction(type: .defaultAction, title: strings.text("Send", "Отправить"), action: { [weak self] in
                    guard let self, self.chatLocation == location, self.viewIfLoaded?.window != nil else { return }
                    send()
                }),
            ]), in: .window(.root))
    }
}
