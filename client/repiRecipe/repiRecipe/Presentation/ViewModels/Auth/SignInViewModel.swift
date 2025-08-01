import SwiftUI

@MainActor
class SignInViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var errorMessage: String?
    @Published var isShowingAlert = false
    @Published var isPasswordVisible = false
    
    private let authViewModel: AuthViewModel
    
    init(authViewModel: AuthViewModel) {
        self.authViewModel = authViewModel
    }
    
    // MARK: - サインイン処理
    
    func signIn() async {
        guard validateInput() else { return }
        
        await authViewModel.signIn(email: email, password: password)
        
        // AuthViewModelのエラーを監視
        if let error = authViewModel.errorMessage {
            errorMessage = error
            isShowingAlert = true
        }
    }
    
    // MARK: - バリデーション
    
    private func validateInput() -> Bool {
        if email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errorMessage = "メールアドレスを入力してください"
            isShowingAlert = true
            return false
        }
        
        if !isValidEmail(email) {
            errorMessage = "有効なメールアドレスを入力してください"
            isShowingAlert = true
            return false
        }
        
        if password.isEmpty {
            errorMessage = "パスワードを入力してください"
            isShowingAlert = true
            return false
        }
        
        return true
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    // MARK: - UI制御
    
    func togglePasswordVisibility() {
        isPasswordVisible.toggle()
    }
    
    func clearError() {
        errorMessage = nil
        isShowingAlert = false
        authViewModel.clearError()
    }
    
    func clearForm() {
        email = ""
        password = ""
        errorMessage = nil
        isPasswordVisible = false
    }
    
    // MARK: - Computed Properties
    
    var canSignIn: Bool {
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !password.isEmpty &&
        !authViewModel.isLoading
    }
    
    var signInButtonTitle: String {
        if authViewModel.isLoading {
            return "サインイン中..."
        } else {
            return "サインイン"
        }
    }
    
    var isLoading: Bool {
        authViewModel.isLoading
    }
}
