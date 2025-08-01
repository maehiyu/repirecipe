import Foundation

/// レシピ更新リクエスト（RecipeDetail準拠）
struct UpdateRecipeRequest {
    let recipeID: String           // 更新対象の識別用
    let title: String
    let thumbnailURL: String?
    let mediaURL: String?
    let memo: String?
    let ingredientGroups: [IngredientGroup]
    // createdAt, lastCookedAtはサーバー側で管理
}