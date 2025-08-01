import Foundation

protocol RecipeRepositoryProtocol {
    // MARK: - Recipe CRUD Operations
    
    /// レシピを一括取得
    /// GET /recipes
    func fetchRecipes() async throws -> [RecipeSummary]
    
    /// レシピ詳細取得
    /// GET /recipes/:id
    func fetchRecipeDetail(recipeID: String) async throws -> RecipeDetail
    
    /// レシピ削除
    /// DELETE /recipes/:id
    func deleteRecipe(recipeID: String) async throws -> String
    
    /// レシピ新規作成
    /// POST /recipes
    func createRecipe(_ request: CreateRecipeRequest) async throws -> String
    
    /// レシピ更新
    /// PUT /recipes
    func updateRecipe(_ request: UpdateRecipeRequest) async throws -> RecipeDetail
    
    // MARK: - Recipe Search Operations
    
    /// レシピ検索
    /// GET /recipes/search
    func searchRecipes(query: String) async throws -> [RecipeSummary]
    
    /// タイトルでレシピ検索
    /// GET /recipes/search?title=xxx
    func searchRecipesByTitle(title: String) async throws -> [RecipeSummary]
    
    /// 材料でレシピ検索
    /// GET /recipes/search?ingredients=xxx
    func searchRecipesByIngredient(ingredient: String) async throws -> [RecipeSummary]
    
    // MARK: - External Recipe Fetch Operations
    
    /// 外部URLからレシピ取得
    /// POST /recipes/fetch
    func fetchRecipeFromURL(_ urlString: String) async throws -> RecipeDetail
    
    
    // MARK: - Authentication Operations
    
    /// サインイン
    func signIn(email: String, password: String) async throws -> AuthUser
    
    /// サインアップ
    func signUp(email: String, password: String) async throws
    
    /// サインアウト
    func signOut() async throws
    
    /// 現在のユーザー取得
    func getCurrentUser() async throws -> AuthUser?
    
    /// アカウント削除
    /// DELETE /account
    func deleteAccount() async throws
}
