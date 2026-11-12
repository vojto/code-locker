import SwiftUI

/*
 * One row in the list: account name, its current code and the countdown ring.
 * Click the row to copy the code. Right-click for Copy and Delete.
 * While the account is locked (no secret), it shows dots and a padlock instead.
 */

struct AccountRow: View {
    let name: String
    let secret: String?
    let date: Date
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

                if isCopied {
                    Text("Copied")
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
}

#Preview {
    List {
        AccountRow(name: "GitHub", secret: "JBSWY3DPEHPK3PXP", date: .now) {}
        AccountRow(name: "Twitter", secret: nil, date: .now) {}
    }
    .frame(width: 340)
}
