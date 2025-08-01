import SwiftUI

struct SimpleSignUpView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isPasswordVisible = false
    @State private var isConfirmPasswordVisible = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var isShowingAlert = false
    @State private var isShowingSuccess = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // ヘッダー
                VStack(spacing: 16) {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 50))
                        .foregroundColor(.orange)
                    
                    Text("アカウント作成")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("現在は開発中のため、\nサインアップ機能は利用できません")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                
                Spacer()
                
                // 開発中メッセージ
                VStack(spacing: 16) {
                    Image(systemName: "hammer.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.orange)
                    
                    Text("機能開発中")
                        .font(.headline)
                    
                    Text("サインアップ機能は現在開発中です。\n既存のアカウントでサインインしてください。")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal, 24)
                
                Spacer()
            }
            .navigationTitle("サインアップ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("戻る") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    SimpleSignUpView()
}