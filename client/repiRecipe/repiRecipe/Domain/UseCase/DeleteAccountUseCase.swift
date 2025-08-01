import Foundation

class DeleteAccountUseCase {
    private let recipeRepository: RecipeRepositoryProtocol
    
    init(recipeRepository: RecipeRepositoryProtocol) {
        self.recipeRepository = recipeRepository
    }
    
    func execute() async throws {
        // ビジネスルール：アカウント削除前の確認
        // 現在のユーザーが存在することを確認
        guard let _ = try await recipeRepository.getCurrentUser() else {
            throw ValidationError.userNotSignedIn
        }
        
        // ビジネスルール：アカウント削除実行
        // サーバー側でユーザーデータとレシピデータを削除
        try await recipeRepository.deleteAccount()
    }
}
