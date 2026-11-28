import AppBundle
import Display
import ExteraSettings
import ItemListUI
import SwiftSignalKit
import UIKit

enum ExteraLivePreview: Equatable {
    case avatars(CGFloat, Bool, Bool)
    case chatList(stories: Bool, search: Bool, dividers: Bool, counters: Bool, snow: Bool, senderAvatars: Bool)
    case header(title: String, centered: Bool, status: Bool, composeInMenu: Bool, compactCompose: Bool, blur: ExteraHeaderBlur)
    case folders(ExteraFolderIcons, ExteraFolderCounters)
    case navigation([ExteraTab])
    case interface(ExteraNavigationAppearance)
    case menu(ExteraMenuAppearance, ExteraMenuOutline)
    case typography(ExteraTypography)
    case chatTheme(ExteraChatTheme)
    case motion(ExteraMotion)
    case messages(scale: CGFloat, shape: ExteraStickerShape, time: ExteraStickerTime, tails: Bool, editedIcon: Bool, reactions: Bool)
    case pills(ExteraPillConfiguration)
    case appIcon(imageName: String, title: String, credit: String)

    var height: CGFloat {
        switch self {
        case .pills(let config): return CGFloat(config.capsuleHeight) + 28
        case .header, .folders, .navigation: return 98
        case .appIcon: return 160
        case .interface: return 278
        case .menu: return 210
        case .motion: return 214
        case .chatList: return 182
        case .avatars, .messages, .typography, .chatTheme: return 148
        }
    }
}

final class ExteraAppearancePreviewItem: ListViewItem {
    let neighborDescriptor: AnyEquatable = .noNeighborInfluence
    let preview: ExteraLivePreview
    let presentationData: ItemListPresentationData
    let approximateHeight: CGFloat

    init(preview: ExteraLivePreview, presentationData: ItemListPresentationData) {
        self.preview = preview
        self.presentationData = presentationData
        self.approximateHeight = preview.height
    }

    func nodeConfiguredForParams(async: @escaping (@escaping () -> Void) -> Void, params: ListViewItemLayoutParams, synchronousLoads: Bool, neighbors: ListViewItemNeighbors, completion: @escaping (ListViewItemNode, @escaping () -> (Signal<Void, NoError>?, (ListViewItemApply) -> Void)) -> Void) {
        Queue.mainQueue().async {
            let node = ExteraAppearancePreviewNode()
            node.contentSize = CGSize(width: params.width, height: self.approximateHeight)
            completion(node, { (nil, { _ in node.apply(self, params: params) }) })
        }
    }

    func updateNode(async: @escaping (@escaping () -> Void) -> Void, node: @escaping () -> ListViewItemNode, params: ListViewItemLayoutParams, neighbors: ListViewItemNeighbors, animation: ListViewItemUpdateAnimation, completion: @escaping (ListViewItemNodeLayout, @escaping (ListViewItemApply) -> Void) -> Void) {
        Queue.mainQueue().async {
            let layout = ListViewItemNodeLayout(contentSize: CGSize(width: params.width, height: self.approximateHeight), insets: .zero)
            completion(layout, { _ in (node() as? ExteraAppearancePreviewNode)?.apply(self, params: params) })
        }
    }
}

private final class ExteraAppearancePreviewNode: ListViewItemNode {
    private let host = UIView()
    private var content: UIView?
    private var folderSelection = 0

    init() { super.init(layerBacked: false) }

    func apply(_ item: ExteraAppearancePreviewItem, params: ListViewItemLayoutParams) {
        if self.host.superview == nil { self.view.addSubview(self.host) }
        self.host.frame = CGRect(x: params.leftInset + 16, y: 8,
            width: max(1, params.width - params.leftInset - params.rightInset - 32), height: item.approximateHeight - 16)
        self.host.layer.cornerRadius = 18
        self.host.layer.cornerCurve = .continuous
        self.host.clipsToBounds = true
        let list = item.presentationData.theme.list
        self.host.backgroundColor = list.itemBlocksBackgroundColor
        let strings = ExteraStrings(languageCode: item.presentationData.strings.baseLanguageCode)

        func label(_ text: String, size: CGFloat = 14, color: UIColor? = nil) -> UILabel {
            let label = UILabel()
            label.text = text
            label.font = .systemFont(ofSize: size, weight: .medium)
            label.textColor = color ?? list.itemPrimaryTextColor
            label.numberOfLines = 2
            label.textAlignment = .center
            return label
        }

        let newContent: UIView
        switch item.preview {
        case let .pills(configuration):
            let strip = (self.content as? ExteraPillStrip) ?? ExteraPillStrip(frame: .zero)
            strip.update(configuration: configuration, language: item.presentationData.strings.baseLanguageCode,
                foreground: list.itemPrimaryTextColor, accent: list.itemAccentColor,
                surface: list.itemBlocksBackgroundColor, dark: item.presentationData.theme.overallDarkAppearance,
                proxyEnabled: nil, active: true, permitRequests: false, selecting: { _ in })
            newContent = strip
        case let .avatars(fraction, uniform, animate):
            let avatars = UIStackView(arrangedSubviews: ["A", "M", "#"].enumerated().map { index, title in
                let button = UIButton(type: .system)
                button.setTitle(title, for: .normal)
                button.setTitleColor(.white, for: .normal)
                button.titleLabel?.font = .systemFont(ofSize: 21, weight: .semibold)
                button.backgroundColor = [list.itemAccentColor, UIColor.systemTeal, UIColor.systemIndigo][index]
                button.layer.cornerRadius = index == 2 && !uniform ? 13 : 46 * fraction
                button.layer.cornerCurve = .continuous
                button.widthAnchor.constraint(equalToConstant: 46).isActive = true
                button.heightAnchor.constraint(equalToConstant: 46).isActive = true
                if animate {
                    button.addAction(UIAction { [weak button] _ in
                        guard let button, !UIAccessibility.isReduceMotionEnabled else { return }
                        button.transform = CGAffineTransform(scaleX: 0.78, y: 1.14)
                        UIView.animate(withDuration: 0.48, delay: 0, usingSpringWithDamping: 0.52, initialSpringVelocity: 0) {
                            button.transform = .identity
                        }
                    }, for: .touchUpInside)
                }
                return button
            })
            avatars.alignment = .center
            avatars.spacing = 12
            let stack = UIStackView(arrangedSubviews: [avatars, label(strings.text("Chat avatars", "Аватарки чатов"))])
            stack.axis = .vertical
            stack.alignment = .center
            stack.spacing = 9
            newContent = stack
        case let .chatList(stories, search, dividers, counters, snow, senderAvatars):
            var rows: [UIView] = []
            if stories { rows.append(label("◉  ◉  ◉", size: 21, color: list.itemAccentColor)) }
            if search { rows.append(label("⌕  " + strings.text("Search", "Поиск"), color: list.itemSecondaryTextColor)) }
            for (name, count) in [(strings.text("Design team", "Дизайн"), "3"), (strings.text("Saved Messages", "Избранное"), "")] {
                rows.append(label(name + (counters && !count.isEmpty ? "  ·  " + count : "")))
            }
            let sender = UIButton(type: .system)
            sender.setTitle(strings.text("Mira: See you soon", "Мира: До встречи"), for: .normal)
            if senderAvatars { sender.setImage(UIImage(systemName: "person.crop.circle.fill"), for: .normal) }
            sender.addAction(UIAction { [weak sender] _ in
                guard let sender else { return }
                sender.isSelected.toggle()
                sender.setTitle(sender.isSelected ? strings.text("Mira: Sounds good!", "Мира: Договорились!") : strings.text("Mira: See you soon", "Мира: До встречи"), for: .normal)
            }, for: .touchUpInside)
            rows.insert(sender, at: max(0, rows.count - 1))
            let stack = UIStackView(arrangedSubviews: rows)
            stack.axis = .vertical
            stack.distribution = .fillEqually
            stack.spacing = dividers ? 8 : 0
            if snow {
                let container = UIView()
                stack.frame = self.host.bounds.insetBy(dx: 10, dy: 10).offsetBy(dx: -10, dy: -10)
                stack.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                let snowView = ExteraSnowView(frame: stack.frame)
                snowView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                container.frame = stack.frame
                container.addSubview(stack)
                container.addSubview(snowView)
                snowView.update(active: true, color: list.itemAccentColor)
                newContent = container
            } else {
                newContent = stack
            }
        case let .motion(motion):
            let tile = label(strings.text("Choose a transition", "Выбери переход"), size: 16)
            tile.backgroundColor = list.itemAccentColor.withAlphaComponent(0.10)
            tile.layer.cornerRadius = 12
            tile.clipsToBounds = true
            let buttons = ExteraMotionTarget.allCases.map { target -> UIButton in
                let button = UIButton(type: .system)
                let shortTitle: String
                switch target {
                case .chatOpen: shortTitle = strings.text("Chat", "Чат")
                case .back: shortTitle = strings.text("Back", "Назад")
                case .tabs: shortTitle = strings.text("Tab", "Вкладка")
                case .menus: shortTitle = strings.text("Menu", "Меню")
                case .settings: shortTitle = strings.text("Settings", "Настройки")
                }
                button.setTitle(shortTitle, for: .normal)
                button.accessibilityLabel = target.title(strings)
                button.titleLabel?.font = .preferredFont(forTextStyle: .footnote)
                button.titleLabel?.adjustsFontSizeToFitWidth = true
                button.addAction(UIAction { [weak tile] _ in
                    guard let tile else { return }
                    let active = motion.forTarget(target)
                    let shift: CGFloat = target == .back ? -38 : 38
                    tile.text = target.title(strings)
                    tile.alpha = active.allowsMotion ? 0.36 : 1
                    if target == .menus {
                        tile.transform = active.restingOffset(horizontal: -38)
                    } else {
                        tile.transform = active.allowsMotion ? CGAffineTransform(translationX: shift, y: 0) : .identity
                    }
                    active.animate(duration: 0.28, { [weak tile] in
                        tile?.transform = .identity
                        tile?.alpha = 1
                    })
                }, for: .touchUpInside)
                return button
            }
            let first = UIStackView(arrangedSubviews: Array(buttons.prefix(3)))
            let second = UIStackView(arrangedSubviews: Array(buttons.suffix(2)))
            first.distribution = .fillEqually
            second.distribution = .fillEqually
            first.heightAnchor.constraint(equalToConstant: 44).isActive = true
            second.heightAnchor.constraint(equalToConstant: 44).isActive = true
            let stack = UIStackView(arrangedSubviews: [tile, first, second])
            stack.axis = .vertical
            stack.spacing = 6
            newContent = stack
        case let .chatTheme(theme):
            func color(_ rgb: UInt32) -> UIColor {
                return UIColor(red: CGFloat((rgb >> 16) & 255) / 255, green: CGFloat((rgb >> 8) & 255) / 255, blue: CGFloat(rgb & 255) / 255, alpha: 1)
            }
            let palette = theme.palette(dark: item.presentationData.theme.overallDarkAppearance)
            self.host.backgroundColor = palette.map { color($0.wallpaper) } ?? list.itemBlocksBackgroundColor
            let incoming = label(strings.text("  A quiet day  ", "  Спокойный день  "))
            incoming.backgroundColor = list.itemBlocksBackgroundColor
            incoming.layer.cornerRadius = 12
            incoming.clipsToBounds = true
            let outgoing = UIButton(type: .system)
            outgoing.setTitle(strings.text("  Tap to reply  ", "  Нажми для ответа  "), for: .normal)
            outgoing.setTitleColor(palette.map { color($0.accent) } ?? list.itemAccentColor, for: .normal)
            outgoing.backgroundColor = palette.map { color($0.outgoing) } ?? list.itemAccentColor.withAlphaComponent(0.15)
            outgoing.layer.cornerRadius = 12
            outgoing.addAction(UIAction { [weak outgoing] _ in
                guard let outgoing else { return }
                outgoing.isSelected.toggle()
                outgoing.setTitle(outgoing.isSelected ? strings.text("  Hello!  ", "  Привет!  ") : strings.text("  Tap to reply  ", "  Нажми для ответа  "), for: .normal)
            }, for: .touchUpInside)
            let stack = UIStackView(arrangedSubviews: [incoming, outgoing])
            stack.axis = .vertical
            stack.alignment = .center
            stack.distribution = .fillEqually
            stack.spacing = 8
            newContent = stack
        case let .typography(typography):
            let title = label(strings.text("Design team", "Команда дизайна"), size: 16)
            title.font = typography.font(.systemFont(ofSize: 16, weight: .semibold), weight: .semibold)
            let message = UIButton(type: .system)
            let font = typography.font(.systemFont(ofSize: 15), weight: .regular)
            func sample(_ value: String) -> NSAttributedString {
                return typography.emojiStyle.applying(to: NSAttributedString(string: value, attributes: [.font: font, .foregroundColor: list.itemAccentColor]))
            }
            let first = sample(strings.text("Tap to change the sample 👋", "Нажмите, чтобы изменить пример 👋"))
            let second = sample(strings.text("Tomorrow at 10:30 ☕", "Завтра в 10:30 ☕"))
            message.setAttributedTitle(first, for: .normal)
            message.titleLabel?.adjustsFontSizeToFitWidth = true
            message.addAction(UIAction { [weak message] _ in
                guard let message else { return }
                message.isSelected.toggle()
                message.setAttributedTitle(message.isSelected ? second : first, for: .normal)
            }, for: .touchUpInside)
            let stack = UIStackView(arrangedSubviews: [title, message])
            stack.axis = .vertical
            stack.distribution = .fillEqually
            newContent = stack
        case let .header(title, centered, status, composeInMenu, compactCompose, blur):
            let titleLabel = label(title + (status ? "  ✦" : ""), size: 19)
            titleLabel.textAlignment = centered ? .center : .left
            let compose = UIImageView(image: UIImage(systemName: composeInMenu ? "ellipsis" : "square.and.pencil"))
            compose.tintColor = list.itemAccentColor
            compose.backgroundColor = list.itemAccentColor.withAlphaComponent(0.15)
            compose.layer.cornerRadius = compactCompose ? 8 : 17
            compose.contentMode = .center
            compose.widthAnchor.constraint(equalToConstant: 34).isActive = true
            compose.heightAnchor.constraint(equalToConstant: 34).isActive = true
            let stack = UIStackView(arrangedSubviews: [titleLabel, compose])
            stack.alignment = .center
            stack.spacing = 8
            let panel = UIView()
            let region = self.host.bounds.insetBy(dx: 10, dy: 10)
            let bounds = CGRect(origin: .zero, size: region.size)
            panel.frame = bounds
            panel.clipsToBounds = true
            panel.layer.cornerRadius = 12
            let gradient = CAGradientLayer()
            gradient.colors = [list.itemAccentColor.withAlphaComponent(blur == .none ? 0 : 0.35).cgColor,
                list.itemBlocksBackgroundColor.cgColor]
            gradient.frame = bounds
            panel.layer.addSublayer(gradient)
            if (blur == .progressive || blur == .standard), !UIAccessibility.isReduceTransparencyEnabled {
                let style: UIBlurEffect.Style = item.presentationData.theme.overallDarkAppearance ? .systemMaterialDark : .systemMaterialLight
                let blurView = UIVisualEffectView(effect: UIBlurEffect(style: style))
                blurView.frame = bounds
                blurView.alpha = blur == .progressive ? 0.55 : 0.8
                panel.addSubview(blurView)
            }
            stack.frame = bounds.insetBy(dx: 8, dy: 0)
            panel.addSubview(stack)
            newContent = panel
        case let .folders(mode, counters):
            let stack = UIStackView()
            stack.distribution = .fillEqually
            stack.spacing = 4
            for (index, name) in [strings.text("All", "Все"), strings.text("Work", "Работа"), strings.text("Personal", "Личное")].enumerated() {
                let button = UIButton(type: .system)
                var config = UIButton.Configuration.tinted()
                config.image = mode == .text ? nil : UIImage(systemName: ["square.stack", "briefcase", "star"][index])
                let badge = index == 1 ? (counters == .all ? " 6" : counters == .unmuted ? " 2" : "") : ""
                config.title = mode == .icons ? badge : name + badge
                config.imagePadding = 4
                config.baseForegroundColor = index == self.folderSelection ? list.itemAccentColor : list.itemSecondaryTextColor
                button.configuration = config
                button.accessibilityLabel = name
                button.addAction(UIAction { [weak self] _ in
                    guard let self else { return }
                    self.folderSelection = index
                    self.apply(item, params: params)
                }, for: .touchUpInside)
                stack.addArrangedSubview(button)
            }
            newContent = stack
        case let .navigation(tabs):
            let stack = UIStackView(arrangedSubviews: tabs.map { kind in
                let image = UIImageView(image: UIImage(systemName: kind.symbol))
                image.tintColor = list.itemAccentColor
                image.contentMode = .scaleAspectFit
                let tab = UIStackView(arrangedSubviews: [image, label(kind.title(strings), size: 11)])
                tab.axis = .vertical
                tab.alignment = .center
                tab.spacing = 5
                return tab
            })
            stack.distribution = .fillEqually
            stack.alignment = .center
            newContent = stack
        case let .interface(config):
            let preview = ExteraInterfacePreviewView(frame: .zero)
            preview.configure(config: config, data: item.presentationData, strings: strings)
            newContent = preview
        case let .menu(config, outline):
            let card = UIView()
            let surface = ExteraMenuSurface(frame: .zero)
            surface.configure(config, outline: outline, base: item.presentationData.theme.contextMenu.backgroundColor,
                accent: list.itemAccentColor, dark: item.presentationData.theme.overallDarkAppearance)
            let background = UIStackView(arrangedSubviews: [
                label(strings.text("Preview message", "Пример сообщения"), color: list.itemAccentColor),
                label(strings.text("Touch a menu action", "Нажми на действие меню"), color: list.itemSecondaryTextColor),
            ])
            background.axis = .vertical
            background.distribution = .fillEqually
            background.backgroundColor = list.itemAccentColor.withAlphaComponent(0.15)
            background.layer.cornerRadius = 12
            let bounds = CGRect(origin: .zero, size: self.host.bounds.insetBy(dx: 10, dy: 10).size)
            card.frame = bounds
            background.frame = bounds
            card.addSubview(background)
            surface.frame = bounds.insetBy(dx: 22, dy: 36)
            card.addSubview(surface)
            let actions = UIStackView()
            actions.axis = .vertical
            actions.distribution = .fillEqually
            for title in [strings.text("Reply", "Ответить"), strings.text("Copy", "Копировать"), strings.text("Forward", "Переслать")] {
                let button = UIButton(type: .system)
                button.setTitle(title, for: .normal)
                button.addAction(UIAction { _ in (background.arrangedSubviews.last as? UILabel)?.text = title }, for: .touchUpInside)
                actions.addArrangedSubview(button)
            }
            actions.frame = surface.frame.insetBy(dx: 12, dy: 2)
            card.addSubview(actions)
            newContent = card
        case let .messages(scale, shape, time, tails, editedIcon, reactions):
            let incoming = label((tails ? "◂  " : "") + strings.text("On my way!", "Уже иду!"), color: list.itemPrimaryTextColor)
            let outgoing = label(strings.text("See you", "До встречи") + (editedIcon ? "  ✎" : "  " + strings.text("edited", "изм.")), color: list.itemAccentColor)
            let sticker = label("🐈", size: 34 * scale)
            sticker.backgroundColor = list.itemAccentColor.withAlphaComponent(0.12)
            sticker.layer.cornerRadius = shape.radius(bubbleRadius: 15)
            sticker.clipsToBounds = true
            sticker.widthAnchor.constraint(equalToConstant: 54 * scale).isActive = true
            let stickerRow = UIStackView(arrangedSubviews: [sticker])
            stickerRow.spacing = 6
            let timeLabel = label("12:35", size: 10, color: list.itemSecondaryTextColor)
            if time == .side { stickerRow.addArrangedSubview(timeLabel) }
            let stack = UIStackView(arrangedSubviews: [incoming, outgoing, stickerRow])
            if reactions { stack.addArrangedSubview(label("❤️ 1", size: 12)) }
            if time == .standard { stack.addArrangedSubview(timeLabel) }
            stack.axis = .vertical
            stack.alignment = .center
            stack.spacing = 3
            stack.distribution = .fillEqually
            newContent = stack
        case let .appIcon(imageName, title, credit):
            let icon = UIImageView(image: UIImage(bundleImageName: imageName))
            icon.contentMode = .scaleAspectFit
            icon.layer.cornerRadius = 15
            icon.clipsToBounds = true
            icon.heightAnchor.constraint(equalToConstant: 62).isActive = true
            icon.widthAnchor.constraint(equalToConstant: 62).isActive = true
            let stage = UIStackView(arrangedSubviews: [icon])
            stage.isLayoutMarginsRelativeArrangement = true
            stage.layoutMargins = UIEdgeInsets(top: 7, left: 16, bottom: 7, right: 16)
            stage.backgroundColor = list.itemAccentColor.withAlphaComponent(0.15)
            stage.layer.cornerRadius = 19
            for symbol in ["calendar", "camera"] {
                let tile = UIImageView(image: UIImage(systemName: symbol))
                tile.contentMode = .center
                tile.tintColor = list.itemSecondaryTextColor
                tile.backgroundColor = list.itemBlocksBackgroundColor
                tile.layer.cornerRadius = 11
                tile.widthAnchor.constraint(equalToConstant: 34).isActive = true
                tile.heightAnchor.constraint(equalToConstant: 34).isActive = true
                stage.addArrangedSubview(tile)
            }
            stage.alignment = .center
            stage.spacing = 8
            let stack = UIStackView(arrangedSubviews: [stage, label(title, size: 16), label(credit, size: 12, color: list.itemSecondaryTextColor)])
            stack.axis = .vertical
            stack.alignment = .center
            stack.spacing = 5
            newContent = stack
        }

        let layout = self.host.bounds.insetBy(dx: 10, dy: 10)
        newContent.frame = layout
        if self.content !== newContent {
            let oldContent = self.content
            self.content = newContent
            self.host.addSubview(newContent)
            if let oldContent, self.view.window != nil, !UIAccessibility.isReduceMotionEnabled {
                newContent.alpha = 0
                UIView.animate(withDuration: 0.18, animations: {
                    newContent.alpha = 1
                    oldContent.alpha = 0
                }, completion: { _ in oldContent.removeFromSuperview() })
            } else {
                oldContent?.removeFromSuperview()
            }
        }
    }
}
