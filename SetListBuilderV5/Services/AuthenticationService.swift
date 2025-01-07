import Foundation
import AuthenticationServices
import CryptoKit

private struct TokenResponse: Codable {
    let access_token: String
    let expires_in: Int
    let scope: String?
    let token_type: String
}

class AuthenticationService: NSObject, ObservableObject {
    @Published var isAuthenticated = false
    @Published var error: Error?
    
    private let clientID = "gaTdNaXk721Z3MmxY5iGIqR9Oi2NjuGH"
    private let clientSecret = "EGDRIozPLoVws5VTvFjgSBTOwbfrSicm"
    private let redirectURI = "setbuilder://callback"
    private var webAuthSession: ASWebAuthenticationSession?
    private var codeVerifier: String?
    private var presentationContext: ASWebAuthenticationPresentationContextProviding?
    
    func authenticate(from context: ASWebAuthenticationPresentationContextProviding) {
        self.presentationContext = context
        
        // Generate PKCE code verifier and challenge
        codeVerifier = generateCodeVerifier()
        guard let codeChallenge = generateCodeChallenge(from: codeVerifier!) else {
            error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to generate code challenge"])
            return
        }
        
        // Create the authorization URL
        var components = URLComponents(string: "https://secure.soundcloud.com/connect")!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "code_challenge", value: codeChallenge),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "state", value: UUID().uuidString),
            URLQueryItem(name: "scope", value: "non-expiring")
        ]
        
        guard let authURL = components.url else {
            error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid authorization URL"])
            return
        }
        
        // Initialize web authentication session
        webAuthSession = ASWebAuthenticationSession(
            url: authURL,
            callbackURLScheme: "setbuilder"
        ) { [weak self] callbackURL, error in
            guard let self = self else { return }
            
            if let error = error {
                DispatchQueue.main.async {
                    self.error = error
                }
                return
            }
            
            guard let callbackURL = callbackURL,
                  let code = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)?
                    .queryItems?
                    .first(where: { $0.name == "code" })?
                    .value
            else {
                DispatchQueue.main.async {
                    self.error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid callback URL"])
                }
                return
            }
            
            Task {
                do {
                    try await self.exchangeCodeForToken(code: code)
                    await MainActor.run {
                        self.isAuthenticated = true
                    }
                } catch {
                    await MainActor.run {
                        self.error = error
                    }
                }
            }
        }
        
        webAuthSession?.presentationContextProvider = context
        webAuthSession?.prefersEphemeralWebBrowserSession = true
        webAuthSession?.start()
    }
    
    private func exchangeCodeForToken(code: String) async throws {
        guard let url = URL(string: "https://api.soundcloud.com/oauth2/token") else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid token URL"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let params = [
            "grant_type": "authorization_code",
            "client_id": clientID,
            "client_secret": clientSecret,
            "redirect_uri": redirectURI,
            "code": code,
            "code_verifier": codeVerifier!
        ]
        
        let body = params.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
        request.httpBody = body.data(using: .utf8)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
        UserDefaults.standard.set(tokenResponse.access_token, forKey: "soundcloud_access_token")
    }
    
    // PKCE Helper Methods
    private func generateCodeVerifier() -> String {
        var bytes = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
            .trimmingCharacters(in: .whitespaces)
    }
    
    private func generateCodeChallenge(from verifier: String) -> String? {
        guard let data = verifier.data(using: .utf8) else { return nil }
        let hash = SHA256.hash(data: data)
        return Data(hash)
            .base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
            .trimmingCharacters(in: .whitespaces)
    }
}

extension AuthenticationService: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        ASPresentationAnchor()
    }
} 