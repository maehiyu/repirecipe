import Foundation

class RecipeRepositoryImpl: RecipeRepositoryProtocol {
    private let apiDataSource: RecipeAPIDataSource
    private let tokenCacheDataSource: TokenCacheDataSource
    
    init(
        apiDataSource: RecipeAPIDataSource,
        tokenCacheDataSource: TokenCacheDataSource
    ) {
        self.apiDataSource = apiDataSource
        self.tokenCacheDataSource = tokenCacheDataSource
    }
    
    // MARK: - Recipe Operations
    
    func fetchRecipes() async throws -> [RecipeSummary] {
        do {
            let token = getTestToken() // user-1固定トークン使用
            let recipeDTOs = try await apiDataSource.fetchRecipes(token: token)
            return recipeDTOs.map { $0.toDomainEntity() }
        } catch {
            throw error
        }
    }
    
    func fetchRecipeDetail(recipeID: String) async throws -> RecipeDetail {
        let token = getTestToken() // user-1固定トークン使用
        let recipeDTO = try await apiDataSource.fetchRecipeDetail(recipeID: recipeID, token: token)
        return recipeDTO.toDomainEntity()
    }
    
    func createRecipe(_ request: CreateRecipeRequest) async throws -> String {
        let token = getTestToken()
        
        // Domain Request → DTO変換
        let ingredientGroupDTOs = request.ingredientGroups.map { group in
            IngredientGroupDTO(
                groupId: group.groupID,
                title: group.title,
                orderNum: group.orderNum,
                ingredients: group.ingredients.map { ingredient in
                    IngredientDTO(
                        id: ingredient.id,
                        ingredientName: ingredient.ingredientName,
                        amount: ingredient.amount,
                        orderNum: ingredient.orderNum
                    )
                }
            )
        }
        
        let createRequestDTO = CreateRecipeRequestDTO(
            title: request.title,
            thumbnailUrl: request.thumbnailURL,
            mediaUrl: request.mediaURL,
            memo: request.memo,
            ingredientGroups: ingredientGroupDTOs
        )
        
        let response = try await apiDataSource.createRecipe(createRequestDTO, token: token)
        return response.message
    }
    
    func deleteRecipe(recipeID: String) async throws -> String {
        let token = getTestToken()
        let response = try await apiDataSource.deleteRecipe(recipeID: recipeID, token: token)
        return response.message
    }
    
    
    func updateRecipe(_ request: UpdateRecipeRequest) async throws -> RecipeDetail {
        let token = getTestToken()
        
        // Domain Request → DTO変換
        let ingredientGroupDTOs = request.ingredientGroups.map { group in
            IngredientGroupDTO(
                groupId: group.groupID,
                title: group.title,
                orderNum: group.orderNum,
                ingredients: group.ingredients.map { ingredient in
                    IngredientDTO(
                        id: ingredient.id,
                        ingredientName: ingredient.ingredientName,
                        amount: ingredient.amount,
                        orderNum: ingredient.orderNum
                    )
                }
            )
        }
        
        let updateRequestDTO = UpdateRecipeRequestDTO(
            recipeId: request.recipeID,
            title: request.title,
            thumbnailUrl: request.thumbnailURL,
            mediaUrl: request.mediaURL,
            memo: request.memo,
            ingredientGroups: ingredientGroupDTOs
        )
        
        let recipeDTO = try await apiDataSource.updateRecipe(updateRequestDTO, token: token)
        return recipeDTO.toDomainEntity()
    }
    
    // MARK: - Search Operations
    
    func searchRecipes(query: String) async throws -> [RecipeSummary] {
        let token = getTestToken()
        let recipeDTOs = try await apiDataSource.searchRecipes(query: query, token: token)
        return recipeDTOs.map { $0.toDomainEntity() }
    }
    
    func searchRecipesByTitle(title: String) async throws -> [RecipeSummary] {
        let token = getTestToken()
        let recipeDTOs = try await apiDataSource.searchRecipesByTitle(title: title, token: token)
        return recipeDTOs.map { $0.toDomainEntity() }
    }
    
    func searchRecipesByIngredient(ingredient: String) async throws -> [RecipeSummary] {
        let token = getTestToken()
        let recipeDTOs = try await apiDataSource.searchRecipesByIngredient(ingredient: ingredient, token: token)
        return recipeDTOs.map { $0.toDomainEntity() }
    }
    
    // MARK: - External Recipe Fetch Operations
    
    func fetchRecipeFromURL(_ urlString: String) async throws -> RecipeDetail {
        let token = getTestToken()
        let recipeDTO = try await apiDataSource.fetchRecipeFromURL(urlString, token: token)
        return recipeDTO.toDomainEntity()
    }
    
    
    // MARK: - Authentication Operations (テスト用簡易実装)
    
    func signIn(email: String, password: String) async throws -> AuthUser {
        // テスト用: user-1として固定ログイン
        let mockUser = AuthUser(
            userID: "user-1",
            email: email
        )
        return mockUser
    }
    
    func signUp(email: String, password: String) async throws {
        // テスト用: サインアップは成功として扱う
        // 実際の実装では、APIDataSourceのsignUpメソッドを呼び出す
        // try await apiDataSource.signUp(email: email, password: password)
        
        // 現在はダミー実装として、少し待機してから成功とする
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1秒待機
    }
    
    func signOut() async throws {
        try await tokenCacheDataSource.clearToken()
    }
    
    func getCurrentUser() async throws -> AuthUser? {
        // テスト用: user-1固定
        return AuthUser(
            userID: "user-1",
            email: "test@example.com"
        )
    }
    
    func deleteAccount() async throws {
        let token = getTestToken()
        try await apiDataSource.deleteAccount(token: token)
        try await tokenCacheDataSource.clearToken()
    }
    
    // MARK: - Private Helper Methods
    
    /// テスト用固定トークン
    private func getTestToken() -> String {
        return "user-1"
    }
}
