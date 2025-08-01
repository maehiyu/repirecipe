import Foundation

enum AuthError: LocalizedError {
    case notSignedIn
    case invalidCredentials
    case refreshTokenNotFound
    case sessionExpired
    case tokenRefreshFailed
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .notSignedIn:
            return "サインインが必要です"
        case .invalidCredentials:
            return "メールアドレスまたはパスワードが正しくありません"
        case .refreshTokenNotFound:
            return "リフレッシュトークンが見つかりません"
        case .sessionExpired:
            return "セッションの有効期限が切れました。再度サインインしてください"
        case .tokenRefreshFailed:
            return "トークンの更新に失敗しました"
        case .networkError:
            return "ネットワークエラーが発生しました"
        }
    }
}