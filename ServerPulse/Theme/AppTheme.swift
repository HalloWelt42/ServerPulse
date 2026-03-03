import SwiftUI

// MARK: - Hand Cursor on Hover
extension View {
    /// Shows a pointing hand cursor when hovering, like web links
    func handCursorOnHover() -> some View {
        self.onHover { inside in
            if inside {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}
