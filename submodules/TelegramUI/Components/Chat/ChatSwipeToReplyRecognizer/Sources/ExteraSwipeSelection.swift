import CoreGraphics

struct ExteraSwipeSelection {
    private var anchor: CGFloat?
    private var index = 0
    private var hasStepped = false
    private var direction: CGFloat = 1

    mutating func update(translation: CGPoint, horizontalThreshold: CGFloat, actionCount: Int, wraps: Bool, reversed: Bool, preferDown: Bool) -> Int {
        guard actionCount > 1, abs(translation.x) >= horizontalThreshold else {
            self = ExteraSwipeSelection()
            return 0
        }
        guard let anchor = self.anchor else {
            self.anchor = translation.y
            self.direction = preferDown ? 1 : -1
            return self.index
        }
        let travel = (translation.y - anchor) * self.direction * (reversed ? -1 : 1)
        guard abs(travel) >= (self.hasStepped ? 36 : 44) else { return self.index }
        self.anchor = translation.y
        self.hasStepped = true
        let nextIndex = self.index + (travel > 0 ? 1 : -1)
        self.index = wraps ? (nextIndex + actionCount) % actionCount : min(actionCount - 1, max(0, nextIndex))
        return self.index
    }
}
