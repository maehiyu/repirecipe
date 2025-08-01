import SwiftUI

@MainActor
class SignUpViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isShowingAlert = false
    @Published var isPasswordVisible = false
    @Published var isShowingSuccess = false
    
    private let signUpUseCase: SignUpUseCase
    
    init(signUpUseCase: SignUpUseCase) {
        self.signUpUseCase = signUpUseCase
    }
    
    // MARK: - サインアップ処理
    
    func signUp() async {
        guard validateInput() else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await signUpUseCase.execute(email: email, password: password)
            isShowingSuccess = true
            clearForm()
        } catch {
            handleError(error)
        }
        
        isLoading = false
    }
    
    // MARK: - バリデーション
    
    private func validateInput() -> Bool {
        // メールアドレスチェック
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
        
        // パスワードチェック
        if password.isEmpty {
            errorMessage = "パスワードを入力してください"
            isShowingAlert = true
            return false
        }
        
        if password.count < 8 {
            errorMessage = "パスワードは8文字以上で入力してください"
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
    }
    
    func clearForm() {
        email = ""
        password = ""
        errorMessage = nil
        isPasswordVisible = false
    }
    
    func clearSuccessState() {
        isShowingSuccess = false
    }
    
    // MARK: - Error Handling
    
    private func handleError(_ error: Error) {
        if let validationError = error as? ValidationError {
            errorMessage = validationError.localizedDescription
        } else if let authError = error as? AuthError {
            errorMessage = authError.localizedDescription
        } else {
            errorMessage = "アカウント作成に失敗しました: \(error.localizedDescription)"
        }
        isShowingAlert = true
    }
    
    // MARK: - Computed Properties
    
    var canSignUp: Bool {
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !password.isEmpty &&
        password.count >= 8 &&
        !isLoading
    }
    
    var signUpButtonTitle: String {
        isLoading ? "アカウント作成中..." : "アカウント作成"
    }
    
    var passwordStrength: PasswordStrength {
        if password.isEmpty {
            return .empty
        } else if password.count < 8 {
            return .weak
        } else if password.count >= 8 && containsNumberAndLetter {
            return .strong
        } else {
            return .medium
        }
    }
    
    private var containsNumberAndLetter: Bool {
        let hasNumber = password.rangeOfCharacter(from: .decimalDigits) != nil
        let hasLetter = password.rangeOfCharacter(from: .letters) != nil
        return hasNumber && hasLetter
    }
}

enum PasswordStrength {
    case empty
    case weak
    case medium
    case strong
    
    var description: String {
        switch self {
        case .empty:
            return ""
        case .weak:
            return "弱い"
        case .medium:
            return "普通"
        case .strong:
            return "強い"
        }
    }
    
    var color: Color {
        switch self {
        case .empty:
            return .gray
        case .weak:
            return .red
        case .medium:
            return .orange
        case .strong:
            return .green
        }
    }
}
