import SwiftUI

enum Currency: String, CaseIterable, Identifiable {
    case usd = "USD"
    case inr = "INR"
    case gbp = "GBP"
    case thb = "THB"

    var id: String { rawValue }
}

struct AddView: View {
    @Environment(\.dismiss) var dismiss

    @State private var name: String = ""
    @State private var type: String = "Personal"

    // ✅ keep user input as text
    @State private var amountText: String = ""

    @State private var currency: Currency = .usd

    // ✅ alert state
    @State private var showInvalidAmountAlert = false

    var expenses: Expenses
    let types = ["Business", "Personal"]

    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $name)

                Picker("Type:", selection: $type) {
                    ForEach(types, id: \.self) { Text($0) }
                }

                HStack {
                    TextField("Amount", text: $amountText)
                        .keyboardType(.decimalPad)

                    Picker("Currency", selection: $currency) {
                        ForEach(Currency.allCases) { c in
                            Text(c.rawValue).tag(c)
                        }
                    }
                    .labelsHidden()
                }
            }
            .navigationTitle("Add New Expense")
            .toolbar {
                Button("Save") {
                    // ✅ allow "12.34" or "12,34" (we normalize comma -> dot)
                    let cleaned = amountText
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                        .replacingOccurrences(of: ",", with: ".")

                    // ✅ reject empty or non-numeric input (also rejects "$12", "12USD", etc.)
                    guard let amount = Double(cleaned), amount.isFinite else {
                        showInvalidAmountAlert = true
                        return
                    }

                    let item = ExpenseItem(
                        name: name,
                        type: type,
                        amount: amount,
                        currency: currency.rawValue
                    )
                    expenses.items.append(item)
                    dismiss()
                }
            }
            .alert("Invalid amount", isPresented: $showInvalidAmountAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Please enter numbers only (example: 12.34).")
            }
        }
    }
}
