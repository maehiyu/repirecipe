import SwiftUI

@MainActor
class RecipeDetailViewModel: ObservableObject {
    @Published var recipe: RecipeDetail?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isShowingAlert = false
    @Published var isDeleting = false
    @Published var isShowingDeleteConfirmation = false
    
    private let getRecipeDetailUseCase: GetRecipeDetailUseCase
    private let recipeId: String
    private let deleteRecipeUseCase: DeleteRecipeUseCase
    
    init(
        recipeId: String,
        getRecipeDetailUseCase: GetRecipeDetailUseCase,
        deleteRecipeUseCase: DeleteRecipeUseCase
    ) {
        self.recipeId = recipeId
        self.getRecipeDetailUseCase = getRecipeDetailUseCase
        self.deleteRecipeUseCase = deleteRecipeUseCase
    }
    
    
    func loadRecipeDetail() async {
        isLoading = true
        errorMessage = nil
        
        do {
            recipe = try await getRecipeDetailUseCase.execute(recipeID: recipeId)
        } catch {
            handleError(error)
        }
        
        isLoading = false
    }
    
    
    func refreshRecipeDetail() async {
        await loadRecipeDetail()
    }
    
    func deleteRecipe() async {
        isDeleting = true
        errorMessage = nil
        
        do {
            let message = try await deleteRecipeUseCase.execute(recipeID: recipeId)
        } catch {
            handleError(error)
        }
        
        isDeleting = false
    }
    
    func showDeleteConfirmation() {
        isShowingDeleteConfirmation = true
    }
    
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
    
    
    var hasRecipe: Bool {
        recipe != nil
    }
    
    var recipeTitle: String {
        recipe?.title ?? ""
    }
    
    var thumbnailURL: String? {
        recipe?.thumbnailURL
    }
    
    var mediaURL: String? {
        recipe?.mediaURL
    }
    
    var memo: String? {
        recipe?.memo
    }
    
    var ingredientGroups: [IngredientGroup] {
        recipe?.ingredientGroups ?? []
    }
    
    var createdAt: Date? {
        recipe?.createdAt
    }
    
    var lastCookedAt: Date? {
        recipe?.lastCookedAt
    }
}
