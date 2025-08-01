import Foundation

class SearchRecipesUseCase {
    private let recipeRepository: RecipeRepositoryProtocol
    
    init(recipeRepository: RecipeRepositoryProtocol) {
        self.recipeRepository = recipeRepository
    }
    
    /// タイトルでレシピを検索
    func searchByTitle(query: String) async throws -> [RecipeSummary] {
        // ビジネスルール：検索クエリのバリデーション
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedQuery.isEmpty else {
            throw ValidationError.emptyQuery
        }
        
        guard trimmedQuery.count >= 2 else {
            throw ValidationError.searchQueryTooShort
        }
        
        let recipes = try await recipeRepository.searchRecipesByTitle(title: trimmedQuery)
        
        // ビジネスルール：検索結果のソート（関連度順→作成日時順）
        return recipes.sorted { lhs, rhs in
            // タイトルに完全一致するものを優先
            let lhsExactMatch = lhs.title.localizedCaseInsensitiveContains(trimmedQuery)
            let rhsExactMatch = rhs.title.localizedCaseInsensitiveContains(trimmedQuery)
            
            if lhsExactMatch != rhsExactMatch {
                return lhsExactMatch
            }
            
            // 次に作成日時順（新しい順）
            return lhs.createdAt > rhs.createdAt
        }
    }
    
    /// 材料でレシピを検索
    func searchByIngredient(ingredient: String) async throws -> [RecipeSummary] {
        // ビジネスルール：検索クエリのバリデーション
        let trimmedIngredient = ingredient.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedIngredient.isEmpty else {
            throw ValidationError.emptyQuery
        }
        
        guard trimmedIngredient.count >= 1 else {
            throw ValidationError.searchQueryTooShort
        }
        
        let recipes = try await recipeRepository.searchRecipesByIngredient(ingredient: trimmedIngredient)
        
        // ビジネスルール：材料検索結果のソート
        return recipes.sorted { lhs, rhs in
            // 材料名に完全一致するものを優先
            let lhsExactMatch = lhs.ingredientsName.contains { ingredientName in
                ingredientName.localizedCaseInsensitiveContains(trimmedIngredient)
            }
            let rhsExactMatch = rhs.ingredientsName.contains { ingredientName in
                ingredientName.localizedCaseInsensitiveContains(trimmedIngredient)
            }
            
            if lhsExactMatch != rhsExactMatch {
                return lhsExactMatch
            }
            
            // マッチした材料の数で優先度を決定
            let lhsMatchCount = lhs.ingredientsName.filter { ingredientName in
                ingredientName.localizedCaseInsensitiveContains(trimmedIngredient)
            }.count
            let rhsMatchCount = rhs.ingredientsName.filter { ingredientName in
                ingredientName.localizedCaseInsensitiveContains(trimmedIngredient)
            }.count
            
            if lhsMatchCount != rhsMatchCount {
                return lhsMatchCount > rhsMatchCount
            }
            
            // 次に作成日時順（新しい順）
            return lhs.createdAt > rhs.createdAt
        }
    }
    
    // MARK: - 後方互換性のため、既存のexecuteメソッドを維持
    @available(*, deprecated, message: "Use searchByTitle or searchByIngredient instead")
    func execute(query: String) async throws -> [RecipeSummary] {
        return try await searchByTitle(query: query)
    }
}
