import Foundation

struct AuthUserDTO: Codable {
    let userID: String
    let email: String
    
    func toDomainEntity() -> AuthUser {
        return AuthUser(
            userID: userID,
            email: email
        )
    }
}