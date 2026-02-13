import SwiftUI

enum AuthScreen {
    case login
    case signup
    case signupVerify
    case forgotPassword
    case resetSent
    case resetPassword
}

struct AuthFlowView: View {
    @EnvironmentObject var appState: AppState
    @State private var screen: AuthScreen = .login
    @State private var resetEmail = ""
    @State private var resetToken = ""
    @State private var signupEmail = ""

    var body: some View {
        Group {
            switch screen {
            case .login:
                LoginView(
                    onForgot: { screen = .forgotPassword },
                    onSignup: { screen = .signup }
                )
            case .signup:
                SignupView(
                    onSignIn: { screen = .login },
                    onVerify: { email, _ in
                        signupEmail = email
                        screen = .signupVerify
                    }
                )
            case .signupVerify:
                VerifyOTPView(
                    email: signupEmail,
                    onBack: { screen = .signup },
                    onVerified: { screen = .login }
                )
            case .forgotPassword:
                ForgotPasswordView(
                    email: $resetEmail,
                    onBack: { screen = .login },
                    onSent: { token in
                        resetToken = token ?? ""
                        screen = .resetSent
                    }
                )
            case .resetSent:
                ResetSentView(
                    email: resetEmail,
                    token: resetToken,
                    onBackToLogin: { screen = .login },
                    onResetNow: { screen = .resetPassword }
                )
            case .resetPassword:
                ResetPasswordView(
                    email: resetEmail,
                    prefillToken: resetToken,
                    onBack: { screen = .login },
                    onComplete: { screen = .login }
                )
            }
        }
    }
}

// MARK: - Signup View
struct SignupView: View {
    @EnvironmentObject var appState: AppState
    let onSignIn: () -> Void
    let onVerify: (String, String?) -> Void

    @State private var fullName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var showMismatch = false
    @State private var errorMessage: String?

    var body: some View {
        AuthLayout(title: "Create your account", subtitle: "Get started with SupportBridge") {
            VStack(spacing: Spacing.lg) {
                authField(label: "Full Name", placeholder: "e.g. Your Name", text: $fullName)
                authField(label: "Email", placeholder: "you@company.com", text: $email)
                authSecureField(label: "Password", placeholder: "Create a password", text: $password)
                authSecureField(label: "Confirm Password", placeholder: "Re-enter your password", text: $confirmPassword)

                if showMismatch {
                    Text("Passwords do not match")
                        .font(.moltCaption)
                        .foregroundColor(.priorityHigh)
                }

                Button(action: signUp) {
                    ZStack {
                        Text("Sign Up")
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
                .disabled(isLoading || !canSubmit)

                Button(action: onSignIn) {
                    HStack(spacing: 4) {
                        Text("Already have an account?")
                            .foregroundColor(.moltTextMuted)
                        Text("Sign In")
                            .foregroundColor(.moltPrimary)
                    }
                    .font(.moltCaption)
                }
                .buttonStyle(.plain)
            }
        }
        .alert("Sign Up Failed", isPresented: Binding(get: { errorMessage != nil }, set: { _ in errorMessage = nil })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "Unable to sign up")
        }
    }

    private var canSubmit: Bool {
        !fullName.isEmpty && !email.isEmpty && !password.isEmpty && password == confirmPassword
    }

    private func signUp() {
        showMismatch = password != confirmPassword
        guard !showMismatch else { return }

        isLoading = true
        _Concurrency.Task {
            do {
                let response = try await appState.signup(name: fullName, email: email, password: password)
                await MainActor.run {
                    isLoading = false
                    onVerify(email, response.token)
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

// MARK: - Signup Verification View
struct VerifyOTPView: View {
    @EnvironmentObject var appState: AppState
    let email: String
    let onBack: () -> Void
    let onVerified: () -> Void

    @State private var code = ""
    @State private var isLoading = false
    @State private var resendMessage: String?
    @State private var errorMessage: String?

    var body: some View {
        AuthLayout(title: "Verify your email", subtitle: "Enter the 6-digit code we sent") {
            VStack(spacing: Spacing.lg) {
                if !email.isEmpty {
                    Text("Code sent to \(email)")
                        .font(.moltCaption)
                        .foregroundColor(.moltTextMuted)
                }

                authField(label: "Verification Code", placeholder: "Enter code", text: $code)

                Button(action: verify) {
                    ZStack {
                        Text("Verify")
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
                .disabled(code.isEmpty || isLoading)

                Button(action: resend) {
                    Text("Resend code")
                        .font(.moltCaption)
                        .foregroundColor(.moltPrimary)
                }
                .buttonStyle(.plain)

                if let message = resendMessage {
                    Text(message)
                        .font(.moltCaption)
                        .foregroundColor(.moltTextMuted)
                }

                Button(action: onBack) {
                    Text("Back to Sign Up")
                        .font(.moltCaption)
                        .foregroundColor(.moltPrimary)
                }
                .buttonStyle(.plain)
            }
        }
        .alert("Verification Failed", isPresented: Binding(get: { errorMessage != nil }, set: { _ in errorMessage = nil })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "Unable to verify code")
        }
    }

    private func verify() {
        guard !code.isEmpty else { return }
        isLoading = true
        _Concurrency.Task {
            do {
                try await appState.verifyEmail(email: email, token: code)
                await MainActor.run {
                    isLoading = false
                    onVerified()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func resend() {
        guard !email.isEmpty else { return }
        _Concurrency.Task {
            do {
                let response = try await appState.resendVerification(email: email)
                await MainActor.run {
                    resendMessage = response.message
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

// MARK: - Forgot Password View
struct ForgotPasswordView: View {
    @EnvironmentObject var appState: AppState
    @Binding var email: String
    let onBack: () -> Void
    let onSent: (String?) -> Void

    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        AuthLayout(title: "Forgot password?", subtitle: "We'll send you a reset link") {
            VStack(spacing: Spacing.lg) {
                authField(label: "Email", placeholder: "you@company.com", text: $email)

                Button(action: sendResetLink) {
                    ZStack {
                        Text("Send Reset Link")
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
                .disabled(isLoading || email.isEmpty)

                Button(action: onBack) {
                    Text("Back to Sign In")
                        .font(.moltCaption)
                        .foregroundColor(.moltPrimary)
                }
                .buttonStyle(.plain)
            }
        }
        .alert("Reset Failed", isPresented: Binding(get: { errorMessage != nil }, set: { _ in errorMessage = nil })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "Unable to request reset")
        }
    }

    private func sendResetLink() {
        isLoading = true
        _Concurrency.Task {
            do {
                let response = try await appState.requestPasswordReset(email: email)
                await MainActor.run {
                    isLoading = false
                    onSent(response.token)
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

// MARK: - Reset Sent View
struct ResetSentView: View {
    let email: String
    let token: String
    let onBackToLogin: () -> Void
    let onResetNow: () -> Void

    var body: some View {
        AuthLayout(title: "Check your inbox", subtitle: "Reset instructions sent") {
            VStack(spacing: Spacing.lg) {
                Text("We sent a password reset link to:")
                    .font(.moltBody)
                    .foregroundColor(.moltTextSecondary)

                Text(email.isEmpty ? "your email" : email)
                    .font(.moltBody)
                    .fontWeight(.medium)
                    .foregroundColor(.moltTextPrimary)

                if !token.isEmpty {
                    VStack(spacing: 4) {
                        Text("Dev reset code")
                            .font(.moltCaption)
                            .foregroundColor(.moltTextMuted)
                        Text(token)
                            .font(.moltCaption)
                            .foregroundColor(.moltTextPrimary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(Spacing.sm)
                    .background(Color.moltSurfaceSecondary)
                    .cornerRadius(CornerRadius.small)
                }

                Button(action: onResetNow) {
                    Text("I have a reset code")
                        .font(.moltBody)
                        .fontWeight(.medium)
                        .foregroundColor(.moltPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color.moltPrimaryLight)
                        .cornerRadius(CornerRadius.medium)
                }
                .buttonStyle(.plain)

                Button(action: onBackToLogin) {
                    Text("Back to Sign In")
                        .font(.moltCaption)
                        .foregroundColor(.moltPrimary)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Reset Password View
struct ResetPasswordView: View {
    @EnvironmentObject var appState: AppState
    let email: String
    let prefillToken: String
    let onBack: () -> Void
    let onComplete: () -> Void

    @State private var token = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var showMismatch = false
    @State private var errorMessage: String?

    var body: some View {
        AuthLayout(title: "Reset password", subtitle: "Create a new password") {
            VStack(spacing: Spacing.lg) {
                if !email.isEmpty {
                    Text("Reset for \(email)")
                        .font(.moltCaption)
                        .foregroundColor(.moltTextMuted)
                }

                authField(label: "Reset Code", placeholder: "Enter code from email", text: $token)
                authSecureField(label: "New Password", placeholder: "Enter new password", text: $password)
                authSecureField(label: "Confirm Password", placeholder: "Re-enter new password", text: $confirmPassword)

                if showMismatch {
                    Text("Passwords do not match")
                        .font(.moltCaption)
                        .foregroundColor(.priorityHigh)
                }

                Button(action: resetPassword) {
                    ZStack {
                        Text("Reset Password")
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
                .disabled(isLoading || token.isEmpty || !canSubmit)

                Button(action: onBack) {
                    Text("Back to Sign In")
                        .font(.moltCaption)
                        .foregroundColor(.moltPrimary)
                }
                .buttonStyle(.plain)
            }
        }
        .onAppear {
            if token.isEmpty && !prefillToken.isEmpty {
                token = prefillToken
            }
        }
        .alert("Reset Failed", isPresented: Binding(get: { errorMessage != nil }, set: { _ in errorMessage = nil })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "Unable to reset password")
        }
    }

    private var canSubmit: Bool {
        !password.isEmpty && password == confirmPassword
    }

    private func resetPassword() {
        showMismatch = password != confirmPassword
        guard !showMismatch else { return }

        isLoading = true
        _Concurrency.Task {
            do {
                try await appState.resetPassword(email: email, token: token, newPassword: password)
                await MainActor.run {
                    isLoading = false
                    onComplete()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

// MARK: - Auth Layout + Fields
struct AuthLayout<Content: View>: View {
    let title: String
    let subtitle: String
    let content: Content

    init(title: String, subtitle: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }

    var body: some View {
        ZStack {
            Color.moltBackground
                .ignoresSafeArea()

            VStack(spacing: Spacing.xxl) {
                Spacer()

                VStack(spacing: Spacing.md) {
                    SupportBridgeLogo(height: 140)

                    Text("AI-Powered Customer Support")
                        .font(.moltBody)
                        .foregroundColor(.moltTextSecondary)
                }

                VStack(spacing: Spacing.lg) {
                    VStack(spacing: 4) {
                        Text(title)
                            .font(.moltTitleMedium)
                            .foregroundColor(.moltTextPrimary)
                        Text(subtitle)
                            .font(.moltCaption)
                            .foregroundColor(.moltTextMuted)
                    }

                    content
                }
                .padding(Spacing.xl)
                .background(Color.moltSurface)
                .cornerRadius(CornerRadius.large)
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
                .frame(maxWidth: 520)
                .accentColor(.moltTextPrimary)

                Spacer()

                Text("© 2026 SupportBridge. All rights reserved.")
                    .font(.moltCaption)
                    .foregroundColor(.moltTextMuted)
                    .padding(.bottom, Spacing.lg)
            }
            .padding(.horizontal, Spacing.xl)
        }
        .frame(minWidth: 640, minHeight: 700)
    }
}

@ViewBuilder
func authField(label: String, placeholder: String, text: Binding<String>) -> some View {
    VStack(alignment: .leading, spacing: Spacing.sm) {
        Text(label)
            .font(.moltLabel)
            .foregroundColor(.moltTextSecondary)

        TextField(placeholder, text: text)
            .textFieldStyle(.plain)
            .font(.moltBody)
            .foregroundColor(.moltTextPrimary)
            .tint(.moltTextPrimary)
            .padding(Spacing.md)
            .background(Color.moltSurfaceSecondary)
            .cornerRadius(CornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.medium)
                    .stroke(Color.moltBorder, lineWidth: 1)
            )
    }
}

@ViewBuilder
func authSecureField(label: String, placeholder: String, text: Binding<String>) -> some View {
    AuthPasswordField(label: label, placeholder: placeholder, text: text)
}

struct AuthPasswordField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    @State private var isVisible = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(label)
                .font(.moltLabel)
                .foregroundColor(.moltTextSecondary)

            ZStack(alignment: .trailing) {
                Group {
                    if isVisible {
                        TextField(placeholder, text: $text)
                    } else {
                        SecureField(placeholder, text: $text)
                    }
                }
                .textFieldStyle(.plain)
                .font(.moltBody)
                .foregroundColor(.moltTextPrimary)
                .tint(.moltTextPrimary)
                .padding(Spacing.md)
                .padding(.trailing, 28)
                .background(Color.moltSurfaceSecondary)
                .cornerRadius(CornerRadius.medium)
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.medium)
                        .stroke(Color.moltBorder, lineWidth: 1)
                )

                Button(action: { isVisible.toggle() }) {
                    Image(systemName: isVisible ? "eye.slash" : "eye")
                        .foregroundColor(.moltTextMuted)
                        .font(.system(size: 14, weight: .regular))
                }
                .buttonStyle(.plain)
                .padding(.trailing, Spacing.md)
                .accessibilityLabel(isVisible ? "Hide password" : "Show password")
            }
        }
    }
}
