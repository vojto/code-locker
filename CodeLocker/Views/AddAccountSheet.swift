import SwiftUI

/*
 * The sheet for adding an account: a name and the secret key from the website.
 * Also takes a whole otpauth:// link pasted into the key field. Once the key is
 * valid it shows the current code, because websites ask for one to finish setup
 * and the account gets locked as soon as it is added.
 */

struct AddAccountSheet: View {
    let onAdd: (_ name: String, _ secret: String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var secret = ""

    var body: some View {
        Form {
            TextField("Name:", text: $name, prompt: Text("GitHub"))

            TextField("Secret Key:", text: $secret, prompt: Text("JBSW Y3DP EHPK 3PXP"))

            Text("Paste the setup key the website shows you, or an otpauth:// link.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            if isSecretValid {
                LabeledContent("Code Now:") {
                    TimelineView(.periodic(from: .now, by: 1)) { timeline in
                        Text(TOTP.code(base32Secret: secret, at: timeline.date)?.groupedInThrees ?? "")
                            .font(.body.monospacedDigit().weight(.medium))
                            .textSelection(.enabled)
                    }
                }

                Text("If the website asks for a code to finish setup, use this one now. After you click Add, codes are locked until the next opening.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(20)
        .frame(width: 400)
        .onChange(of: secret) { fillFromLink() }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Add", action: add)
                    .disabled(!isValid)
            }
        }
    }

    // MARK: - Actions

    private func add() {
        onAdd(trimmedName, secret)
        dismiss()
    }

    private func fillFromLink() {
        guard let link = OTPAuthLink(secret) else { return }
        secret = link.secret
        if trimmedName.isEmpty { name = link.name }
    }

    // MARK: - Validation

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespaces)
    }

    private var isSecretValid: Bool {
        Base32.decode(secret) != nil
    }

    private var isValid: Bool {
        !trimmedName.isEmpty && isSecretValid
    }
}

#Preview {
    AddAccountSheet { _, _ in }
}
