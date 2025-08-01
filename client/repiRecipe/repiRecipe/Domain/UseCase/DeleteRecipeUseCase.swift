import Foundation

class DeleteRecipeUseCase {
    private let recipeRepository: RecipeRepositoryProtocol
    
    init(recipeRepository: RecipeRepositoryProtocol) {
        self.recipeRepository = recipeRepository
    }
    
    func execute(recipeID: String) async throws -> String {
        // ビジネスルール：レシピIDのバリデーション
        guard !recipeID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ValidationError.invalidRecipeID
        }
        
        // レシピ削除実行
        return try await recipeRepository.deleteRecipe(recipeID: recipeID)
    }
}