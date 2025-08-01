import Foundation

/// レスポンスボディが空のAPIエンドポイント用のDTO
/// DELETE /account などで使用
struct EmptyResponse: Codable {
    // 空のレスポンス用
}