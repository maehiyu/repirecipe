import Foundation

struct RecipeSummaryDTO: Codable {
    let recipeId: String
    let title: String
    let thumbnailUrl: String?
    let createdAt: String          // ISO8601文字列
    let ingredientsName: [String]
}

extension RecipeSummaryDTO {
    func toDomainEntity() -> RecipeSummary {
        return RecipeSummary(
            recipeID: recipeId,
            title: title,
            thumbnailURL: thumbnailUrl,
            createdAt: ISO8601DateFormatter().date(from: createdAt) ?? Date(),
            ingredientsName: ingredientsName
        )
    }
}
