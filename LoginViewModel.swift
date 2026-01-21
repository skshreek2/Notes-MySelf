//
//  LoginViewModel.swift
//  UserApp
//
//  Created by Shrikant Korigeri on 13/01/26.
//

import Foundation

//ViewModel 
@MainActor
class LoginViewModel: ObservableObject {
    
    @Published var phoneNumber: String = "9876543210"
    @Published var state: LoginState = .idle
    @Published var isLoggedIn: Bool = false 
    
    private let service =  APIService.shared
    
    func login() async-> Bool {
        guard !phoneNumber.isEmpty else {
            state  = .error("Enter Phone Number")
                return false
        }
        state = .loading
        do {
            let loginResponse: LoginResponse = try await service.login(phoneNumber: phoneNumber)
            if success {
                state = .success
                isLoggedIn = true
                return true
            }else {
                state = .error("Invalid Phone Number")
            }
        }catch {
            state = .error(error.localizedDescription)
        }
        return false
    }
}
