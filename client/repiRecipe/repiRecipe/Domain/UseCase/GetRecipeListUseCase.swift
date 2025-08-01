import Foundation

class GetRecipeListUseCase {
    private let recipeRepository: RecipeRepositoryProtocol
    
    init(recipeRepository: RecipeRepositoryProtocol) {
        self.recipeRepository = recipeRepository
    }
    
    func execute() async throws -> [RecipeSummary] {
        let recipes = try await recipeRepository.fetchRecipes()
        
        // ビジネスルール：作成日時順でソート（新しい順）
        return recipes.sorted { $0.createdAt > $1.createdAt }
    }
}
