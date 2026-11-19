import SwiftUI

/*
 * One row in the list: account name, its current code and the countdown ring.
 * Click the row to copy the code. Right-click for Copy, Lock and Delete.
 * While the account is locked (no secret), it shows dots, a padlock and when
 * it opens, like "Opens in 3 days". Once that time has passed, it says
 * "Opening…" until the app has the key.
 */

struct AccountRow: View {
    let name: String
    let secret: String?
    let opening: Date?
    let date: Date
    let onLock: () -> Void
    let onDelete: () -> Void

    @State private var isCopied = false

    var body: some View {
        Button(action: copyCode) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .foregroundStyle(.secondary)

                    Text(code?.groupedInThrees ?? "••• •••")
                        .font(.system(.title, design: .rounded).monospacedDigit())
                        .fontWeight(.medium)
                        .foregroundStyle(isLocked ? .tertiary : .primary)
                        .contentTransition(.numericText())
                }

                Spacer()

                if let noteText {
                    Text(noteText)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .transition(.opacity)
                }

                if isLocked {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(.tertiary)
                        .frame(width: 20, height: 20)
                } else {
                    CountdownRing(secondsRemaining: TOTP.secondsRemaining(at: date), period: TOTP.period)
                }
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isLocked)
        .help(isLocked ? "Locked" : "Click to copy")
        .animation(.default, value: isCopied)
        .animation(.default, value: code)
        .contextMenu {
            Button("Copy Code", action: copyCode)
                .disabled(isLocked)
            Button("Lock…", action: onLock)
                .disabled(isLocked)
            Divider()
            Button("Delete…", role: .destructive, action: onDelete)
        }
    }

    // MARK: - Code

    private var isLocked: Bool {
        secret == nil
    }

    private var code: String? {
        secret.flatMap { TOTP.code(base32Secret: $0, at: date) }
    }

    private func copyCode() {
        guard let code else { return }

        Pasteboard.copy(code)
        isCopied = true

        Task {
            try? await Task.sleep(for: .seconds(1.5))
            isCopied = false
        }
    }

    // MARK: - Note

    /// The small text next to the ring or padlock.
    private var noteText: String? {
        if isCopied { return "Copied" }
        guard let opening else { return nil }
        return opening > date ? "Opens \(opening.relativeText(from: date))" : "Opening…"
    }
}

#Preview {
    List {
        AccountRow(name: "GitHub", secret: "JBSWY3DPEHPK3PXP", opening: nil, date: .now, onLock: {}, onDelete: {})
        AccountRow(name: "Twitter", secret: nil, opening: .now.addingTimeInterval(3 * 86_400), date: .now, onLock: {}, onDelete: {})
        AccountRow(name: "Reddit", secret: nil, opening: .now.addingTimeInterval(-10), date: .now, onLock: {}, onDelete: {})
    }
    .frame(width: 340)
}
