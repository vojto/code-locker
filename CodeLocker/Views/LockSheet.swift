import SwiftUI

/*
 * The sheet for locking one account: how long, as a number and a unit like
 * "2 Weeks". Starts from the account's last lock period. Shows the exact time
 * the lock opens, and warns that a lock can't be undone or opened early.
 * The amount is kept as typed text, so the opening time follows every keystroke.
 */

struct LockSheet: View {
    let name: String
    let onLock: (LockPeriod) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var amountText: String
    @State private var unit: LockPeriod.Unit

    init(name: String, initialPeriod: LockPeriod, onLock: @escaping (LockPeriod) -> Void) {
        self.name = name
        self.onLock = onLock
        _amountText = State(initialValue: String(initialPeriod.amount))
        _unit = State(initialValue: initialPeriod.unit)
    }

    var body: some View {
        Form {
            Text("Lock “\(name)”")
                .font(.headline)

            LabeledContent("Lock For:") {
                HStack {
                    TextField("Amount", text: $amountText)
                        .labelsHidden()
                        .frame(width: 60)

                    Stepper("Amount", value: amountBinding, in: 1...999)
                        .labelsHidden()

                    Picker("Unit", selection: $unit) {
                        ForEach(LockPeriod.Unit.allCases) { unit in
                            Text(unit.title)
                        }
                    }
                    .labelsHidden()
                    .fixedSize()
                }
            }

            if isValid {
                LabeledContent("Opens:") {
                    TimelineView(.everyMinute) { timeline in
                        Text(period.end(from: timeline.date).formatted(.dateTime.weekday(.wide).day().month(.wide).hour().minute()))
                    }
                }
            }

            Text("There is no way to undo this or open it early, not even for you. Make sure you won't need this code before then.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .frame(width: 400)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Lock", action: lock)
                    .disabled(!isValid)
            }
        }
    }

    // MARK: - Actions

    private func lock() {
        onLock(period)
        dismiss()
    }

    // MARK: - Period

    private var amount: Int {
        Int(amountText) ?? 0
    }

    private var period: LockPeriod {
        LockPeriod(amount: amount, unit: unit)
    }

    private var isValid: Bool {
        amount >= 1
    }

    private var amountBinding: Binding<Int> {
        Binding(
            get: { amount },
            set: { amountText = String($0) }
        )
    }
}

#Preview {
    LockSheet(name: "GitHub", initialPeriod: .standard) { _ in }
}
