import Foundation

class RecipeAPIDataSource {
    private let networkClient: NetworkClient
    private let baseURL: String
    
    init(networkClient: NetworkClient = NetworkClient(), baseURL: String = "http://localhost:8080") {
        self.networkClient = networkClient
        self.baseURL = baseURL
    }
    
    // MARK: - Recipe Operations
    
    /// レシピを一括取得
    /// GET /recipes
    func fetchRecipes(token: String) async throws -> [RecipeSummaryDTO] {
        return try await networkClient.request(
            url: "\(baseURL)/recipes",
            method: .GET,
            headers: ["Authorization": "Bearer \(token)"],
            responseType: [RecipeSummaryDTO].self
        )
    }
    
    /// レシピ詳細取得
    /// GET /recipes/:id
    func fetchRecipeDetail(recipeID: String, token: String) async throws -> RecipeDetailDTO {
        return try await networkClient.request(
            url: "\(baseURL)/recipes/\(recipeID)",
            method: .GET,
            headers: ["Authorization": "Bearer \(token)"],
            responseType: RecipeDetailDTO.self
        )
    }
    
    /// レシピ削除
    /// DELETE /recipes/:id
    func deleteRecipe(recipeID: String, token: String) async throws -> MessageResponseDTO {
        return try await networkClient.request(
            url: "\(baseURL)/recipes/\(recipeID)",
            method: .DELETE,
            headers: ["Authorization": "Bearer \(token)"],
            responseType: MessageResponseDTO.self
        )
    }
    
    /// レシピ新規作成
    /// POST /recipes
    func createRecipe(_ recipe: CreateRecipeRequestDTO, token: String) async throws -> MessageResponseDTO {
        return try await networkClient.request(
            url: "\(baseURL)/recipes",
            method: .POST,
            headers: ["Authorization": "Bearer \(token)"],
            body: recipe,
            responseType: MessageResponseDTO.self
        )
    }
    
    /// レシピ更新
    /// PUT /recipes
    func updateRecipe(_ recipe: UpdateRecipeRequestDTO, token: String) async throws -> RecipeDetailDTO {
        return try await networkClient.request(
            url: "\(baseURL)/recipes",
            method: .PUT,
            headers: ["Authorization": "Bearer \(token)"],
            body: recipe,
            responseType: RecipeDetailDTO.self
        )
    }
    
    // MARK: - Search Operations
    
    /// レシピ検索
    /// GET /recipes/search?q=query
    func searchRecipes(query: String, token: String) async throws -> [RecipeSummaryDTO] {
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return try await networkClient.request(
            url: "\(baseURL)/recipes/search?q=\(encodedQuery)",
            method: .GET,
            headers: ["Authorization": "Bearer \(token)"],
            responseType: [RecipeSummaryDTO].self
        )
    }
    
    /// タイトルでレシピ検索
    /// GET /recipes/search?title=xxx
    func searchRecipesByTitle(title: String, token: String) async throws -> [RecipeSummaryDTO] {
        let encodedTitle = title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return try await networkClient.request(
            url: "\(baseURL)/recipes/search?title=\(encodedTitle)",
            method: .GET,
            headers: ["Authorization": "Bearer \(token)"],
            responseType: [RecipeSummaryDTO].self
        )
    }
    
    /// 材料でレシピ検索
    /// GET /recipes/search?ingredients=xxx
    func searchRecipesByIngredient(ingredient: String, token: String) async throws -> [RecipeSummaryDTO] {
        let encodedIngredient = ingredient.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return try await networkClient.request(
            url: "\(baseURL)/recipes/search?ingredients=\(encodedIngredient)",
            method: .GET,
            headers: ["Authorization": "Bearer \(token)"],
            responseType: [RecipeSummaryDTO].self
        )
    }
    
    // MARK: - External Fetch Operations
    
    /// 外部URLからレシピ取得
    /// POST /recipes/fetch
    func fetchRecipeFromURL(_ urlString: String, token: String) async throws -> RecipeDetailDTO {
        let request = FetchRecipeFromURLRequestDTO(url: urlString)
        return try await networkClient.request(
            url: "\(baseURL)/recipes/fetch",
            method: .POST,
            headers: ["Authorization": "Bearer \(token)"],
            body: request,
            responseType: RecipeDetailDTO.self
        )
    }
    
    // MARK: - User Operations
    
    /// 現在のユーザー情報取得
    func getCurrentUser(token: String) async throws -> AuthUserDTO {
        return try await networkClient.request(
            url: "\(baseURL)/user/me",
            method: .GET,
            headers: ["Authorization": "Bearer \(token)"],
            responseType: AuthUserDTO.self
        )
    }
    
    /// アカウント削除
    /// DELETE /account
    func deleteAccount(token: String) async throws {
        try await networkClient.request(
            url: "\(baseURL)/account",
            method: .DELETE,
            headers: ["Authorization": "Bearer \(token)"],
            responseType: EmptyResponse.self
        )
    }
}
