import Foundation

class SignUpUseCase {
    private let recipeRepository: RecipeRepositoryProtocol
    
    init(recipeRepository: RecipeRepositoryProtocol) {
        self.recipeRepository = recipeRepository
    }
    
    func execute(email: String, password: String) async throws {
        // ビジネスルール：バリデーション
        try validateSignUpRequest(email: email, password: password)
        
        // サインアップ実行
        try await recipeRepository.signUp(email: email, password: password)
    }
    
    private func validateSignUpRequest(email: String, password: String) throws {
        // ビジネスルール：メールアドレスは必須
        guard !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ValidationError.emailRequired
        }
        
        // ビジネスルール：パスワードは必須かつ8文字以上
        guard !password.isEmpty else {
            throw ValidationError.passwordRequired
        }
        
        guard password.count >= 8 else {
            throw ValidationError.passwordTooShort
        }
        
        // ビジネスルール：メールアドレス形式チェック
        guard isValidEmail(email) else {
            throw ValidationError.invalidEmailFormat
        }
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
}