import Foundation

class CreateRecipeUseCase {
    private let recipeRepository: RecipeRepositoryProtocol
    
    init(recipeRepository: RecipeRepositoryProtocol) {
        self.recipeRepository = recipeRepository
    }
    
    func execute(_ request: CreateRecipeRequest) async throws -> String {
        // ビジネスルール：バリデーション
        try validateRecipeRequest(request)
        
        // レシピ作成実行
        return try await recipeRepository.createRecipe(request)
    }
    
    private func validateRecipeRequest(_ request: CreateRecipeRequest) throws {
        // ビジネスルール：タイトルは必須
        guard !request.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ValidationError.titleRequired
        }
        
        // ビジネスルール：材料グループは空でも可、但し材料がある場合は各材料にingredientNameが必須
        for group in request.ingredientGroups {
            for ingredient in group.ingredients {
                guard !ingredient.ingredientName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    throw ValidationError.ingredientNameRequired
                }
            }
        }
    }
}