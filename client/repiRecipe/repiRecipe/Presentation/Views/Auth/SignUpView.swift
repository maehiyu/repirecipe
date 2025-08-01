import SwiftUI

struct SignUpView: View {
    @StateObject private var signUpViewModel = DIContainer.shared.signUpViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var confirmPassword = ""
    @State private var isConfirmPasswordVisible = false
    
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
                }
                .padding(.top, 20)
                
                ScrollView {
                    VStack(spacing: 16) {
                        // メールアドレス入力
                        VStack(alignment: .leading, spacing: 8) {
                            Text("メールアドレス")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            TextField("メールアドレスを入力", text: $signUpViewModel.email)
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
                                    if signUpViewModel.isPasswordVisible {
                                        TextField("パスワードを入力", text: $signUpViewModel.password)
                                    } else {
                                        SecureField("パスワードを入力", text: $signUpViewModel.password)
                                    }
                                }
                                .textContentType(.newPassword)
                                
                                Button(action: {
                                    signUpViewModel.isPasswordVisible.toggle()
                                }) {
                                    Image(systemName: signUpViewModel.isPasswordVisible ? "eye.slash" : "eye")
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                        
                        // パスワード確認入力
                        VStack(alignment: .leading, spacing: 8) {
                            Text("パスワード確認")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            HStack {
                                Group {
                                    if isConfirmPasswordVisible {
                                        TextField("パスワードを再入力", text: $confirmPassword)
                                    } else {
                                        SecureField("パスワードを再入力", text: $confirmPassword)
                                    }
                                }
                                .textContentType(.newPassword)
                                
                                Button(action: {
                                    isConfirmPasswordVisible.toggle()
                                }) {
                                    Image(systemName: isConfirmPasswordVisible ? "eye.slash" : "eye")
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                        
                        // パスワード要件
                        VStack(alignment: .leading, spacing: 4) {
                            Text("パスワード要件:")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            
                            Text("• 8文字以上")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal, 24)
                }
                
                // サインアップボタン
                Button(action: {
                    Task {
                        await signUpViewModel.signUp()
                    }
                }) {
                    HStack {
                        if signUpViewModel.isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                                .foregroundColor(.white)
                        }
                        
                        Text("アカウント作成")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        isFormValid ? Color.orange : Color.gray
                    )
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(!isFormValid || signUpViewModel.isLoading)
                .padding(.horizontal, 24)
                
                Spacer()
            }
            .navigationTitle("サインアップ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
            }
        }
        .alert("エラー", isPresented: $signUpViewModel.isShowingAlert) {
            Button("OK") {
                signUpViewModel.clearError()
            }
        } message: {
            Text(signUpViewModel.errorMessage ?? "")
        }
        .alert("アカウント作成完了", isPresented: $signUpViewModel.isShowingSuccess) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("アカウントが作成されました。サインインしてください。")
        }
    }
    
    private var isFormValid: Bool {
        !signUpViewModel.email.isEmpty &&
        !signUpViewModel.password.isEmpty &&
        !confirmPassword.isEmpty &&
        signUpViewModel.password == confirmPassword &&
        signUpViewModel.password.count >= 8
    }
}

#Preview {
    SignUpView()
}