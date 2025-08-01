import Foundation

struct RecipeSummary {
    let recipeID: String
    let title: String
    let thumbnailURL: String?
    let createdAt: Date
    let ingredientsName: [String]
    
    var hasIngredients: Bool {
        !ingredientsName.isEmpty
    }
    
    var displayTitle: String {
        title.isEmpty ? "無題のレシピ" : title
    }
}
