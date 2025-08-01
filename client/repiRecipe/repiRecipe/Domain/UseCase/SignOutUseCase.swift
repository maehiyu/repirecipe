import Foundation

class SignOutUseCase {
    private let recipeRepository: RecipeRepositoryProtocol
    
    init(recipeRepository: RecipeRepositoryProtocol) {
        self.recipeRepository = recipeRepository
    }
    
    func execute() async throws {
        // ビジネスルール：サインアウト処理
        // トークンクリア、ローカルデータクリアなどを実行
        try await recipeRepository.signOut()
    }
}