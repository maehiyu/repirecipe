import SwiftUI

struct MainView: View {
    @StateObject private var authViewModel = DIContainer.shared.authViewModel
    
    var body: some View {
        Group {
            // モック環境のため、常にサインイン済みとしてメインコンテンツを表示
            MainContentView()
                .environmentObject(authViewModel)
            
            // 実際のサインイン機能を使用する場合は以下のコードを有効化
            /*
            if authViewModel.isSignedIn {
                // サインイン済みの場合はメインコンテンツを表示
                MainContentView()
                    .environmentObject(authViewModel)
            } else {
                // サインインしていない場合はサインイン画面を表示
                SignInView()
                    .environmentObject(authViewModel)
            }
            */
        }
        .onAppear {
            // モック環境のため認証チェックをスキップ
            // Task {
            //     await authViewModel.checkAuthStatus()
            // }
        }
    }
}

#Preview {
    MainView()
}
