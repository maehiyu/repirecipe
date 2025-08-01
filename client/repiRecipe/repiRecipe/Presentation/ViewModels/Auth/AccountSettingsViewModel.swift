import SwiftUI

@MainActor
class AccountSettingsViewModel: ObservableObject {
    @Published var errorMessage: String?
    @Published var isShowingAlert = false
    @Published var isShowingSignOutConfirmation = false
    @Published var isShowingDeleteAccountConfirmation = false
    @Published var isSignOutSuccessful = false
    @Published var isAccountDeleted = false
    
    private let authViewModel: AuthViewModel
    
    init(authViewModel: AuthViewModel) {
        self.authViewModel = authViewModel
    }
    
    // MARK: - サインアウト
    
    func signOut() async {
        await authViewModel.signOut()
        
        if authViewModel.errorMessage == nil {
            isSignOutSuccessful = true
        } else {
            errorMessage = authViewModel.errorMessage
            isShowingAlert = true
        }
    }
    
    func showSignOutConfirmation() {
        isShowingSignOutConfirmation = true
    }
    
    // MARK: - アカウント削除
    
    func deleteAccount() async {
        await authViewModel.deleteAccount()
        
        if authViewModel.errorMessage == nil {
            isAccountDeleted = true
        } else {
            errorMessage = authViewModel.errorMessage
            isShowingAlert = true
        }
    }
    
    func showDeleteAccountConfirmation() {
        isShowingDeleteAccountConfirmation = true
    }
    
    // MARK: - エラーハンドリング
    
    func clearError() {
        errorMessage = nil
        isShowingAlert = false
        authViewModel.clearError()
    }
    
    func clearSuccessStates() {
        isSignOutSuccessful = false
        isAccountDeleted = false
    }
    
    // MARK: - Computed Properties
    
    var currentUser: AuthUser? {
        authViewModel.currentUser
    }
    
    var userEmail: String {
        authViewModel.currentUser?.email ?? "不明"
    }
    
    var userDisplayName: String {
        authViewModel.userDisplayName
    }
    
    var isSignedIn: Bool {
        authViewModel.isSignedIn
    }
    
    var isLoading: Bool {
        authViewModel.isLoading
    }
    
    var canPerformActions: Bool {
        !isLoading && isSignedIn
    }
}
