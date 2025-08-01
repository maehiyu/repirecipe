import Foundation

class SignInUseCase {
    private let recipeRepository: RecipeRepositoryProtocol
    
    init(recipeRepository: RecipeRepositoryProtocol) {
        self.recipeRepository = recipeRepository
    }
    
    func execute(email: String, password: String) async throws -> AuthUser {
        // ビジネスルール：認証情報のバリデーション
        try validateSignInCredentials(email: email, password: password)
        
        return try await recipeRepository.signIn(email: email, password: password)
    }
    
    private func validateSignInCredentials(email: String, password: String) throws {
        // ビジネスルール：メールアドレスのバリデーション
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty else {
            throw ValidationError.emptyEmail
        }
        
        guard trimmedEmail.contains("@") && trimmedEmail.contains(".") else {
            throw ValidationError.invalidEmailFormat
        }
        
        // ビジネスルール：パスワードのバリデーション
        guard !password.isEmpty else {
            throw ValidationError.emptyPassword
        }
        
        guard password.count >= 6 else {
            throw ValidationError.passwordTooShort
        }
    }
}
