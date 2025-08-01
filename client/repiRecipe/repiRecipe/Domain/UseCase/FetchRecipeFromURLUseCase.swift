import Foundation

class FetchRecipeFromURLUseCase {
    private let recipeRepository: RecipeRepositoryProtocol
    
    init(recipeRepository: RecipeRepositoryProtocol) {
        self.recipeRepository = recipeRepository
    }
    
    func execute(urlString: String) async throws -> RecipeDetail {
        // ビジネスルール：URLのバリデーション
        let trimmedURL = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedURL.isEmpty else {
            throw ValidationError.emptyURL
        }
        
        // 基本的なURL形式チェック
        guard trimmedURL.hasPrefix("http://") || trimmedURL.hasPrefix("https://") else {
            throw ValidationError.invalidURLFormat
        }
        
        // ビジネスルール：外部レシピ取得
        return try await recipeRepository.fetchRecipeFromURL(trimmedURL)
    }
}

