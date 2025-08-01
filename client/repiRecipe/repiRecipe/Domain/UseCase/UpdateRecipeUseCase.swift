import Foundation

class UpdateRecipeUseCase {
    private let recipeRepository: RecipeRepositoryProtocol
    
    init(recipeRepository: RecipeRepositoryProtocol) {
        self.recipeRepository = recipeRepository
    }
    
    func execute(_ request: UpdateRecipeRequest) async throws -> RecipeDetail {
        // ビジネスルール：更新リクエストのバリデーション
        try validateUpdateRequest(request)
        
        return try await recipeRepository.updateRecipe(request)
    }
    
    private func validateUpdateRequest(_ request: UpdateRecipeRequest) throws {
        // ビジネスルール：レシピIDは必須
        guard !request.recipeID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ValidationError.invalidRecipeID
        }
        
        // ビジネスルール：タイトルは必須
        guard !request.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ValidationError.titleRequired
        }
        
        // ビジネスルール：材料名の検証
        for group in request.ingredientGroups {
            for ingredient in group.ingredients {
                guard !ingredient.ingredientName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    throw ValidationError.ingredientNameRequired
                }
            }
        }
    }
}