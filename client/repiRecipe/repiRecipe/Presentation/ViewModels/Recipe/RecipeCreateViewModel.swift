import SwiftUI

@MainActor
class RecipeCreateViewModel: ObservableObject {
    @Published var title: String = ""
    @Published var memo: String = ""
    @Published var thumbnailURL: String = ""
    @Published var mediaURL: String = ""
    @Published var ingredientGroups: [IngredientGroup] = []
    
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var errorMessage: String?
    @Published var isShowingAlert = false
    @Published var isShowingCreateSuccess = false
    @Published var createdRecipeID: String?
    
    private let createRecipeUseCase: CreateRecipeUseCase
    
    init(createRecipeUseCase: CreateRecipeUseCase) {
        self.createRecipeUseCase = createRecipeUseCase
        setupInitialIngredientGroup()
    }
    
    // MARK: - 初期設定
    
    private func setupInitialIngredientGroup() {
        let initialGroup = IngredientGroup(
            groupID: "group-\(UUID().uuidString)",
            title: "材料",
            orderNum: 1,
            ingredients: [createNewIngredient(orderNum: 1)]
        )
        ingredientGroups = [initialGroup]
    }
    
    // MARK: - レシピ作成
    
    func createRecipe() async {
        guard validateInput() else { return }
        
        isSaving = true
        errorMessage = nil
        
        do {
            let request = CreateRecipeRequest(
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                thumbnailURL: thumbnailURL.isEmpty ? nil : thumbnailURL,
                mediaURL: mediaURL.isEmpty ? nil : mediaURL,
                memo: memo.isEmpty ? nil : memo,
                ingredientGroups: getValidIngredientGroups()
            )
            
            let recipeID = try await createRecipeUseCase.execute(request)
            createdRecipeID = recipeID
            isShowingCreateSuccess = true
            
        } catch {
            handleError(error)
        }
        
        isSaving = false
    }
    
    // MARK: - バリデーション
    
    private func validateInput() -> Bool {
        // タイトルの検証
        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errorMessage = "タイトルは必須です"
            isShowingAlert = true
            return false
        }
        
        // 有効な材料があるかチェック
        let validGroups = getValidIngredientGroups()
        if validGroups.isEmpty || validGroups.allSatisfy({ $0.ingredients.isEmpty }) {
            errorMessage = "材料は最低1つ必要です"
            isShowingAlert = true
            return false
        }
        
        // 各材料の名前が入力されているかチェック
        for group in validGroups {
            for ingredient in group.ingredients {
                if ingredient.ingredientName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    errorMessage = "材料名は必須です"
                    isShowingAlert = true
                    return false
                }
            }
        }
        
        return true
    }
    
    private func getValidIngredientGroups() -> [IngredientGroup] {
        return ingredientGroups.compactMap { group in
            let validIngredients = group.ingredients.filter {
                !$0.ingredientName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
            
            guard !validIngredients.isEmpty else { return nil }
            
            return IngredientGroup(
                groupID: group.groupID,
                title: group.title,
                orderNum: group.orderNum,
                ingredients: validIngredients
            )
        }
    }
    
    // MARK: - 材料グループ操作
    
    func addIngredientGroup() {
        let newGroup = IngredientGroup(
            groupID: "group-\(UUID().uuidString)",
            title: "材料グループ\(ingredientGroups.count + 1)",
            orderNum: ingredientGroups.count + 1,
            ingredients: [createNewIngredient(orderNum: 1)]
        )
        ingredientGroups.append(newGroup)
    }
    
    func removeIngredientGroup(at index: Int) {
        guard index < ingredientGroups.count else { return }
        ingredientGroups.remove(at: index)
        
        // グループが空になったら初期グループを追加
        if ingredientGroups.isEmpty {
            setupInitialIngredientGroup()
        }
    }
    
    func updateIngredientGroupTitle(at groupIndex: Int, title: String) {
        guard groupIndex < ingredientGroups.count else { return }
        
        let updatedGroup = IngredientGroup(
            groupID: ingredientGroups[groupIndex].groupID,
            title: title.isEmpty ? "材料" : title,
            orderNum: ingredientGroups[groupIndex].orderNum,
            ingredients: ingredientGroups[groupIndex].ingredients
        )
        ingredientGroups[groupIndex] = updatedGroup
    }
    
    // MARK: - 材料操作
    
    func addIngredient(to groupIndex: Int) {
        guard groupIndex < ingredientGroups.count else { return }
        
        let newIngredient = createNewIngredient(
            orderNum: ingredientGroups[groupIndex].ingredients.count + 1
        )
        
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
        
        var updatedIngredients = ingredientGroups[groupIndex].ingredients
        updatedIngredients.remove(at: ingredientIndex)
        
        // 材料が空になったら1つ追加
        if updatedIngredients.isEmpty {
            updatedIngredients.append(createNewIngredient(orderNum: 1))
        }
        
        let updatedGroup = IngredientGroup(
            groupID: ingredientGroups[groupIndex].groupID,
            title: ingredientGroups[groupIndex].title,
            orderNum: ingredientGroups[groupIndex].orderNum,
            ingredients: updatedIngredients
        )
        ingredientGroups[groupIndex] = updatedGroup
    }
    
    func updateIngredient(groupIndex: Int, ingredientIndex: Int, name: String, amount: String) {
        guard groupIndex < ingredientGroups.count,
              ingredientIndex < ingredientGroups[groupIndex].ingredients.count else { return }
        
        var updatedIngredients = ingredientGroups[groupIndex].ingredients
        let ingredient = updatedIngredients[ingredientIndex]
        
        let updatedIngredient = Ingredient(
            id: ingredient.id,
            ingredientName: name,
            amount: amount.isEmpty ? nil : amount,
            orderNum: ingredient.orderNum
        )
        
        updatedIngredients[ingredientIndex] = updatedIngredient
        
        let updatedGroup = IngredientGroup(
            groupID: ingredientGroups[groupIndex].groupID,
            title: ingredientGroups[groupIndex].title,
            orderNum: ingredientGroups[groupIndex].orderNum,
            ingredients: updatedIngredients
        )
        ingredientGroups[groupIndex] = updatedGroup
    }
    
    private func createNewIngredient(orderNum: Int) -> Ingredient {
        return Ingredient(
            id: "ingredient-\(UUID().uuidString)",
            ingredientName: "",
            amount: nil,
            orderNum: orderNum
        )
    }
    
    // MARK: - フォームリセット
    
    func resetForm() {
        title = ""
        memo = ""
        thumbnailURL = ""
        mediaURL = ""
        createdRecipeID = nil
        setupInitialIngredientGroup()
        clearError()
    }
    
    // MARK: - 入力チェック
    
    func hasContent() -> Bool {
        let hasTitle = !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasMemo = !memo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasThumbnail = !thumbnailURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasMedia = !mediaURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasIngredients = ingredientGroups.contains { group in
            group.ingredients.contains { !$0.ingredientName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        }
        
        return hasTitle || hasMemo || hasThumbnail || hasMedia || hasIngredients
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
    
    func clearSuccess() {
        isShowingCreateSuccess = false
        createdRecipeID = nil
    }
}
