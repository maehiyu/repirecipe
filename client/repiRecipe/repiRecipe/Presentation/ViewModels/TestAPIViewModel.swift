import SwiftUI

@MainActor
class TestAPIViewModel: ObservableObject {
    @Published var testResult: String = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isShowingAlert = false
    
    private let getRecipeListUseCase: GetRecipeListUseCase
    private let createRecipeUseCase: CreateRecipeUseCase
    
    init() {
        // 依存関係を手動で注入
        let apiDataSource = RecipeAPIDataSource()
        let tokenCacheDataSource = TokenCacheDataSource()
        let recipeRepository: RecipeRepositoryProtocol = RecipeRepositoryImpl(
            apiDataSource: apiDataSource,
            tokenCacheDataSource: tokenCacheDataSource
        )
        
        // Use Caseの初期化
        self.getRecipeListUseCase = GetRecipeListUseCase(recipeRepository: recipeRepository)
        self.createRecipeUseCase = CreateRecipeUseCase(recipeRepository: recipeRepository)
    }
    
    func testFetchRecipes() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Use Caseを使用（ビジネスロジックは Use Case に委任）
            let recipes = try await getRecipeListUseCase.execute()
            
            testResult = "取得成功: \(recipes.count)件のレシピ\n\n" +
                        recipes.prefix(3).map { "・\($0.title)" }.joined(separator: "\n")
        } catch {
            errorMessage = "エラー: \(error.localizedDescription)"
            isShowingAlert = true
        }
        
        isLoading = false
    }
    
    func testCreateRecipe() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let createRequest = CreateRecipeRequest(
                title: "テストレシピ from iOS",
                thumbnailURL: nil,
                mediaURL: nil,
                memo: "APIテスト用のレシピです",
                ingredientGroups: [
                    IngredientGroup(
                        groupID: "group-1",
                        title: "メイン食材",
                        orderNum: 1,
                        ingredients: [
                            Ingredient(
                                id: "ingredient-1",
                                ingredientName: "トマト",
                                amount: "2個",
                                orderNum: 1
                            ),
                            Ingredient(
                                id: "ingredient-2",
                                ingredientName: "玉ねぎ",
                                amount: "1個",
                                orderNum: 2
                            )
                        ]
                    ),
                    IngredientGroup(
                        groupID: "group-2",
                        title: "調味料",
                        orderNum: 2,
                        ingredients: [
                            Ingredient(
                                id: "ingredient-3",
                                ingredientName: "塩",
                                amount: "適量",
                                orderNum: 1
                            ),
                            Ingredient(
                                id: "ingredient-4",
                                ingredientName: "胡椒",
                                amount: "少々",
                                orderNum: 2
                            )
                        ]
                    )
                ]
            )
            
            // Use Caseを使用（バリデーションロジックも Use Case に委任）
            let message = try await createRecipeUseCase.execute(createRequest)
            
            testResult = "作成成功: \(message)"
        } catch {
            errorMessage = "エラー: \(error.localizedDescription)"
            isShowingAlert = true
        }
        
        isLoading = false
    }
    
    func clearError() {
        errorMessage = nil
        isShowingAlert = false
    }
}
