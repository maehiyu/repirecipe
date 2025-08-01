import Foundation

struct RecipeDetail {
    let recipeID: String
    let title: String
    let thumbnailURL: String?
    let mediaURL: String?
    let ingredientGroups: [IngredientGroup]
    let memo: String?
    let createdAt: Date?
    let lastCookedAt: Date?
    
    var isValid: Bool {
        !title.isEmpty
    }
    
    var hasIngredients: Bool {
        ingredientGroups.contains { $0.hasIngredients }
    }
    
    var displayTitle: String {
        title.isEmpty ? "無題のレシピ" : title
    }
    
    func validate() throws {
        if title.isEmpty {
            throw ValidationError.titleRequired
        }
        
        for group in ingredientGroups {
            for ingredient in group.ingredients {
                try ingredient.validate()
            }
        }
    }
    
    func markAsCooked() -> RecipeDetail {
        RecipeDetail(
            recipeID: recipeID,
            title: title,
            thumbnailURL: thumbnailURL,
            mediaURL: mediaURL,
            ingredientGroups: ingredientGroups,
            memo: memo,
            createdAt: createdAt,
            lastCookedAt: Date()
        )
    }
    
    func updateMemo(_ newMemo: String?) -> RecipeDetail {
        RecipeDetail(
            recipeID: recipeID,
            title: title,
            thumbnailURL: thumbnailURL,
            mediaURL: mediaURL,
            ingredientGroups: ingredientGroups,
            memo: newMemo,
            createdAt: createdAt,
            lastCookedAt: lastCookedAt
        )
    }
}
