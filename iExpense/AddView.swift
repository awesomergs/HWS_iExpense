//
//  AddView.swift
//  iExpense
//
//  Created by Rohan George on 1/11/26.
//

import SwiftUI

struct AddView: View {
    @Environment(\.dismiss) var dismiss
    
    @State private var name: String = ""
    @State private var type: String = "Personal"
    @State private var amount: Double = 0.0
    
    var expenses: Expenses

    let types = ["Business", "Personal"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Name")) {
                    TextField("Name", text: $name)
                }
                
                Section(header: Text("Type")) {
                    Picker("Type", selection: $type) {
                        ForEach(types, id: \.self) {
                            Text($0)
                        }
                    }
                }
                
                Section(header: Text("Amount")) {
                    TextField("Amount", value:  $amount, format: .currency(code: "USD")).keyboardType(.decimalPad)
                }
                
            }.navigationTitle(Text("Add New Expense"))
                .toolbar{
                    Button("Save"){
                        let item = ExpenseItem(name: name, type: type, amount: amount)
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
