import Combine
import Foundation
import AuthenticationServices
import CryptoKit

@MainActor
final class AuthManager: ObservableObject {
    static let shared = AuthManager()

    @Published var isAuthenticated = false
    @Published var userEmail: String?

    var clientID: String {
        let stored = UserDefaults.standard.string(forKey: AppSettings.Keys.oauthClientID) ?? ""
        return stored.isEmpty ? "YOUR_CLIENT_ID.apps.googleusercontent.com" : stored
    }

    private var redirectScheme: String {
        // Derive reverse-DNS scheme from clientID
        // e.g. "123-abc.apps.googleusercontent.com" → "com.googleusercontent.apps.123-abc"
        let withoutSuffix = clientID.replacingOccurrences(of: ".apps.googleusercontent.com", with: "")
        return "com.googleusercontent.apps.\(withoutSuffix)"
    }

    private var redirectURI: String { "\(redirectScheme):/oauth2redirect" }
    private let scope = "https://www.googleapis.com/auth/calendar.events email profile"
    private var codeVerifier = ""

    private var clientSecret: String {
        UserDefaults.standard.string(forKey: AppSettings.Keys.oauthClientSecret) ?? ""
    }

    init() {
        if let token = KeychainManager.shared.load(for: .accessToken), !token.isEmpty {
            isAuthenticated = true
        }
        userEmail = KeychainManager.shared.load(for: .userEmail)
    }

    func signIn(presentationContextProvider: ASWebAuthenticationPresentationContextProviding) async throws {
        codeVerifier = generateCodeVerifier()
        let codeChallenge = generateCodeChallenge(from: codeVerifier)

        var comps = URLComponents(string: "https://accounts.google.com/o/oauth2/v2/auth")!
        comps.queryItems = [
            URLQueryItem(name: "client_id",             value: clientID),
            URLQueryItem(name: "redirect_uri",          value: redirectURI),
            URLQueryItem(name: "response_type",         value: "code"),
            URLQueryItem(name: "scope",                 value: scope),
            URLQueryItem(name: "code_challenge",        value: codeChallenge),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "access_type",           value: "offline"),
            URLQueryItem(name: "prompt",                value: "consent")
        ]
        guard let authURL = comps.url else { throw AuthError.invalidURL }

        let callbackURL: URL = try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: authURL,
                callbackURLScheme: redirectScheme
            ) { url, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let url = url {
                    continuation.resume(returning: url)
                } else {
                    continuation.resume(throwing: AuthError.cancelled)
                }
            }
            session.presentationContextProvider = presentationContextProvider
            session.prefersEphemeralWebBrowserSession = false
            session.start()
        }

        guard let code = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)?
            .queryItems?.first(where: { $0.name == "code" })?.value
        else { throw AuthError.missingCode }

        try await exchangeCode(code)
    }

    func validAccessToken() async throws -> String {
        if let expiryStr = KeychainManager.shared.load(for: .tokenExpiry),
           let expiry = Double(expiryStr),
           Date().timeIntervalSince1970 < expiry - 60,
           let token = KeychainManager.shared.load(for: .accessToken) {
            return token
        }
        return try await refreshToken()
    }

    func signOut() {
        KeychainManager.shared.deleteAll()
        isAuthenticated = false
        userEmail = nil
    }

    // MARK: - Private

    private func exchangeCode(_ code: String) async throws {
        var params: [String: String] = [
            "code":          code,
            "client_id":     clientID,
            "redirect_uri":  redirectURI,
            "grant_type":    "authorization_code",
            "code_verifier": codeVerifier
        ]
        if !clientSecret.isEmpty { params["client_secret"] = clientSecret }
        let response = try await postToken(params)
        storeTokens(response)
    }

    private func refreshToken() async throws -> String {
        guard let refresh = KeychainManager.shared.load(for: .refreshToken) else {
            signOut()
            throw AuthError.notAuthenticated
        }
        var params: [String: String] = [
            "refresh_token": refresh,
            "client_id":     clientID,
            "grant_type":    "refresh_token"
        ]
        if !clientSecret.isEmpty { params["client_secret"] = clientSecret }
        let response = try await postToken(params)
        storeTokens(response)
        return response.accessToken
    }

    private func postToken(_ params: [String: String]) async throws -> TokenResponse {
        var request = URLRequest(url: URL(string: "https://oauth2.googleapis.com/token")!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = params
            .map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)" }
            .joined(separator: "&")
            .data(using: .utf8)
        let (data, _) = try await URLSession.shared.data(for: request)
        // Surface Google's error message before attempting to decode a token
        if let googleError = try? JSONDecoder().decode(GoogleErrorResponse.self, from: data),
           !googleError.error.isEmpty {
            throw AuthError.serverError("\(googleError.error): \(googleError.errorDescription ?? "")")
        }
        return try JSONDecoder().decode(TokenResponse.self, from: data)
    }

    private func storeTokens(_ response: TokenResponse) {
        KeychainManager.shared.save(response.accessToken, for: .accessToken)
        if let rt = response.refreshToken {
            KeychainManager.shared.save(rt, for: .refreshToken)
        }
        let expiry = Date().timeIntervalSince1970 + Double(response.expiresIn)
        KeychainManager.shared.save(String(expiry), for: .tokenExpiry)
        if let email = decodeEmail(from: response.idToken) {
            KeychainManager.shared.save(email, for: .userEmail)
            self.userEmail = email
        }
        isAuthenticated = true
    }

    private func decodeEmail(from idToken: String?) -> String? {
        guard let idToken else { return nil }
        let parts = idToken.split(separator: ".")
        guard parts.count == 3 else { return nil }
        var payload = String(parts[1])
        while payload.count % 4 != 0 { payload += "=" }
        let base64 = payload
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        guard let data = Data(base64Encoded: base64),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return nil }
        return json["email"] as? String
    }

    private func generateCodeVerifier() -> String {
        var bytes = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes).base64URLEncoded()
    }

    private func generateCodeChallenge(from verifier: String) -> String {
        Data(SHA256.hash(data: Data(verifier.utf8))).base64URLEncoded()
    }
}

// MARK: - Supporting Types

private struct TokenResponse: Codable {
    let accessToken: String
    let refreshToken: String?
    let expiresIn: Int
    let idToken: String?

    enum CodingKeys: String, CodingKey {
        case accessToken  = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn    = "expires_in"
        case idToken      = "id_token"
    }
}

enum AuthError: LocalizedError {
    case invalidURL, cancelled, missingCode, notAuthenticated, serverError(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:           return "Invalid authentication URL"
        case .cancelled:            return "Sign-in was cancelled"
        case .missingCode:          return "Authorization code not received"
        case .notAuthenticated:     return "Not signed in. Please sign in again."
        case .serverError(let msg): return "Google error: \(msg)"
        }
    }
}

private struct GoogleErrorResponse: Decodable {
    let error: String
    let errorDescription: String?
    enum CodingKeys: String, CodingKey {
        case error
        case errorDescription = "error_description"
    }
}

private extension Data {
    func base64URLEncoded() -> String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
