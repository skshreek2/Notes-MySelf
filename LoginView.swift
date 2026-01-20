//
//  ContentView.swift
//  UserApp
//
//  Created by Shrikant Korigeri on 13/01/26.
//


//View
import SwiftUI

struct LoginView: View {
    
    @Binding var isLoggedIn: Bool
    @StateObject private var viewModel = LoginViewModel()
    @State private var path = NavigationPath()
    
    
    var body: some View {
        NavigationStack(path: $path){
            VStack(spacing: 20) {
                TextField("Phone Number (e.g., 9087654321)", text: $viewModel.phoneNumber)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.phonePad)
                
                Button("Login"){
                    Task {
                        await viewModel.login()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.state == .loading)
                
                if case .loading = viewModel.state {
                    ProgressView("Verifying...")
                }
                
                if case let .error(message) = viewModel.state {
                    Text(message)
                        .foregroundStyle(.red)
                }
            }
            .padding()
            .navigationDestination(isPresented: $viewModel.isLoggedIn){
                
                DashboardView()
            }
        }
       
    }
}

#Preview {
    LoginView()
}
