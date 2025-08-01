import SwiftUI

struct SignInView: View {
    @StateObject private var signInViewModel = DIContainer.shared.signInViewModel
    @EnvironmentObject private var authViewModel: AuthViewModel
    @State private var showSignUp = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // アプリロゴ・タイトル
                VStack(spacing: 16) {
                    Image(systemName: "fork.knife")
                        .font(.system(size: 60))
                        .foregroundColor(.orange)
                    
                    Text("RepiRecipe")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("レシピを管理しよう")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)
                
                Spacer()
                
                // サインインフォーム
                VStack(spacing: 16) {
                    // メールアドレス入力
                    VStack(alignment: .leading, spacing: 8) {
                        Text("メールアドレス")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextField("メールアドレスを入力", text: $signInViewModel.email)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                            .autocapitalization(.none)
                    }
                    
                    // パスワード入力
                    VStack(alignment: .leading, spacing: 8) {
                        Text("パスワード")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Group {
                                if signInViewModel.isPasswordVisible {
                                    TextField("パスワードを入力", text: $signInViewModel.password)
                                } else {
                                    SecureField("パスワードを入力", text: $signInViewModel.password)
                                }
                            }
                            .textContentType(.password)
                            
                            Button(action: {
                                signInViewModel.isPasswordVisible.toggle()
                            }) {
                                Image(systemName: signInViewModel.isPasswordVisible ? "eye.slash" : "eye")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal, 24)
                
                // サインインボタン
                Button(action: {
                    Task {
                        await signInViewModel.signIn()
                    }
                }) {
                    HStack {
                        if authViewModel.isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                                .foregroundColor(.white)
                        }
                        
                        Text("サインイン")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(authViewModel.isLoading || signInViewModel.email.isEmpty || signInViewModel.password.isEmpty)
                .padding(.horizontal, 24)
                
                // サインアップへのナビゲーション
                Button(action: {
                    showSignUp = true
                }) {
                    Text("アカウントをお持ちでない方はこちら")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                .padding(.bottom, 40)
                
                Spacer()
            }
            .navigationBarHidden(true)
        }
        .alert("エラー", isPresented: $signInViewModel.isShowingAlert) {
            Button("OK") {
                signInViewModel.clearError()
            }
        } message: {
            Text(signInViewModel.errorMessage ?? "")
        }
        .sheet(isPresented: $showSignUp) {
            SimpleSignUpView()
        }
    }
}

#Preview {
    SignInView()
        .environmentObject(DIContainer.shared.authViewModel)
}
