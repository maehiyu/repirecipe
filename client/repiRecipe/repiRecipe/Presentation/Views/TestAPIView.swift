import SwiftUI

struct TestAPIView: View {
    @StateObject private var viewModel = TestAPIViewModel()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("API テスト (localhost:8080)")
                .font(.title)
                .padding(.top)
            
            ScrollView {
                Text(viewModel.testResult)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    .textSelection(.enabled)
            }
            .frame(height: 200)
            
            VStack(spacing: 15) {
                Button("レシピ一覧取得テスト") {
                    Task {
                        await viewModel.testFetchRecipes()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isLoading)
                
                Button("レシピ作成テスト") {
                    Task {
                        await viewModel.testCreateRecipe()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isLoading)
            }
            
            if viewModel.isLoading {
                ProgressView("通信中...")
                    .padding()
            }
            
            Spacer()
        }
        .padding()
        .alert("エラー", isPresented: $viewModel.isShowingAlert) {
            Button("OK") {
                viewModel.clearError()
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}

#Preview {
    TestAPIView()
}