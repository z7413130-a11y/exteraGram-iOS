import ComponentFlow
import Display
import ExteraSettings
import TelegramPresentationData
import UIKit

struct ExteraPillPanel: Component {
    let configuration: ExteraPillConfiguration
    let theme: PresentationTheme
    let language: String
    let proxyEnabled: Bool
    let active: Bool
    let selection: (ExteraPill) -> Void

    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.configuration == rhs.configuration && lhs.theme === rhs.theme &&
            lhs.language == rhs.language && lhs.proxyEnabled == rhs.proxyEnabled && lhs.active == rhs.active
    }

    func makeView() -> ExteraPillStrip { return ExteraPillStrip(frame: .zero) }

    func update(view: ExteraPillStrip, availableSize: CGSize, state: EmptyComponentState, environment: Environment<Empty>, transition: ComponentTransition) -> CGSize {
        view.update(configuration: self.configuration, language: self.language,
            foreground: self.theme.list.itemPrimaryTextColor, accent: self.theme.list.itemAccentColor,
            surface: self.theme.list.itemBlocksBackgroundColor, dark: self.theme.overallDarkAppearance,
            proxyEnabled: self.proxyEnabled, active: self.active, selecting: self.selection)
        return CGSize(width: availableSize.width, height: CGFloat(self.configuration.capsuleHeight) + 12)
    }
}

struct ExteraFolderLabel: Component {
    let title: String
    let icon: String
    let color: UIColor

    func makeView() -> UILabel {
        let view = UILabel()
        view.lineBreakMode = .byTruncatingTail
        return view
    }

    func update(view: UILabel, availableSize: CGSize, state: EmptyComponentState, environment: Environment<Empty>, transition: ComponentTransition) -> CGSize {
        let font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        let text = NSMutableAttributedString(string: "", attributes: [.font: font])
        if let image = UIImage(systemName: self.icon, withConfiguration: UIImage.SymbolConfiguration(font: font)) {
            let attachment = NSTextAttachment()
            attachment.image = image.withTintColor(self.color, renderingMode: .alwaysOriginal)
            text.append(NSAttributedString(attachment: attachment))
        }
        if !self.title.isEmpty {
            text.append(NSAttributedString(string: " " + self.title, attributes: [.font: font, .foregroundColor: self.color]))
        }
        view.attributedText = text
        return view.sizeThatFits(availableSize)
    }
}
