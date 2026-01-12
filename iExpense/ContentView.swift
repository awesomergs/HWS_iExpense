//
//  ContentView.swift
//  iExpense
//
//  Created by Rohan George on 1/10/26.
//

import Observation
import SwiftUI

struct ExpenseItem: Identifiable, Codable {
    var id = UUID()
    let name: String
    let type: String
    let amount: Double
    let currency: String
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

