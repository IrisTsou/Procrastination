import Foundation
import Combine
import Supabase

@MainActor
final class AuthViewModel: ObservableObject {

    // MARK: - 綁定給畫面的欄位（登入 / 註冊表單）
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var displayName: String = ""

    // MARK: - Auth 狀態
    @Published var currentUser: AppUser?
    @Published var didJustRegister: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    // 🔥 AppStore：註冊 / 登入 / 自動登入 時要切換 snapshot 用
    private let store: AppStore

    init(store: AppStore) {
        self.store = store
    }

    // MARK: - Register（註冊）
    func register() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            print("[AuthViewModel.register] start signUp email=\(email)")

            // ✅ 交給 AuthService 處理 Supabase → AppUser
            let appUser = try await AuthService.register(
                email: email,
                displayName: displayName,
                password: password
            )

            print("[AuthViewModel.register] success user id=\(appUser.id)")

            // 更新 Auth 狀態
            self.currentUser = appUser
            self.didJustRegister = true

            // 🔁 切換到該使用者的 snapshot（會從 Supabase 抓雲端資料）
            await store.switchUser(to: appUser.id.uuidString)

        } catch let authError as AppAuthError {
            self.errorMessage = authError.errorDescription
        } catch {
            print("[AuthViewModel.register] error detail:", error)
            self.errorMessage = "伺服器錯誤，請稍後再試"
        }
    }

    // MARK: - Login（UI 用）

    func login() async {
        await login(email: email, password: password)
    }

    // MARK: - Login（實際邏輯）

    func login(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let user = try await AuthService.login(
                email: email,
                password: password
            )

            print("[AuthViewModel.login] success: \(user.id)")

            self.currentUser = user
            self.didJustRegister = false

            // ⬇️ 只做一件事：切換到這個 user 的 snapshot
            await store.switchUser(to: user.id.uuidString)

        } catch let authError as AppAuthError {
            self.errorMessage = authError.errorDescription
        } catch {
            print("[AuthViewModel.login] error:", error)
            self.errorMessage = "伺服器錯誤，請稍後再試"
        }
    }

    // MARK: - Auto Login on App Launch

    /// App 啟動時呼叫：如果 Supabase 裡還有有效 session，就自動登入
    func restoreSessionOnLaunch() async {
        isLoading = true
        defer { isLoading = false }

        do {
            if let user = try await AuthService.getCurrentUser() {
                print("[AuthViewModel] restoreSessionOnLaunch: got user \(user.id)")

                self.currentUser = user
                self.didJustRegister = false
                self.email = user.email

                // ⬇️ 直接切換到這個 user 的 snapshot（從雲端載入）
                await store.switchUser(to: user.id.uuidString)
            } else {
                print("[AuthViewModel] restoreSessionOnLaunch: no active session")
                self.currentUser = nil
                // 沒有 user → 切到空狀態
                await store.switchUser(to: nil)
            }
        } catch {
            print("[AuthViewModel] restoreSessionOnLaunch error:", error)
            self.currentUser = nil
            await store.switchUser(to: nil)
        }
    }

    // MARK: - Logout

    func logout() async {
        await AuthService.logout()
        self.currentUser = nil
        self.didJustRegister = false

        // 登出後清空表單欄位
        self.email = ""
        self.password = ""
        self.displayName = ""

        // 🔁 切回 empty snapshot（不會動到雲端資料）
        await store.switchUser(to: nil)

        print("[AuthViewModel.logout] done")
    }
}
