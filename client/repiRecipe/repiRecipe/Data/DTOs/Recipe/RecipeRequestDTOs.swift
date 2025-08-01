import Foundation

// MARK: - Recipe Request DTOs

struct CreateRecipeRequestDTO: Codable {
    let title: String
    let thumbnailUrl: String?       // 追加
    let mediaUrl: String?           // 追加
    let memo: String?
    let ingredientGroups: [IngredientGroupDTO]
    // recipeId, createdAt, lastCookedAtはサーバー側で設定
}

struct UpdateRecipeRequestDTO: Codable {
    let recipeId: String           // 更新対象の識別用
    let title: String
    let thumbnailUrl: String?       // 追加
    let mediaUrl: String?           // 追加
    let memo: String?
    let ingredientGroups: [IngredientGroupDTO]
    // createdAt, lastCookedAtはサーバー側で管理
}
