import Foundation

class GetRecipeDetailUseCase {
    private let recipeRepository: RecipeRepositoryProtocol
    
    init(recipeRepository: RecipeRepositoryProtocol) {
        self.recipeRepository = recipeRepository
    }
    
    func execute(recipeID: String) async throws -> RecipeDetail {
        // ビジネスルール：レシピIDのバリデーション
        guard !recipeID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ValidationError.invalidRecipeID
        }
        
        return try await recipeRepository.fetchRecipeDetail(recipeID: recipeID)
    }
}
