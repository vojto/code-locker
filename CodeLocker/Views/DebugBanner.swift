import SwiftUI

/*
 * The orange strip at the bottom of the window in debug builds, so a debug build
 * (with its own accounts) is never mistaken for the real app in Applications.
 * Used by AccountListView. Production builds don't show it.
 */

struct DebugBanner: View {
    var body: some View {
        Label("Debug build", systemImage: "hammer.fill")
            .font(.callout.weight(.medium))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(.orange)
    }
}

#Preview {
    DebugBanner()
        .frame(width: 340)
}
