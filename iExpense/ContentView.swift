//
//  ContentView.swift
//  iExpense
//
//  Created by Rohan George on 1/10/26.
//

import Observation
import SwiftUI

@Observable //A 'macro' - Swifts way of rewriting our code for additional functionality. Can right click and go to 'expand macro'
class User{
    var firstName = "Bilbo"
    var lastName = "Baggins"
}

struct SecondView: View {
    @Environment(\.dismiss) var dismiss
    let name: String
    
    var body: some View{
        // Text("Hello, \(name)!")
        Button("Dismiss"){
            dismiss()
        }
    }
}

struct ContentView: View {
    @State private var user = User()
    @State private var showingSheet = false
    
    var body: some View {
        VStack{
            TextField("First Name:", text: $user.firstName)
                .padding(20)
            TextField("Last Name:", text: $user.lastName)
                .padding(20)
            
            Spacer()
            
            Button("Show Sheet"){
                showingSheet.toggle()
            }
            .sheet(isPresented: $showingSheet){
                SecondView(name: user.firstName + " " + user.lastName)
            }
        }
    }
}

#Preview {
    ContentView()
}
