import Observation
import SwiftUI

// ✅ NEW: categories with emoji
enum ExpenseCategory: String, CaseIterable, Identifiable, Codable {
    case food = "Food"
    case transport = "Transport"
    case entertainment = "Entertainment"
    case clothes = "Clothes"
    case gift = "Gift"
    case education = "Education / Schoolwork"
    case health = "Health"
    case home = "Home / Living"
    case fees = "Fees & Charges"
    case videoGames = "Video Games"
    case projects = "Projects"
    case other = "Other"

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .food: return "🍽️"
        case .transport: return "🚗"
        case .entertainment: return "🎟️"
        case .clothes: return "👕"
        case .gift: return "🎁"
        case .education: return "📚"
        case .health: return "🩺"
        case .home: return "🏠"
        case .fees: return "💸"
        case .videoGames: return "🎮"
        case .projects: return "🛠️"
        case .other: return "📦"
        }
    }

    // Backward-compat mapping for old saved values like "Business"/"Personal"
    static func fromLegacyTypeString(_ s: String) -> ExpenseCategory {
        let trimmed = s.trimmingCharacters(in: .whitespacesAndNewlines)

        // If it matches one of our rawValues exactly, use it.
        if let exact = ExpenseCategory(rawValue: trimmed) { return exact }

        // Handle old app values
        switch trimmed.lowercased() {
        case "business", "personal":
            return .other
        default:
            return .other
        }
    }
}

struct ExpenseItem: Identifiable, Codable {
    var id = UUID()
    let name: String

    // ✅ CHANGED: now category, but stored under "type" key for backward compatibility
    let category: ExpenseCategory

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
        category: ExpenseCategory,
        amount: Double,
        currency: String,
        date: Date = .now,
        store: String,
        details: String = ""
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.amount = amount
        self.currency = currency
        self.date = date
        self.store = store
        self.details = details
    }

    // ✅ Manual encode so we keep using the "type" key (migration-safe)
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(name, forKey: .name)
        try c.encode(category.rawValue, forKey: .type)
        try c.encode(amount, forKey: .amount)
        try c.encode(currency, forKey: .currency)
        try c.encode(date, forKey: .date)
        try c.encode(store, forKey: .store)
        try c.encode(details, forKey: .details)
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try c.decode(String.self, forKey: .name)

        // ✅ Backward compatible decoding: old "type" strings become a category
        let decodedType = try c.decodeIfPresent(String.self, forKey: .type) ?? "Other"
        category = ExpenseCategory.fromLegacyTypeString(decodedType)

        amount = try c.decode(Double.self, forKey: .amount)

        // Backward compatible defaults
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
    
    var sortedItems: [ExpenseItem] {
        expenses.items.sorted { $0.date > $1.date }
    }


    var body: some View {
        NavigationStack {
            List {
                ForEach(sortedItems) { item in
                    HStack(spacing: 12) {
                        Text(item.category.emoji)
                            .font(.title3)

                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(item.name)
                                    .font(.headline)
                                Spacer()
                                Text(item.amount, format: .currency(code: item.currency))
                                    .font(.headline)
                            }

                            let isToday = Calendar.current.isDateInToday(item.date)
                            let isYear: Bool = Calendar.current.component(.year, from: item.date) ==
                                               Calendar.current.component(.year, from: Date())

                            if isToday {
                                Text("\(item.date, format: .dateTime.hour().minute()) · \(item.store)")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            } else {
                                if isYear {
                                    Text("\(item.date, format: .dateTime.month().day()) · \(item.store)")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                } else {
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
