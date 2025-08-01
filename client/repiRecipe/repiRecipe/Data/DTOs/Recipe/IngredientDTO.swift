import Foundation

struct IngredientDTO: Codable {
    let id: String
    let ingredientName: String
    let amount: String?
    let orderNum: Int
    // ingredientVectorはAPIレスポンスに含まれないので除外
}

extension IngredientDTO {
    func toDomainEntity() -> Ingredient {
        return Ingredient(
            id: id,
            ingredientName: ingredientName,
            amount: amount,
            orderNum: orderNum
        )
    }
}