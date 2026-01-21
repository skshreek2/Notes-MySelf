  func login() async-> Bool {
        guard !phoneNumber.isEmpty else {
            state  = .error("Enter Phone Number")
                return false
        }
        state = .loading
        do {
            let success = try await service.login(phoneNumber: phoneNumber)
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
