import Foundation

enum RepositoryError: LocalizedError {
    case networkError
    case serverError
    case notFound
    case unauthorized
    case invalidData
    case tokenExpired
    case connectionTimeout
    case unknownError(String)
    
    var errorDescription: String? {
        switch self {
        case .networkError:
            return "ネットワークエラーが発生しました"
        case .serverError:
            return "サーバーエラーが発生しました"
        case .notFound:
            return "リソースが見つかりませんでした"
        case .unauthorized:
            return "認証が必要です"
        case .invalidData:
            return "無効なデータです"
        case .tokenExpired:
            return "認証トークンが期限切れです"
        case .connectionTimeout:
            return "接続がタイムアウトしました"
        case .unknownError(let message):
            return "予期しないエラーが発生しました: \(message)"
        }
    }
}