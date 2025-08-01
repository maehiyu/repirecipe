import Foundation

struct IngredientGroupDTO: Codable {
    let groupId: String
    let title: String?
    let orderNum: Int
    let ingredients: [IngredientDTO]
}

extension IngredientGroupDTO {
    func toDomainEntity() -> IngredientGroup {
        return IngredientGroup(
            groupID: groupId,
            title: title,
            orderNum: orderNum,
            ingredients: ingredients.map { $0.toDomainEntity() }
        )
    }
}