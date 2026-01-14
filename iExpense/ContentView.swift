import Observation
import SwiftUI

struct ExpenseItem: Identifiable, Codable {
    var id = UUID()
    let name: String
    let type: String
    let amount: Double
    let currency: String

    let date: Date
    let store: String
    let details: String

    enum CodingKeys: String, CodingKey {
        case id, name, type, amount, currency, date, store, details
    }

    init(
        id: UUID = UUID(),
        name: String,
        type: String,
        amount: Double,
        currency: String,
        date: Date = .now,
        store: String,
        details: String = ""
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.amount = amount
        self.currency = currency
        self.date = date
        self.store = store
        self.details = details
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try c.decode(String.self, forKey: .name)
        type = try c.decode(String.self, forKey: .type)
        amount = try c.decode(Double.self, forKey: .amount)

        // Backward compatible defaults !!
        currency = try c.decodeIfPresent(String.self, forKey: .currency) ?? "USD"
        date = try c.decodeIfPresent(Date.self, forKey: .date) ?? .now
        store = try c.decodeIfPresent(String.self, forKey: .store) ?? "Other"
        details = try c.decodeIfPresent(String.self, forKey: .details) ?? ""
    }
}

@Observable
class Expenses {
    var items = [ExpenseItem]() {
        didSet {
            if let encoded = try? JSONEncoder().encode(items) {
                UserDefaults.standard.set(encoded, forKey: "Items")
            }
        }
    }
    
    init() {
        if let savedItems = UserDefaults.standard.data(forKey: "Items"),
           let decodedItems = try? JSONDecoder().decode([ExpenseItem].self, from: savedItems) {
            items = decodedItems
            return
        } else {
            items = []
        }
    }
}

struct ContentView: View {
    @State private var expenses = Expenses()
    @State private var showingAddExpense = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(expenses.items) { item in
                    HStack(spacing: 12) {
                        Text(item.amount < 10 ? "🟢" : item.amount < 100 ? "🟡" : "🔴")

                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(item.name)
                                    .font(.headline)
                                Spacer()
                                Text(item.amount, format: .currency(code: item.currency))
                                    .font(.headline)
                            }
                            
                            let isToday = Calendar.current.isDateInToday(item.date)
                            let isYear: Bool = Calendar.current.component(.year, from: item.date) == Calendar.current.component(.year, from: Date())

                            if isToday {
                                Text("\(item.date, format: .dateTime.hour().minute()) · \(item.store)")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            } else {
                                if isYear{
                                    Text("\(item.date, format: .dateTime.month().day()) · \(item.store)")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                else {
                                    Text("\(item.date, format: .dateTime.month().day().year()) · \(item.store)")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }


                        }
                    }
                    .padding(.vertical, 4)
                }
                .onDelete(perform: removeItems)
            }
            .navigationTitle("Expenses")
            .toolbar {
                Button("Add Expense", systemImage: "plus") {
                    showingAddExpense = true
                }
            }
            .sheet(isPresented: $showingAddExpense) {
                AddView(expenses: expenses)
            }
        }
    }

    func removeItems(_ offsets: IndexSet) {
        expenses.items.remove(atOffsets: offsets)
    }
}

#Preview {
    ContentView()
}
