import SwiftUI

/*
 * The sheet for adding an account: a name and the secret key from the website.
 * Also takes a whole otpauth:// link pasted into the key field. The Add button
 * only lights up once the key is valid.
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

    private var isValid: Bool {
        !trimmedName.isEmpty && Base32.decode(secret) != nil
    }
}

#Preview {
    AddAccountSheet { _, _ in }
}
