import Foundation

struct AuthUser {
    let userID: String          // Cognito User Sub (UUID)
    let email: String           // Cognito Username (email)
    
    // MARK: - Computed Properties
    
    /// 表示用の名前（emailのローカル部分を使用）
    var displayName: String {
        return email.components(separatedBy: "@").first ?? "User"
    }
    
    /// Cognitoのユーザー識別子
    var cognitoSub: String {
        return userID
    }
}

// MARK: - Identifiable
extension AuthUser: Identifiable {
    var id: String { userID }
}

// MARK: - Equatable
extension AuthUser: Equatable {
    static func == (lhs: AuthUser, rhs: AuthUser) -> Bool {
        return lhs.userID == rhs.userID
    }
}
