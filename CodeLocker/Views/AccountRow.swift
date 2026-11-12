import SwiftUI

/*
 * One row in the list: account name, its current code and the countdown ring.
 * Click the row to copy the code. Right-click for Copy and Delete.
 */

struct AccountRow: View {
    let account: Account
    let date: Date
    let onDelete: () -> Void

    @State private var isCopied = false

    var body: some View {
        Button(action: copyCode) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(account.name)
                        .foregroundStyle(.secondary)

                    Text(formattedCode)
                        .font(.system(.title, design: .rounded).monospacedDigit())
                        .fontWeight(.medium)
                        .contentTransition(.numericText())
                }

                Spacer()

                if isCopied {
                    Text("Copied")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .transition(.opacity)
                }

                CountdownRing(secondsRemaining: TOTP.secondsRemaining(at: date), period: TOTP.period)
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help("Click to copy")
        .animation(.default, value: isCopied)
        .animation(.default, value: code)
        .contextMenu {
            Button("Copy Code", action: copyCode)
            Divider()
            Button("Delete…", role: .destructive, action: onDelete)
        }
    }

    // MARK: - Code

    private var code: String {
        account.code(at: date)
    }

    private var formattedCode: String {
        "\(code.prefix(3)) \(code.suffix(3))"
    }

    private func copyCode() {
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
        AccountRow(account: Account(name: "GitHub", secret: "JBSWY3DPEHPK3PXP"), date: .now) {}
        AccountRow(account: Account(name: "Google", secret: "GEZDGNBVGY3TQOJQ"), date: .now) {}
    }
    .frame(width: 340)
}
