import Foundation

/// レシピ作成リクエスト（RecipeDetail準拠）
struct CreateRecipeRequest {
    let title: String
    let thumbnailURL: String?
    let mediaURL: String?
    let memo: String?
    let ingredientGroups: [IngredientGroup]
    // recipeID, createdAt, lastCookedAtはサーバー側で設定
}