import Foundation

struct IngredientGroup {
    let groupID: String
    let title: String?
    let orderNum: Int
    let ingredients: [Ingredient]
    
    var displayTitle: String {
        title ?? "材料"
    }
    
    var hasIngredients: Bool {
        !ingredients.isEmpty
    }
    
    var validIngredients: [Ingredient] {
        ingredients.filter { $0.isValid }
    }
}