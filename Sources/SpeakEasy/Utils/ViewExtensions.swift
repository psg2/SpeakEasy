import AppKit
import SwiftUI

extension View {
    /// Adds a pointing hand cursor when hovering over the view.
    func handCursorOnHover() -> some View {
        self.onHover { hovering in
            if hovering { NSCursor.pointingHand.push() } else { NSCursor.pop() }
        }
    }
}
