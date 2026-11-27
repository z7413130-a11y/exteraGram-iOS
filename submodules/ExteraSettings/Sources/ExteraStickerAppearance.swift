import CoreGraphics

public enum ExteraStickerTime: Int, CaseIterable {
    case standard
    case side
    case hidden

    public func title(_ strings: ExteraStrings) -> String {
        switch self {
        case .standard: return strings.text("Standard", "Стандартное")
        case .side: return strings.text("Beside the sticker", "Сбоку от стикера")
        case .hidden: return strings.text("Hidden", "Скрыто")
        }
    }

    public func statusFrame(_ original: CGRect, image: CGRect, leading: CGFloat, trailing: CGFloat, incoming: Bool) -> CGRect {
        guard self == .side else { return original }
        let padding: CGFloat = 6
        let candidates = [image.maxX + padding, image.minX - padding - original.width]
        let ordered = incoming ? candidates : [candidates[1], candidates[0]]
        guard let x = ordered.first(where: { $0 >= leading && $0 + original.width <= trailing }) else { return original }
        return CGRect(x: x, y: image.midY - original.height / 2, width: original.width, height: original.height)
    }
}

public enum ExteraStickerShape: Int, CaseIterable {
    case standard
    case rounded
    case message

    public func title(_ strings: ExteraStrings) -> String {
        switch self {
        case .standard: return strings.text("Original shape", "Исходная форма")
        case .rounded: return strings.text("Rounded corners", "Скруглённые углы")
        case .message: return strings.text("Chat bubble corners", "Скругление как у сообщения")
        }
    }

    public func radius(bubbleRadius: CGFloat) -> CGFloat {
        switch self {
        case .standard: return 0
        case .rounded: return 6
        case .message: return bubbleRadius
        }
    }
}
