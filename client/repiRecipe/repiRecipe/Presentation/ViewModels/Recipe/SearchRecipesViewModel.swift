import SwiftUI

@MainActor
class SearchRecipesViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var searchResults: [RecipeSummary] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isShowingAlert = false
    
    // MARK: - Private Properties
    
    private let searchRecipesUseCase: SearchRecipesUseCase
    
    // MARK: - Initialization
    
    init(searchRecipesUseCase: SearchRecipesUseCase) {
        self.searchRecipesUseCase = searchRecipesUseCase
    }
    
    // MARK: - Public Methods
    
    /// タイトルでレシピを検索
    func searchByTitle(_ title: String) async {
        await performSearch {
            try await self.searchRecipesUseCase.searchByTitle(query: title)
        }
    }
    
    /// 材料でレシピを検索
    func searchByIngredient(_ ingredient: String) async {
        await performSearch {
            try await self.searchRecipesUseCase.searchByIngredient(ingredient: ingredient)
        }
    }
    
    /// 検索結果をクリア
    func clearResults() {
        searchResults = []
        clearError()
    }
    
    /// エラーをクリア
    func clearError() {
        errorMessage = nil
        isShowingAlert = false
    }
    
    // MARK: - Private Methods
    
    /// 検索を実行する共通メソッド
    private func performSearch(_ searchOperation: @escaping () async throws -> [RecipeSummary]) async {
        guard !isLoading else { return }
        
        isLoading = true
        clearError()
        
        do {
            let results = try await searchOperation()
            searchResults = results
        } catch {
            handleError(error)
        }
        
        isLoading = false
    }
    
    /// エラーハンドリング
    private func handleError(_ error: Error) {
        if let validationError = error as? ValidationError {
            switch validationError {
            case .emptyQuery:
                errorMessage = "検索キーワードを入力してください"
            case .invalidQuery:
                errorMessage = "検索キーワードが無効です"
            default:
                errorMessage = validationError.localizedDescription
            }
        } else if let repositoryError = error as? RepositoryError {
            switch repositoryError {
            case .networkError:
                errorMessage = "ネットワークエラーが発生しました"
            case .serverError:
                errorMessage = "サーバーエラーが発生しました"
            case .notFound:
                errorMessage = "該当するレシピが見つかりませんでした"
            case .unauthorized:
                errorMessage = "認証が必要です"
            default:
                errorMessage = "検索中にエラーが発生しました"
            }
        } else {
            errorMessage = "予期しないエラーが発生しました: \(error.localizedDescription)"
        }
        
        isShowingAlert = true
    }
}
