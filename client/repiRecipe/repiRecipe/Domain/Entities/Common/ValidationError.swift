import Foundation

enum ValidationError: LocalizedError {
    case titleRequired
    case ingredientNameRequired
    case emailRequired
    case passwordRequired
    case passwordTooShort
    case invalidEmailFormat
    case emptySearchQuery
    case searchQueryTooShort
    case emptyQuery
    case invalidQuery
    case invalidRecipeID
    case userNotSignedIn
    case emptyURL
    case invalidURLFormat
    case emptyEmail
    case emptyPassword
    
    var errorDescription: String? {
        switch self {
        case .titleRequired:
            return "タイトルが必要です"
        case .ingredientNameRequired:
            return "材料名が必要です"
        case .emailRequired:
            return "メールアドレスが必要です"
        case .passwordRequired:
            return "パスワードが必要です"
        case .passwordTooShort:
            return "パスワードは8文字以上で入力してください"
        case .invalidEmailFormat:
            return "有効なメールアドレスを入力してください"
        case .emptySearchQuery:
            return "検索クエリが空です"
        case .searchQueryTooShort:
            return "検索クエリが短すぎます"
        case .emptyQuery:
            return "検索キーワードを入力してください"
        case .invalidQuery:
            return "検索キーワードが無効です"
        case .invalidRecipeID:
            return "無効なレシピIDです"
        case .userNotSignedIn:
            return "ユーザーがサインインしていません"
        case .emptyURL:
            return "URLが空です"
        case .invalidURLFormat:
            return "無効なURL形式です"
        case .emptyEmail:
            return "メールアドレスを入力してください"
        case .emptyPassword:
            return "パスワードを入力してください"
        }
    }
}
