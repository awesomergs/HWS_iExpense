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

    // ✅ CHANGED: category instead of "Business/Personal"
    @State private var category: ExpenseCategory = .food

    // keep user input as text
    @State private var amountText: String = ""

    @State private var currency: Currency = .usd

    // NEW
    @State private var date: Date = .now
    @State private var store: String = ""
    @State private var details: String = ""

    // store search
    @State private var storeSearch: String = ""

    // alert state
    @State private var showInvalidAmountAlert = false

    var expenses: Expenses

    let storeOptions = [
        "Amazon",
        "Target",
        "Trader Joe's",
        "Taco Bell",
        "Starbucks",
        "Chipotle",
        "Uber",
        "Lyft",
        "Apple",
        "Waymo",
        "RTCC",
        "USC Bookstore",
        "Other"
    ]

    var filteredStores: [String] {
        let q = storeSearch.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return storeOptions }
        return storeOptions.filter { $0.localizedCaseInsensitiveContains(q) }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Basic") {
                    TextField("Name", text: $name)

                    Picker("Category", selection: $category) {
                        ForEach(ExpenseCategory.allCases) { c in
                            Text("\(c.emoji) \(c.rawValue)").tag(c)
                        }
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

                Section("When") {
                    DatePicker(
                        "Date & Time",
                        selection: $date,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                }

                Section("Store") {
                    TextField("Search stores", text: $storeSearch)

                    Picker("Select store", selection: $store) {
                        Text("Select…").tag("")
                        ForEach(filteredStores, id: \.self) { s in
                            Text(s).tag(s)
                        }
                    }
                }

                Section("Description (optional)") {
                    TextField("Notes, items, why you bought it…", text: $details, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Add New Expense")
            .toolbar {
                Button("Save") {
                    let cleaned = amountText
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                        .replacingOccurrences(of: ",", with: ".")

                    guard let amount = Double(cleaned), amount.isFinite else {
                        showInvalidAmountAlert = true
                        return
                    }

                    let finalStore = store.isEmpty ? "Other" : store

                    let item = ExpenseItem(
                        name: name,
                        category: category,
                        amount: amount,
                        currency: currency.rawValue,
                        date: date,
                        store: finalStore,
                        details: details
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
            .onAppear {
                date = .now
            }
        }
    }
}
