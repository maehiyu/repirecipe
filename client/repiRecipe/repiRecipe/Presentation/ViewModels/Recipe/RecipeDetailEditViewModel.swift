import SwiftUI

@MainActor
class RecipeDetailEditViewModel: ObservableObject {
    @Published var title: String = ""
    @Published var memo: String = ""
    @Published var thumbnailURL: String = ""
    @Published var mediaURL: String = ""
    @Published var ingredientGroups: [IngredientGroup] = []
    
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var errorMessage: String?
    @Published var isShowingAlert = false
    @Published var isShowingSaveSuccess = false
    
    private let updateRecipeUseCase: UpdateRecipeUseCase
    private let getRecipeDetailUseCase: GetRecipeDetailUseCase
    private let recipeId: String
    private var originalRecipe: RecipeDetail?
    
    init(
        recipeId: String,
        updateRecipeUseCase: UpdateRecipeUseCase,
        getRecipeDetailUseCase: GetRecipeDetailUseCase
    ) {
        self.recipeId = recipeId
        self.updateRecipeUseCase = updateRecipeUseCase
        self.getRecipeDetailUseCase = getRecipeDetailUseCase
    }
    
    // MARK: - レシピ詳細取得・編集データ設定
    
    func loadRecipeForEdit() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let recipe = try await getRecipeDetailUseCase.execute(recipeID: recipeId)
            originalRecipe = recipe
            setupEditingData(from: recipe)
        } catch {
            handleError(error)
        }
        
        isLoading = false
    }
    
    private func setupEditingData(from recipe: RecipeDetail) {
        title = recipe.title
        memo = recipe.memo ?? ""
        thumbnailURL = recipe.thumbnailURL ?? ""
        mediaURL = recipe.mediaURL ?? ""
        ingredientGroups = recipe.ingredientGroups
    }
    
    // MARK: - レシピ更新
    
    func updateRecipe() async {
        guard validateInput() else { return }
        
        isSaving = true
        errorMessage = nil
        
        do {
            let request = UpdateRecipeRequest(
                recipeID: recipeId,
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                thumbnailURL: thumbnailURL.isEmpty ? nil : thumbnailURL,
                mediaURL: mediaURL.isEmpty ? nil : mediaURL,
                memo: memo.isEmpty ? nil : memo,
                ingredientGroups: ingredientGroups
            )
            
            _ = try await updateRecipeUseCase.execute(request)
            isShowingSaveSuccess = true
            
        } catch {
            handleError(error)
        }
        
        isSaving = false
    }
    
    // MARK: - バリデーション
    
    private func validateInput() -> Bool {
        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errorMessage = "タイトルは必須です"
            isShowingAlert = true
            return false
        }
        
        if ingredientGroups.isEmpty {
            errorMessage = "材料は最低1つ必要です"
            isShowingAlert = true
            return false
        }
        
        return true
    }
    
    // MARK: - 材料グループ操作
    
    func addIngredientGroup() {
        let newGroup = IngredientGroup(
            groupID: "group-\(UUID().uuidString)",
            title: "材料グループ\(ingredientGroups.count + 1)",
            orderNum: ingredientGroups.count + 1,
            ingredients: []
        )
        ingredientGroups.append(newGroup)
    }
    
    func removeIngredientGroup(at index: Int) {
        guard index < ingredientGroups.count else { return }
        ingredientGroups.remove(at: index)
    }
    
    func addIngredient(to groupIndex: Int) {
        guard groupIndex < ingredientGroups.count else { return }
        
        let newIngredient = Ingredient(
            id: "ingredient-\(UUID().uuidString)",
            ingredientName: "",
            amount: "",
            orderNum: ingredientGroups[groupIndex].ingredients.count + 1
        )
        
        // IngredientGroupは不変なので、新しいインスタンスを作成
        let updatedIngredients = ingredientGroups[groupIndex].ingredients + [newIngredient]
        let updatedGroup = IngredientGroup(
            groupID: ingredientGroups[groupIndex].groupID,
            title: ingredientGroups[groupIndex].title,
            orderNum: ingredientGroups[groupIndex].orderNum,
            ingredients: updatedIngredients
        )
        ingredientGroups[groupIndex] = updatedGroup
    }
    
    func removeIngredient(from groupIndex: Int, at ingredientIndex: Int) {
        guard groupIndex < ingredientGroups.count,
              ingredientIndex < ingredientGroups[groupIndex].ingredients.count else { return }
        
        // IngredientGroupは不変なので、新しいインスタンスを作成
        var updatedIngredients = ingredientGroups[groupIndex].ingredients
        updatedIngredients.remove(at: ingredientIndex)
        let updatedGroup = IngredientGroup(
            groupID: ingredientGroups[groupIndex].groupID,
            title: ingredientGroups[groupIndex].title,
            orderNum: ingredientGroups[groupIndex].orderNum,
            ingredients: updatedIngredients
        )
        ingredientGroups[groupIndex] = updatedGroup
    }
    
    // MARK: - 変更検知
    
    func hasChanges() -> Bool {
        guard let original = originalRecipe else { return false }
        
        return title != original.title ||
               memo != (original.memo ?? "") ||
               thumbnailURL != (original.thumbnailURL ?? "") ||
               mediaURL != (original.mediaURL ?? "") ||
               !ingredientGroupsEqual(ingredientGroups, original.ingredientGroups)
    }
    
    private func ingredientGroupsEqual(_ lhs: [IngredientGroup], _ rhs: [IngredientGroup]) -> Bool {
        guard lhs.count == rhs.count else { return false }
        
        for (index, lhsGroup) in lhs.enumerated() {
            let rhsGroup = rhs[index]
            if lhsGroup.title != rhsGroup.title ||
               lhsGroup.ingredients.count != rhsGroup.ingredients.count {
                return false
            }
            
            for (ingredientIndex, lhsIngredient) in lhsGroup.ingredients.enumerated() {
                let rhsIngredient = rhsGroup.ingredients[ingredientIndex]
                if lhsIngredient.ingredientName != rhsIngredient.ingredientName ||
                   lhsIngredient.amount != rhsIngredient.amount {
                    return false
                }
            }
        }
        return true
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
    
    func clearSaveSuccess() {
        isShowingSaveSuccess = false
    }
    
    // MARK: - Computed Properties
    
    var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !ingredientGroups.isEmpty &&
        !isSaving
    }
    
    var saveButtonTitle: String {
        isSaving ? "保存中..." : "保存"
    }
    
    var hasValidIngredients: Bool {
        ingredientGroups.contains { group in
            group.ingredients.contains { ingredient in
                !ingredient.ingredientName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
        }
    }
}
