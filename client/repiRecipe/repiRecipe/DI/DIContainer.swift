import SwiftUI

@MainActor
class DIContainer: ObservableObject {
    
    // MARK: - Singleton
    static let shared = DIContainer()
    
    private init() {}
    
    // MARK: - Data Layer
    
    private lazy var networkClient = NetworkClient.shared
    private lazy var recipeAPIDataSource = RecipeAPIDataSource(
        networkClient: networkClient
    )
    private lazy var tokenCacheDataSource = TokenCacheDataSource()
    
    // MARK: - Repository Layer
    
    private lazy var recipeRepository: RecipeRepositoryProtocol = RecipeRepositoryImpl(
        apiDataSource: recipeAPIDataSource,
        tokenCacheDataSource: tokenCacheDataSource
    )
    
    // MARK: - UseCase Layer
    
    // Recipe UseCases
    private lazy var getRecipeListUseCase = GetRecipeListUseCase(
        recipeRepository: recipeRepository
    )
    
    private lazy var getRecipeDetailUseCase = GetRecipeDetailUseCase(
        recipeRepository: recipeRepository
    )
    
    private lazy var createRecipeUseCase = CreateRecipeUseCase(
        recipeRepository: recipeRepository
    )
    
    private lazy var updateRecipeUseCase = UpdateRecipeUseCase(
        recipeRepository: recipeRepository
    )
    
    private lazy var deleteRecipeUseCase = DeleteRecipeUseCase(
        recipeRepository: recipeRepository
    )
    
    private lazy var searchRecipesUseCase = SearchRecipesUseCase(
        recipeRepository: recipeRepository
    )
    
    private lazy var fetchRecipeFromURLUseCase = FetchRecipeFromURLUseCase(
        recipeRepository: recipeRepository
    )
    
    // Auth UseCases
    private lazy var signInUseCase = SignInUseCase(
        recipeRepository: recipeRepository
    )
    
    private lazy var signUpUseCase = SignUpUseCase(
        recipeRepository: recipeRepository
    )
    
    private lazy var signOutUseCase = SignOutUseCase(
        recipeRepository: recipeRepository
    )
    
    private lazy var deleteAccountUseCase = DeleteAccountUseCase(
        recipeRepository: recipeRepository
    )
    
    // MARK: - ViewModel Properties
    
    // Auth ViewModels
    private var _authViewModel: AuthViewModel?
    var authViewModel: AuthViewModel {
        if _authViewModel == nil {
            _authViewModel = AuthViewModel(
                signInUseCase: signInUseCase,
                signOutUseCase: signOutUseCase,
                deleteAccountUseCase: deleteAccountUseCase
            )
        }
        return _authViewModel!
    }
    
    private var _signInViewModel: SignInViewModel?
    var signInViewModel: SignInViewModel {
        if _signInViewModel == nil {
            _signInViewModel = SignInViewModel(authViewModel: authViewModel)
        }
        return _signInViewModel!
    }
    
    private var _signUpViewModel: SignUpViewModel?
    var signUpViewModel: SignUpViewModel {
        if _signUpViewModel == nil {
            _signUpViewModel = SignUpViewModel(signUpUseCase: signUpUseCase)
        }
        return _signUpViewModel!
    }
    
    private var _accountSettingsViewModel: AccountSettingsViewModel?
    var accountSettingsViewModel: AccountSettingsViewModel {
        if _accountSettingsViewModel == nil {
            _accountSettingsViewModel = AccountSettingsViewModel(authViewModel: authViewModel)
        }
        return _accountSettingsViewModel!
    }
    
    // Recipe ViewModels
    private var _recipeListViewModel: RecipeListViewModel?
    var recipeListViewModel: RecipeListViewModel {
        if _recipeListViewModel == nil {
            _recipeListViewModel = RecipeListViewModel(
                getRecipeListUseCase: getRecipeListUseCase,
                searchRecipesUseCase: searchRecipesUseCase,
                deleteRecipeUseCase: deleteRecipeUseCase
            )
        }
        return _recipeListViewModel!
    }
    
    private var _searchRecipesViewModel: SearchRecipesViewModel?
    var searchRecipesViewModel: SearchRecipesViewModel {
        if _searchRecipesViewModel == nil {
            _searchRecipesViewModel = SearchRecipesViewModel(
                searchRecipesUseCase: searchRecipesUseCase
            )
        }
        return _searchRecipesViewModel!
    }
    
    // MARK: - Factory Methods for Recipe ViewModels
    
    /// レシピ詳細ViewModelを作成（レシピIDが必要なため）
    func makeRecipeDetailViewModel(recipeId: String) -> RecipeDetailViewModel {
        return RecipeDetailViewModel(
            recipeId: recipeId,
            getRecipeDetailUseCase: getRecipeDetailUseCase,
            deleteRecipeUseCase: deleteRecipeUseCase
        )
    }
    
    /// レシピ編集ViewModelを作成（レシピIDが必要なため）
    func makeRecipeDetailEditViewModel(recipeId: String) -> RecipeDetailEditViewModel {
        return RecipeDetailEditViewModel(
            recipeId: recipeId,
            updateRecipeUseCase: updateRecipeUseCase,
            getRecipeDetailUseCase: getRecipeDetailUseCase
        )
    }
    
    /// レシピ作成ViewModelを作成
    func makeRecipeCreateViewModel() -> RecipeCreateViewModel {
        return RecipeCreateViewModel(
            createRecipeUseCase: createRecipeUseCase
        )
    }
    
    /// SignUpViewModelを作成
    func makeSignUpViewModel() -> SignUpViewModel {
        return SignUpViewModel(signUpUseCase: signUpUseCase)
    }
    
    // MARK: - Configuration
    
    /// 開発環境用の設定
    func configureForDevelopment() {
        // 開発環境専用の設定があれば追加
    }
    
    /// テスト環境用の設定
    func configureForTesting() {
        // テスト用のモックRepositoryに置き換える等
    }
}
