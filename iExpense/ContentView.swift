import Observation
import SwiftUI

struct ExpenseItem: Identifiable, Codable {
    var id = UUID()
    let name: String
    let type: String
    let amount: Double
    let currency: String

    enum CodingKeys: String, CodingKey {
        case id, name, type, amount, currency
    }

    init(id: UUID = UUID(), name: String, type: String, amount: Double, currency: String) {
        self.id = id
        self.name = name
        self.type = type
        self.amount = amount
        self.currency = currency
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try c.decode(String.self, forKey: .name)
        type = try c.decode(String.self, forKey: .type)
        amount = try c.decode(Double.self, forKey: .amount)

        // ✅ If older saved data doesn’t have "currency", default to USD
        currency = try c.decodeIfPresent(String.self, forKey: .currency) ?? "USD"
    }
}


@Observable
class Expenses{
    var items = [ExpenseItem](){
        didSet {
            if let encoded = try? JSONEncoder().encode(items){
                 UserDefaults.standard.set(encoded, forKey: "Items")
            }
        }
    }

    init() {
        if let savedItems = UserDefaults.standard.data(forKey: "Items"),
           let decodedItems = try? JSONDecoder().decode([ExpenseItem].self, from: savedItems){
            items = decodedItems
            return
        }else{
            items = []
        }
    }
}

struct ContentView: View {
    @State private var expenses = Expenses()
    @State private var showingAddExpense = false


    var body: some View {
        NavigationStack{
            List{
                ForEach(expenses.items) { item in
                    HStack{
                        Text(item.amount < 10 ? "🟢" : item.amount < 100 ? "🟡" : "🔴")
                        VStack(alignment: .leading){
                            Text(item.name).font(.headline)
                            Text(item.type)
                        }

                        Spacer()

                        Text(item.amount, format: .currency(code: item.currency))

                    }
                }.onDelete(perform: removeItems)
            }
            .navigationTitle("Expenses")
            .toolbar {
                    Button("Add Expense", systemImage: "plus"){
                        showingAddExpense = true
                    }
                }
            .sheet(isPresented: $showingAddExpense) {
                AddView(expenses: expenses)
            }
        }
    }

    func removeItems(_ offsets: IndexSet){
        expenses.items.remove(atOffsets: offsets)
    }
}

#Preview {
    ContentView()
}

