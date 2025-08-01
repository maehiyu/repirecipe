import SwiftUI

struct RecipeDetailView: View {
    let recipeId: String
    @StateObject private var viewModel: RecipeDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var isShowingEditView = false
    
    init(recipeId: String) {
        self.recipeId = recipeId
        let container = DIContainer.shared
        let detailViewModel = container.makeRecipeDetailViewModel(recipeId: recipeId)
        self._viewModel = StateObject(wrappedValue: detailViewModel)
    }
    
    var body: some View {
        ScrollView {
            if viewModel.isLoading {
                ProgressView("読み込み中...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let recipe = viewModel.recipe {
                VStack(alignment: .leading, spacing: 16) {
                    // レシピタイトル
                    Text(recipe.title)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    // 作成日
                    if let createdAt = recipe.createdAt {
                        Text("作成日: \(createdAt, formatter: dateFormatter)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // メモ
                    if let memo = recipe.memo, !memo.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("メモ")
                                .font(.headline)
                            Text(memo)
                                .font(.body)
                        }
                    }
                    
                    // 材料グループ
                    if !recipe.ingredientGroups.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("材料")
                                .font(.headline)
                            
                            ForEach(recipe.ingredientGroups, id: \.groupID) { group in
                                IngredientGroupView(group: group)
                            }
                        }
                    }
                    
                    Spacer()
                }
                .padding()
            } else {
                EmptyRecipeView()
            }
        }
        .navigationTitle("レシピ詳細")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button("編集") {
                        isShowingEditView = true
                    }
                    
                    Button("削除", role: .destructive) {
                        viewModel.isShowingDeleteConfirmation = true
                    }
                } label: {
                    Image(systemName: "ellipsis")
                }
            }
        }
        .sheet(isPresented: $isShowingEditView) {
            RecipeEditView(recipeId: recipeId)
        }
        .onAppear {
            Task {
                await viewModel.loadRecipeDetail()
            }
        }
        .alert("エラー", isPresented: $viewModel.isShowingAlert) {
            Button("OK") {
                viewModel.clearError()
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .alert("レシピを削除", isPresented: $viewModel.isShowingDeleteConfirmation) {
            Button("削除", role: .destructive) {
                Task {
                    await viewModel.deleteRecipe()
                    dismiss()
                }
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("このレシピを削除しますか？この操作は取り消せません。")
        }
    }
    
    // MARK: - Subviews

    private struct IngredientGroupView: View {
        let group: IngredientGroup
        
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                if let title = group.title, !title.isEmpty {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                
                ForEach(group.ingredients, id: \.id) { ingredient in
                    HStack {
                        Text(ingredient.ingredientName)
                        Spacer()
                        Text(ingredient.displayAmount)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(.regularMaterial)
            .cornerRadius(8)
        }
    }

    private struct EmptyRecipeView: View {
        var body: some View {
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 60))
                    .foregroundColor(.orange)
                
                Text("レシピが見つかりません")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
}

// MARK: - レシピ編集View
struct RecipeEditView: View {
    let recipeId: String
    @StateObject private var viewModel: RecipeDetailEditViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingDiscardAlert = false
    
    init(recipeId: String) {
        self.recipeId = recipeId
        let container = DIContainer.shared
        let editViewModel = container.makeRecipeDetailEditViewModel(recipeId: recipeId)
        self._viewModel = StateObject(wrappedValue: editViewModel)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                BasicInfoSection(viewModel: viewModel)
                MediaSection(viewModel: viewModel)
                IngredientsEditSection(viewModel: viewModel)
            }
            .navigationTitle("レシピ編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        if viewModel.hasChanges() {
                            showingDiscardAlert = true
                        } else {
                            dismiss()
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        Task {
                            await viewModel.updateRecipe()
                            if viewModel.isShowingSaveSuccess {
                                dismiss()
                            }
                        }
                    }
                    .disabled(viewModel.isSaving)
                }
            }
        }
        .onAppear {
            Task {
                await viewModel.loadRecipeForEdit()
            }
        }
        .alert("変更を破棄", isPresented: $showingDiscardAlert) {
            Button("破棄", role: .destructive) {
                dismiss()
            }
            Button("継続編集", role: .cancel) {}
        } message: {
            Text("編集した内容が失われます。よろしいですか？")
        }
        .alert("エラー", isPresented: $viewModel.isShowingAlert) {
            Button("OK") {
                viewModel.clearError()
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}

// MARK: - Edit Form Sections

private struct BasicInfoSection: View {
    @ObservedObject var viewModel: RecipeDetailEditViewModel
    
    var body: some View {
        Section("基本情報") {
            TextField("レシピタイトル", text: $viewModel.title)
            TextField("メモ（任意）", text: $viewModel.memo, axis: .vertical)
                .lineLimit(3...6)
        }
    }
}

private struct MediaSection: View {
    @ObservedObject var viewModel: RecipeDetailEditViewModel
    
    var body: some View {
        Section("メディア（任意）") {
            TextField("サムネイルURL", text: $viewModel.thumbnailURL)
            TextField("メディアURL", text: $viewModel.mediaURL)
        }
    }
}

private struct IngredientsEditSection: View {
    @ObservedObject var viewModel: RecipeDetailEditViewModel
    
    var body: some View {
        Section("材料") {
            ForEach(Array(viewModel.ingredientGroups.enumerated()), id: \.offset) { groupIndex, group in
                IngredientGroupEditView(
                    group: group,
                    groupIndex: groupIndex,
                    viewModel: viewModel
                )
            }
            
            Button("材料グループを追加") {
                viewModel.addIngredientGroup()
            }
            .foregroundColor(.orange)
        }
    }
}

private struct IngredientGroupEditView: View {
    let group: IngredientGroup
    let groupIndex: Int
    @ObservedObject var viewModel: RecipeDetailEditViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("グループ名", text: .constant(group.title ?? ""))
                .font(.headline)
                .disabled(true) // 一時的に無効化（ViewModelにアップデートメソッドがないため）
            
            ForEach(Array(group.ingredients.enumerated()), id: \.offset) { ingredientIndex, ingredient in
                IngredientEditRowView(
                    ingredient: ingredient,
                    groupIndex: groupIndex,
                    ingredientIndex: ingredientIndex,
                    viewModel: viewModel
                )
            }
            
            Button("材料を追加") {
                viewModel.addIngredient(to: groupIndex)
            }
            .foregroundColor(.orange)
        }
        .padding(.vertical, 4)
    }
}

private struct IngredientEditRowView: View {
    let ingredient: Ingredient
    let groupIndex: Int
    let ingredientIndex: Int
    @ObservedObject var viewModel: RecipeDetailEditViewModel
    
    var body: some View {
        HStack {
            TextField("材料名", text: .constant(ingredient.ingredientName))
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .disabled(true) // 一時的に無効化（ViewModelにアップデートメソッドがないため）
            
            TextField("分量", text: .constant(ingredient.displayAmount))
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 80)
                .disabled(true) // 一時的に無効化
            
            Button(action: {
                viewModel.removeIngredient(from: groupIndex, at: ingredientIndex)
            }) {
                Image(systemName: "minus.circle.fill")
                    .foregroundColor(.red)
            }
        }
    }
}

#Preview {
    RecipeDetailView(recipeId: "sample-id")
}
