import Foundation
import ExteraSettings
import UIKit
import TelegramPresentationData
import TelegramUIPreferences

public final class ChatListPresentationData {
    public let theme: PresentationTheme
    public let fontSize: PresentationFontSize
    public let strings: PresentationStrings
    public let dateTimeFormat: PresentationDateTimeFormat
    public let nameSortOrder: PresentationPersonNameOrder
    public let nameDisplayOrder: PresentationPersonNameOrder
    public let disableAnimations: Bool
    let exteraTypography: ExteraTypography
    let exteraSenderMiniAvatars: Bool
    
    public init(theme: PresentationTheme, fontSize: PresentationFontSize, strings: PresentationStrings, dateTimeFormat: PresentationDateTimeFormat, nameSortOrder: PresentationPersonNameOrder, nameDisplayOrder: PresentationPersonNameOrder, disableAnimations: Bool) {
        self.theme = theme
        self.fontSize = fontSize
        self.strings = strings
        self.dateTimeFormat = dateTimeFormat
        self.nameSortOrder = nameSortOrder
        self.nameDisplayOrder = nameDisplayOrder
        self.disableAnimations = disableAnimations
        self.exteraTypography = ExteraSettingsStore.shared.value(for: ExteraPreferences.typography)
        self.exteraSenderMiniAvatars = ExteraSettingsStore.shared.value(for: ExteraPreferences.senderMiniAvatars)
    }
}
