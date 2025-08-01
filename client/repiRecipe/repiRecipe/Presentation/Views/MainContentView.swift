import SwiftUI

struct MainContentView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // レシピ一覧タブ
            Tab("レシピ", systemImage: "list.bullet", value: 0) {
                RecipeListView()
            }
            
            // レシピ作成タブ
            Tab("作成", systemImage: "plus.circle", value: 2) {
                RecipeCreateView()
            }
            
            // 設定タブ
            Tab("設定", systemImage: "gearshape", value: 3) {
                SettingsView()
            }
            
            // 検索タブ（セマンティック検索ロール）
            Tab("検索", systemImage: "magnifyingglass", value: 1, role: .search) {
                SearchRecipeView()
            }
        }
        .tabViewStyle(.sidebarAdaptable)
        .accentColor(.orange)
    }
}

// MARK: - レシピ一覧View
struct RecipeListView: View {
    @StateObject private var viewModel = DIContainer.shared.recipeListViewModel
    
    var body: some View {
        NavigationStack {
            VStack {
                if viewModel.isLoading {
                    ProgressView("読み込み中...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.recipes.isEmpty {
                    // 空の状態
                    VStack(spacing: 16) {
                        Image(systemName: "fork.knife")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("レシピがありません")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("新しいレシピを作成してみましょう")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // レシピリスト
                    List(viewModel.recipes, id: \.recipeID) { recipe in
                        NavigationLink(destination: RecipeDetailView(recipeId: recipe.recipeID)) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(recipe.title)
                                    .font(.headline)
                                
                                Text("作成日: \(recipe.createdAt, formatter: dateFormatter)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                if recipe.hasIngredients {
                                    Text("材料: \(recipe.ingredientsName.joined(separator: ", "))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(2)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("レシピ")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("更新") {
                        Task {
                            await viewModel.loadRecipes()
                        }
                    }
                }
            }
        }
        .onAppear {
            Task {
                await viewModel.loadRecipes()
            }
        }
        .alert("エラー", isPresented: $viewModel.isShowingAlert) {
            Button("OK") {
                viewModel.clearError()
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
}

// MARK: - 検索View
struct SearchRecipeView: View {
    @StateObject private var viewModel = DIContainer.shared.searchRecipesViewModel
    @State private var searchText = ""
    @State private var selectedSearchType: SearchType = .ingredient
    
    enum SearchType: String, CaseIterable {
        case title = "タイトル"
        case ingredient = "材料"
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                // 検索タイプ選択（システム検索フィールド使用時のオプション）
                Picker("検索タイプ", selection: $selectedSearchType) {
                    ForEach(SearchType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // 検索結果
                if viewModel.isLoading {
                    Spacer()
                    ProgressView("検索中...")
                    Spacer()
                } else if searchText.isEmpty {
                    // 初期状態
                    VStack(spacing: 16) {
                        Image(systemName: currentSearchIcon)
                            .font(.system(size: 60))
                            .foregroundColor(currentSearchColor)
                        
                        Text(currentSearchTitle)
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text(currentSearchDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.searchResults.isEmpty && !viewModel.isLoading {
                    // 検索結果なし
                    VStack(spacing: 16) {
                        Image(systemName: "questionmark.circle")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("該当するレシピがありません")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("別のキーワードで検索してみてください")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // 検索結果リスト
                    List(viewModel.searchResults, id: \.recipeID) { recipe in
                        NavigationLink(destination: RecipeDetailView(recipeId: recipe.recipeID)) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(recipe.title)
                                    .font(.headline)
                                
                                Text("作成日: \(recipe.createdAt, formatter: dateFormatter)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                if recipe.hasIngredients {
                                    Text("材料: \(recipe.ingredientsName.joined(separator: ", "))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(2)
                                }
                                
                                // 検索タイプに応じたハイライト表示
                                if selectedSearchType == .ingredient && !recipe.ingredientsName.isEmpty {
                                    Text("マッチした材料: \(highlightedIngredients(recipe.ingredientsName))")
                                        .font(.caption2)
                                        .foregroundColor(.orange)
                                        .padding(.top, 2)
                                } else if selectedSearchType == .title {
                                    Text("タイトル検索でマッチ")
                                        .font(.caption2)
                                        .foregroundColor(.orange)
                                        .padding(.top, 2)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("レシピ検索")
            .searchable(text: $searchText, prompt: searchPlaceholder)
            .onSubmit(of: .search) {
                performSearch()
            }
            .onChange(of: searchText) { oldValue, newValue in
                if newValue.isEmpty {
                    viewModel.clearResults()
                } else {
                    // リアルタイム検索も可能
                    // performSearch()
                }
            }
        }
        .alert("エラー", isPresented: $viewModel.isShowingAlert) {
            Button("OK") {
                viewModel.clearError()
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
    
    // MARK: - Computed Properties
    
    private var searchPlaceholder: String {
        switch selectedSearchType {
        case .title:
            return "レシピ名を入力..."
        case .ingredient:
            return "材料名を入力..."
        }
    }
    
    private var currentSearchIcon: String {
        switch selectedSearchType {
        case .title:
            return "doc.text.magnifyingglass"
        case .ingredient:
            return "leaf.circle"
        }
    }
    
    private var currentSearchColor: Color {
        switch selectedSearchType {
        case .title:
            return .blue
        case .ingredient:
            return .green
        }
    }
    
    private var currentSearchTitle: String {
        switch selectedSearchType {
        case .title:
            return "レシピ名で検索"
        case .ingredient:
            return "材料からレシピを検索"
        }
    }
    
    private var currentSearchDescription: String {
        switch selectedSearchType {
        case .title:
            return "作りたいレシピの名前を入力して\n検索できます"
        case .ingredient:
            return "冷蔵庫にある材料名を入力して\nレシピを検索できます"
        }
    }
    
    // MARK: - Private Methods
    
    private func performSearch() {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        Task {
            switch selectedSearchType {
            case .title:
                await viewModel.searchByTitle(searchText)
            case .ingredient:
                await viewModel.searchByIngredient(searchText)
            }
        }
    }
    
    private func highlightedIngredients(_ ingredients: [String]) -> String {
        let matchedIngredients = ingredients.filter { ingredient in
            ingredient.localizedCaseInsensitiveContains(searchText)
        }
        return matchedIngredients.joined(separator: ", ")
    }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
}

// MARK: - レシピ作成View
struct RecipeCreateView: View {
    @StateObject private var viewModel = DIContainer.shared.makeRecipeCreateViewModel()
    @State private var showingDiscardAlert = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("基本情報") {
                    TextField("レシピタイトル", text: $viewModel.title)
                    TextField("メモ（任意）", text: $viewModel.memo, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("メディア（任意）") {
                    TextField("サムネイルURL", text: $viewModel.thumbnailURL)
                    TextField("メディアURL", text: $viewModel.mediaURL)
                }
                
                Section("材料") {
                    ForEach(Array(viewModel.ingredientGroups.enumerated()), id: \.offset) { groupIndex, group in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(group.displayTitle)
                                .font(.headline)
                            
                            ForEach(Array(group.ingredients.enumerated()), id: \.offset) { ingredientIndex, ingredient in
                                HStack {
                                    TextField("材料名", text: .constant(ingredient.ingredientName))
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                    
                                    TextField("分量", text: .constant(ingredient.displayAmount))
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .frame(width: 80)
                                }
                            }
                            
                            Button("材料を追加") {
                                viewModel.addIngredient(to: groupIndex)
                            }
                            .foregroundColor(.orange)
                        }
                        .padding(.vertical, 4)
                    }
                    
                    Button("材料グループを追加") {
                        viewModel.addIngredientGroup()
                    }
                    .foregroundColor(.orange)
                }
            }
            .navigationTitle("レシピ作成")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("リセット") {
                        if viewModel.hasContent() {
                            showingDiscardAlert = true
                        } else {
                            viewModel.resetForm()
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        Task {
                            await viewModel.createRecipe()
                        }
                    }
                    .disabled(viewModel.isSaving)
                }
            }
        }
        .alert("入力内容を破棄", isPresented: $showingDiscardAlert) {
            Button("破棄", role: .destructive) {
                viewModel.resetForm()
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("入力した内容が削除されます。よろしいですか？")
        }
        .alert("エラー", isPresented: $viewModel.isShowingAlert) {
            Button("OK") {
                viewModel.clearError()
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .alert("レシピ作成完了", isPresented: $viewModel.isShowingCreateSuccess) {
            Button("OK") {
                viewModel.clearSuccess()
                viewModel.resetForm()
            }
        } message: {
            Text("レシピが作成されました")
        }
    }
    
    // MARK: - Helper Methods for Bindings
    
    private func createGroupTitleBinding(groupIndex: Int, group: IngredientGroup) -> Binding<String> {
        return Binding(
            get: { group.title ?? "" },
            set: { newValue in
                viewModel.updateIngredientGroupTitle(at: groupIndex, title: newValue)
            }
        )
    }
    
    private func createIngredientNameBinding(groupIndex: Int, ingredientIndex: Int, ingredient: Ingredient) -> Binding<String> {
        return Binding(
            get: { ingredient.ingredientName },
            set: { newValue in
                viewModel.updateIngredient(
                    groupIndex: groupIndex,
                    ingredientIndex: ingredientIndex,
                    name: newValue,
                    amount: ingredient.amount ?? ""
                )
            }
        )
    }
    
    private func createIngredientAmountBinding(groupIndex: Int, ingredientIndex: Int, ingredient: Ingredient) -> Binding<String> {
        return Binding(
            get: { ingredient.amount ?? "" },
            set: { newValue in
                viewModel.updateIngredient(
                    groupIndex: groupIndex,
                    ingredientIndex: ingredientIndex,
                    name: ingredient.ingredientName,
                    amount: newValue
                )
            }
        )
    }
}

// MARK: - 設定View
struct SettingsView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @StateObject private var accountViewModel = DIContainer.shared.accountSettingsViewModel
    @State private var showingSignOutAlert = false
    @State private var showingDeleteAccountAlert = false
    
    var body: some View {
        NavigationStack {
            List {
                // ユーザー情報セクション
                Section("アカウント") {
                    if let user = authViewModel.currentUser {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .font(.title2)
                                .foregroundColor(.orange)
                            
                            VStack(alignment: .leading) {
                                Text(user.email)
                                    .font(.headline)
                                Text("ユーザーID: \(user.userID)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                // アクションセクション
                Section("アクション") {
                    Button(action: {
                        showingSignOutAlert = true
                    }) {
                        Label("サインアウト", systemImage: "rectangle.portrait.and.arrow.right")
                            .foregroundColor(.orange)
                    }
                    
                    Button(action: {
                        showingDeleteAccountAlert = true
                    }) {
                        Label("アカウント削除", systemImage: "trash")
                            .foregroundColor(.red)
                    }
                }
                
                // アプリ情報セクション
                Section("アプリ情報") {
                    HStack {
                        Text("バージョン")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("設定")
        }
        .alert("サインアウト", isPresented: $showingSignOutAlert) {
            Button("サインアウト", role: .destructive) {
                Task {
                    await authViewModel.signOut()
                }
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("サインアウトしますか？")
        }
        .alert("アカウント削除", isPresented: $showingDeleteAccountAlert) {
            Button("削除", role: .destructive) {
                Task {
                    await accountViewModel.deleteAccount()
                }
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("アカウントを削除すると、すべてのデータが失われます。この操作は取り消せません。")
        }
    }
}

#Preview {
    MainContentView()
        .environmentObject(DIContainer.shared.authViewModel)
}
