import Foundation

struct RecipeDetailDTO: Codable {
    let recipeId: String
    let title: String
    let thumbnailUrl: String?
    let mediaUrl: String?
    let memo: String?
    let createdAt: String?
    let lastCookedAt: String?
    let ingredientGroups: [IngredientGroupDTO]?
}

extension RecipeDetailDTO {
    func toDomainEntity() -> RecipeDetail {
        return RecipeDetail(
            recipeID: recipeId,
            title: title,
            thumbnailURL: thumbnailUrl,
            mediaURL: mediaUrl,
            ingredientGroups: ingredientGroups?.map { $0.toDomainEntity() } ?? [],
            memo: memo,
            createdAt: createdAt.flatMap { ISO8601DateFormatter().date(from: $0) },
            lastCookedAt: lastCookedAt.flatMap { ISO8601DateFormatter().date(from: $0) }
        )
    }
}
