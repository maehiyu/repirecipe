import SwiftUI

@MainActor
class AuthViewModel: ObservableObject {
    @Published var currentUser: AuthUser?
    @Published var isSignedIn = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isShowingAlert = false
    
    private let signInUseCase: SignInUseCase
    private let signOutUseCase: SignOutUseCase
    private let deleteAccountUseCase: DeleteAccountUseCase
    
    init(
        signInUseCase: SignInUseCase,
        signOutUseCase: SignOutUseCase,
        deleteAccountUseCase: DeleteAccountUseCase
    ) {
        self.signInUseCase = signInUseCase
        self.signOutUseCase = signOutUseCase
        self.deleteAccountUseCase = deleteAccountUseCase
    }
    
    // MARK: - サインイン
    
    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let user = try await signInUseCase.execute(email: email, password: password)
            currentUser = user
            isSignedIn = true
        } catch {
            handleError(error)
        }
        
        isLoading = false
    }
    
    // MARK: - サインアウト
    
    func signOut() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await signOutUseCase.execute()
            currentUser = nil
            isSignedIn = false
        } catch {
            handleError(error)
        }
        
        isLoading = false
    }
    
    // MARK: - アカウント削除
    
    func deleteAccount() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await deleteAccountUseCase.execute()
            currentUser = nil
            isSignedIn = false
        } catch {
            handleError(error)
        }
        
        isLoading = false
    }
    
    // MARK: - 現在のユーザー状態チェック
    
    func checkAuthStatus() async {
        // 現在の実装では、保存されたトークンから認証状態を復元
        // 実際のプロジェクトでは、getCurrentUserUseCaseを実装して使用
        isLoading = true
        
        // TODO: 実際の認証状態チェック実装
        // 現在はダミー実装として、何もしない
        do {
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5秒待機
        } catch {
            // Task.sleepのエラーは通常発生しないが、念のためハンドリング
        }
        
        isLoading = false
    }
    
    // MARK: - Error Handling
    
    private func handleError(_ error: Error) {
        if let validationError = error as? ValidationError {
            errorMessage = validationError.localizedDescription
        } else if let authError = error as? AuthError {
            errorMessage = authError.localizedDescription
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
    
    var userDisplayName: String {
        currentUser?.email ?? "ゲスト"
    }
    
    var hasValidSession: Bool {
        currentUser != nil && isSignedIn
    }
}
