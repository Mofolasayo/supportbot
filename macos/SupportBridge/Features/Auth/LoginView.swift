import SwiftUI

struct LoginView: View {
    @EnvironmentObject var appState: AppState
    let onForgot: () -> Void
    let onSignup: () -> Void

    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        AuthLayout(title: "Sign in", subtitle: "Welcome back to SupportBridge") {
            VStack(spacing: Spacing.lg) {
                authField(label: "Email", placeholder: "you@company.com", text: $email)
                authSecureField(label: "Password", placeholder: "Enter your password", text: $password)

                Button(action: login) {
                    ZStack {
                        Text("Sign In")
                            .opacity(isLoading ? 0 : 1)
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .moltPrimary))
                                .scaleEffect(0.8)
                        }
                    }
                    .font(.moltBody)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color.moltPrimary)
                    .cornerRadius(CornerRadius.medium)
                }
                .buttonStyle(.plain)
                .disabled(isLoading || email.isEmpty || password.isEmpty)

                Button(action: onForgot) {
                    Text("Forgot password?")
                        .font(.moltCaption)
                        .foregroundColor(.moltPrimary)
                }
                .buttonStyle(.plain)

                Button(action: onSignup) {
                    HStack(spacing: 4) {
                        Text("New here?")
                            .foregroundColor(.moltTextMuted)
                        Text("Create an account")
                            .foregroundColor(.moltPrimary)
                    }
                    .font(.moltCaption)
                }
                .buttonStyle(.plain)
            }
        }
        .alert("Sign In Failed", isPresented: Binding(get: { errorMessage != nil }, set: { _ in errorMessage = nil })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "Unable to sign in")
        }
    }

    private func login() {
        isLoading = true
        _Concurrency.Task {
            do {
                try await appState.login(email: email, password: password)
                await MainActor.run { isLoading = false }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}
