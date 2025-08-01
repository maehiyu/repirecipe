import Foundation

struct Ingredient {
    let id: String
    let ingredientName: String
    let amount: String?
    let orderNum: Int
    
    var isValid: Bool {
        !ingredientName.isEmpty
    }
    
    var displayAmount: String {
        amount ?? ""
    }
    
    func validate() throws {
        if ingredientName.isEmpty {
            throw ValidationError.ingredientNameRequired
        }
    }
    
    func updateAmount(_ newAmount: String?) -> Ingredient {
        Ingredient(
            id: id,
            ingredientName: ingredientName,
            amount: newAmount,
            orderNum: orderNum
        )
    }
}