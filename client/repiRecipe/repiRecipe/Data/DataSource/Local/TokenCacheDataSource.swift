import Foundation

protocol TokenCacheDataSourceProtocol {
    func saveToken(_ token: String) async throws
    func getToken() async throws -> String?
    func clearToken() async throws
    func getRefreshToken() async throws -> String?
    func saveRefreshToken(_ token: String) async throws
}

class TokenCacheDataSource: TokenCacheDataSourceProtocol {
    private let userDefaults = UserDefaults.standard
    private let accessTokenKey = "access_token"
    private let refreshTokenKey = "refresh_token"
    
    // MARK: - Token Operations
    
    func saveToken(_ token: String) async throws {
        userDefaults.set(token, forKey: accessTokenKey)
    }
    
    func getToken() async throws -> String? {
        return userDefaults.string(forKey: accessTokenKey)
    }
    
    func clearToken() async throws {
        userDefaults.removeObject(forKey: accessTokenKey)
        userDefaults.removeObject(forKey: refreshTokenKey)
    }
    
    func getRefreshToken() async throws -> String? {
        return userDefaults.string(forKey: refreshTokenKey)
    }
    
    func saveRefreshToken(_ token: String) async throws {
        userDefaults.set(token, forKey: refreshTokenKey)
    }
    
    // MARK: - Complex Token Operations (将来のCognito対応用)
    
    /// AuthTokenDTOを保存（将来のCognito実装用）
    func saveAuthToken(_ authToken: AuthTokenInfo) async throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(authToken)
        userDefaults.set(data, forKey: "auth_token_info")
    }
    
    /// AuthTokenDTOを取得（将来のCognito実装用）
    func getAuthToken() async throws -> AuthTokenInfo? {
        guard let data = userDefaults.data(forKey: "auth_token_info") else {
            return nil
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(AuthTokenInfo.self, from: data)
    }
    
    /// トークンの有効期限チェック
    func isTokenValid() async throws -> Bool {
        guard let authToken = try await getAuthToken() else {
            return false
        }
        
        return !authToken.isExpired
    }
}

// MARK: - Token Info Model

struct AuthTokenInfo: Codable {
    let accessToken: String
    let refreshToken: String?
    let expiresAt: Date
    
    var isExpired: Bool {
        Date() > expiresAt
    }
    
    var needsRefresh: Bool {
        let refreshThreshold = expiresAt.addingTimeInterval(-300) // 5分前
        return Date() > refreshThreshold
    }
    
    init(accessToken: String, refreshToken: String? = nil, expiresAt: Date = Date().addingTimeInterval(3600)) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresAt = expiresAt
    }
}