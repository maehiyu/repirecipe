import SwiftUI

@MainActor
class RecipeListViewModel: ObservableObject {
    @Published var recipes: [RecipeSummary] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isShowingAlert = false
    @Published var searchText = ""
    
    private let getRecipeListUseCase: GetRecipeListUseCase
    private let searchRecipesUseCase: SearchRecipesUseCase
    private let deleteRecipeUseCase: DeleteRecipeUseCase
    
    init(
        getRecipeListUseCase: GetRecipeListUseCase,
        searchRecipesUseCase: SearchRecipesUseCase,
        deleteRecipeUseCase: DeleteRecipeUseCase
    ) {
        self.getRecipeListUseCase = getRecipeListUseCase
        self.searchRecipesUseCase = searchRecipesUseCase
        self.deleteRecipeUseCase = deleteRecipeUseCase
    }
    
    // MARK: - レシピ取得
    
    func loadRecipes() async {
        isLoading = true
        errorMessage = nil
        
        do {
            recipes = try await getRecipeListUseCase.execute()
        } catch {
            handleError(error)
        }
        
        isLoading = false
    }
    
    // MARK: - レシピ検索
    
    func searchRecipes() async {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            await loadRecipes()
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            recipes = try await searchRecipesUseCase.execute(query: searchText)
        } catch {
            handleError(error)
        }
        
        isLoading = false
    }
    
    // MARK: - リフレッシュ
    
    func refreshRecipes() async {
        await loadRecipes()
    }
    
    // MARK: - レシピ削除
    
    func deleteRecipe(recipeID: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            _ = try await deleteRecipeUseCase.execute(recipeID: recipeID)
            // 削除後、リストを再取得
            await loadRecipes()
        } catch {
            handleError(error)
        }
        
        isLoading = false
    }
    
    // MARK: - Error Handling
    
    private func handleError(_ error: Error) {
        if let validationError = error as? ValidationError {
            errorMessage = validationError.localizedDescription
        } else {
            errorMessage = "エラーが発生しました: \(error.localizedDescription)"
        }
        isShowingAlert = true
    }
    
    func clearError() {
        errorMessage = nil
        isShowingAlert = false
    }
    
    // MARK: - Computed Properties
    
    var hasRecipes: Bool {
        !recipes.isEmpty
    }
    
    var isSearching: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var displayRecipes: [RecipeSummary] {
        recipes
    }
}
