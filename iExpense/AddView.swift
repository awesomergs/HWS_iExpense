//
//  AddView.swift
//  iExpense
//
//  Created by Rohan George on 1/11/26.
//

import SwiftUI

enum Currency: String, CaseIterable, Identifiable {
    case usd = "USD"
    case inr = "INR"
    case gbp = "GBP"
    case thb = "THB"
    
    var id: String { self.rawValue }
}

struct AddView: View {
    @Environment(\.dismiss) var dismiss
    
    @State private var name: String = ""
    @State private var type: String = "Personal"
    @State private var amount: Double = 0.0
    @State private var currency: String = "USD"

    
    var expenses: Expenses

    let types = ["Business", "Personal"]
    
    var body: some View {
        NavigationStack {
            Form {
                    TextField("Name", text: $name)
               
                    Picker("Type:", selection: $type) {
                        ForEach(types, id: \.self) {
                            Text($0)
                        }
                    }
                
                HStack{
                    Section(header: Text("Amount:")) {
                        TextField("Amount", value:  $amount, format: .currency(code: currency)).keyboardType(.decimalPad)
                    }
                    Picker("Currency", selection: $currency) {
                        ForEach(Currency.allCases) { currency in
                            Text(currency.rawValue).tag(currency)
                        }
                    }.labelsHidden()
                    
                }
                
            }.navigationTitle(Text("Add New Expense"))
                .toolbar{
                    Button("Save"){
                        let item = ExpenseItem(name: name, type: type, amount: amount, currency: currency)
                        expenses.items.append(item)
                        dismiss()
                    }
                }
        }
    }
}

#Preview {
    AddView(expenses: Expenses())
}
