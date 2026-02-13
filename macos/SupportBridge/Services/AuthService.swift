import Foundation

struct AuthResponse: Decodable {
    let token: String
    let agent: Agent
}

struct SignupResponse: Decodable {
    let message: String?
    let agent: Agent
    let verificationRequired: Bool?
    let token: String?
    let expiresAt: Date?
}

struct ForgotPasswordResponse: Decodable {
    let message: String
    let token: String?
    let expiresAt: Date?
}

struct MessageResponse: Decodable {
    let message: String
}

final class AuthService {
    private let client: APIClient

    init(client: APIClient = .shared) {
        self.client = client
    }

    func login(email: String, password: String) async throws -> AuthResponse {
        struct Body: Encodable { let email: String; let password: String }
        return try await client.request("auth/login", method: .post, body: Body(email: email, password: password))
    }

    func signup(name: String, email: String, password: String) async throws -> SignupResponse {
        struct Body: Encodable { let name: String; let email: String; let password: String }
        return try await client.request("auth/register", method: .post, body: Body(name: name, email: email, password: password))
    }

    func verifyEmail(email: String, token: String) async throws -> AuthResponse {
        struct Body: Encodable { let email: String; let token: String }
        return try await client.request("auth/verify-email", method: .post, body: Body(email: email, token: token))
    }

    func resendVerification(email: String) async throws -> ForgotPasswordResponse {
        struct Body: Encodable { let email: String }
        return try await client.request("auth/resend-verification", method: .post, body: Body(email: email))
    }

    func forgotPassword(email: String) async throws -> ForgotPasswordResponse {
        struct Body: Encodable { let email: String }
        return try await client.request("auth/forgot-password", method: .post, body: Body(email: email))
    }

    func resetPassword(email: String, token: String, newPassword: String) async throws -> MessageResponse {
        struct Body: Encodable { let email: String; let token: String; let password: String }
        return try await client.request("auth/reset-password", method: .post, body: Body(email: email, token: token, password: newPassword))
    }
}
