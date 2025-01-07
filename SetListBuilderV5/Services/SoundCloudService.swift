import Foundation

enum SoundCloudError: Error {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case unauthorized
    case rateLimitExceeded
    case serverError
    case tokenError(String)
    case invalidClient(String)
}

@MainActor
class SoundCloudService: ObservableObject {
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?
    
    private let clientID: String
    private let clientSecret: String
    private let baseURL = "https://api.soundcloud.com"
    private var currentToken: String?
    private var tokenExpirationTask: Task<Void, Never>?
    
    private func log(_ message: String) {
        print("SoundCloudService: \(message)")
    }
    
    init(clientID: String = "gaTdNaXk721Z3MmxY5iGIqR9Oi2NjuGH", 
         clientSecret: String = "EGDRIozPLoVws5VTvFjgSBTOwbfrSicm") {
        self.clientID = clientID.trimmingCharacters(in: .whitespacesAndNewlines)
        self.clientSecret = clientSecret.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    deinit {
        tokenExpirationTask?.cancel()
    }
    
    private func getClientCredentialsToken() async throws -> String {
        // If we already have a token, return it
        if let token = currentToken {
            return token
        }
        
        let url = URL(string: "\(baseURL)/oauth2/token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        // Format according to SoundCloud's example
        let bodyString = "client_id=\(clientID)&client_secret=\(clientSecret)&grant_type=client_credentials"
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        request.httpBody = bodyString.data(using: .utf8)
        
        log("Token Request URL: \(url)")
        log("Token Request Body: \(bodyString)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SoundCloudError.networkError(NSError(domain: "", code: -1))
        }
        
        log("Token Response Status Code: \(httpResponse.statusCode)")
        if let responseString = String(data: data, encoding: .utf8) {
            log("Token Response: \(responseString)")
            
            // Check for specific error responses
            if httpResponse.statusCode == 401 {
                struct ErrorResponse: Codable {
                    let code: Int
                    let message: String
                    let error_code: String?
                }
                
                if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data),
                   errorResponse.error_code == "invalid_client" {
                    throw SoundCloudError.invalidClient("Invalid client credentials. Please check your client ID and secret.")
                }
            }
        }
        
        if httpResponse.statusCode == 200 {
            struct TokenResponse: Codable {
                let access_token: String
                let expires_in: Int
            }
            
            let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
            currentToken = tokenResponse.access_token
            
            // Cancel any existing expiration task
            tokenExpirationTask?.cancel()
            
            // Schedule token refresh before expiration
            tokenExpirationTask = Task { [weak self] in
                try? await Task.sleep(nanoseconds: UInt64((tokenResponse.expires_in - 300) * 1_000_000_000))
                await MainActor.run { [weak self] in
                    self?.currentToken = nil
                }
            }
            
            return tokenResponse.access_token
        } else {
            if let errorString = String(data: data, encoding: .utf8) {
                throw SoundCloudError.tokenError(errorString)
            }
            throw SoundCloudError.unauthorized
        }
    }
    
    func searchTracks(bpmRange: ClosedRange<Double>, genre: String) async throws -> [Track] {
        let token = try await getClientCredentialsToken()
        
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.soundcloud.com"
        components.path = "/tracks"
        
        var queryItems = [
            URLQueryItem(name: "limit", value: "50")
        ]
        
        if bpmRange.lowerBound > 0 {
            queryItems.append(URLQueryItem(name: "bpm[from]", value: String(Int(bpmRange.lowerBound))))
            queryItems.append(URLQueryItem(name: "bpm[to]", value: String(Int(bpmRange.upperBound))))
        }
        
        if genre != "All" {
            queryItems.append(URLQueryItem(name: "genres", value: genre.lowercased()))
        }
        
        components.queryItems = queryItems
        
        guard let url = components.url else {
            log("Failed to create search URL")
            throw SoundCloudError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("OAuth \(token)", forHTTPHeaderField: "Authorization")
        
        log("Search Request URL: \(url)")
        log("Search Request Headers: \(request.allHTTPHeaderFields ?? [:])")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                log("Invalid response type")
                throw SoundCloudError.networkError(NSError(domain: "", code: -1))
            }
            
            log("Search Response Status Code: \(httpResponse.statusCode)")
            
            if let responseString = String(data: data, encoding: .utf8) {
                log("Search Response: \(responseString)")
            }
            
            switch httpResponse.statusCode {
            case 200:
                let decoder = JSONDecoder()
                do {
                    let tracks = try decoder.decode([SoundCloudTrack].self, from: data)
                    return tracks.compactMap { $0.toTrack() }
                } catch {
                    log("Decoding Error: \(error)")
                    throw SoundCloudError.decodingError(error)
                }
            case 401:
                currentToken = nil // Clear the invalid token
                throw SoundCloudError.unauthorized
            case 429:
                throw SoundCloudError.rateLimitExceeded
            default:
                throw SoundCloudError.serverError
            }
        } catch {
            log("Search Error: \(error)")
            throw error
        }
    }
}

// SoundCloud API response model
private struct SoundCloudTrack: Codable {
    let id: Int
    let title: String
    let user: SoundCloudUser
    let genre: String?
    let bpm: Double?
    let duration: Int
    let artwork_url: String?
    let permalink_url: String
    
    func toTrack() -> Track? {
        guard let bpm = bpm else { return nil }
        
        return Track(
            id: String(id),
            title: title,
            artist: user.username,
            bpm: bpm,
            genre: genre ?? "Unknown",
            artworkURL: artwork_url,
            duration: duration,
            url: URL(string: permalink_url)
        )
    }
}

private struct SoundCloudUser: Codable {
    let username: String
}

extension SoundCloudError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL configuration"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .unauthorized:
            return "Authentication failed"
        case .rateLimitExceeded:
            return "Rate limit exceeded"
        case .serverError:
            return "Server error occurred"
        case .tokenError(let error):
            return "Token error: \(error)"
        case .invalidClient(let message):
            return "Invalid client: \(message)"
        }
    }
} 
