import Foundation

// MARK: - Authentication Request DTOs

struct SignInRequestDTO: Codable {
    let email: String
    let password: String
}

struct SignUpRequestDTO: Codable {
    let email: String
    let password: String
    let name: String?
}

struct ConfirmSignUpRequestDTO: Codable {
    let email: String
    let confirmationCode: String
}

struct ForgotPasswordRequestDTO: Codable {
    let email: String
}

struct ConfirmForgotPasswordRequestDTO: Codable {
    let email: String
    let confirmationCode: String
    let newPassword: String
}