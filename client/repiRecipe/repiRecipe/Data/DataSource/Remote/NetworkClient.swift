import Foundation

enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
}

class NetworkClient {
    static let shared = NetworkClient()
    
    private let baseURL = "http://localhost:8080"
    
    private let session: URLSession
    
    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
    }
    
    /// HTTP リクエストを実行
    func request<T: Codable>(
        url: String,
        method: HTTPMethod,
        headers: [String: String] = [:],
        body: Codable? = nil,
        responseType: T.Type
    ) async throws -> T {
        
        guard let requestURL = URL(string: url) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: requestURL)
        request.httpMethod = method.rawValue
        
        // ヘッダー設定
        headers.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // Content-Type設定
        if body != nil {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        // ボディ設定
        if let body = body {
            do {
                request.httpBody = try JSONEncoder().encode(body)
            } catch {
                throw NetworkError.encodingFailed
            }
        }
        
        // リクエストログ
        print("📤 Request: \(method.rawValue) \(url)")
        if let headers = request.allHTTPHeaderFields {
            print("📤 Headers: \(headers)")
        }
        if let bodyData = request.httpBody,
           let bodyString = String(data: bodyData, encoding: .utf8) {
            print("📤 Body: \(bodyString)")
        }
        
        // リクエスト実行
        do {
            let (data, response) = try await session.data(for: request)
            
            // レスポンスログ追加
            if let httpResponse = response as? HTTPURLResponse {
                print("📥 Response Status: \(httpResponse.statusCode)")
                print("📥 Response Headers: \(httpResponse.allHeaderFields)")
            }
            
            let responseString = String(data: data, encoding: .utf8) ?? "Unable to decode response"
            print("📥 Response Body: \(responseString)")
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }
            
            // ステータスコードチェック
            switch httpResponse.statusCode {
            case 200...299:
                // 成功
                break
            case 401:
                throw NetworkError.unauthorized
            case 403:
                throw NetworkError.forbidden
            case 404:
                throw NetworkError.notFound
            case 500...599:
                throw NetworkError.serverError
            default:
                throw NetworkError.httpError(httpResponse.statusCode)
            }
            
            // 空のレスポンスの場合
            if responseType == EmptyResponse.self && data.isEmpty {
                return EmptyResponse() as! T
            }
            
            // JSONデコード
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                return try decoder.decode(responseType, from: data)
            } catch {
                throw NetworkError.decodingFailed
            }
            
        } catch let error as NetworkError {
            throw error
        } catch {
            throw NetworkError.networkFailed(error)
        }
    }
}

// MARK: - Network Error

enum NetworkError: LocalizedError {
    case invalidURL
    case encodingFailed
    case decodingFailed
    case invalidResponse
    case unauthorized
    case forbidden
    case notFound
    case serverError
    case httpError(Int)
    case networkFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "無効なURLです"
        case .encodingFailed:
            return "リクエストのエンコードに失敗しました"
        case .decodingFailed:
            return "レスポンスのデコードに失敗しました"
        case .invalidResponse:
            return "無効なレスポンスです"
        case .unauthorized:
            return "認証が必要です"
        case .forbidden:
            return "アクセスが拒否されました"
        case .notFound:
            return "リソースが見つかりません"
        case .serverError:
            return "サーバーエラーが発生しました"
        case .httpError(let code):
            return "HTTPエラー: \(code)"
        case .networkFailed(let error):
            return "ネットワークエラー: \(error.localizedDescription)"
        }
    }
}
