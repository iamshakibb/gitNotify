import Foundation

// MARK: - GitHub API Service

/// Service for interacting with GitHub's REST API
/// Using actor to ensure thread-safe access to mutable state
actor GitHubAPIService {
    static nonisolated let shared = GitHubAPIService()
    
    private let baseURL = "https://api.github.com"
    private let apiVersion = "2022-11-28"
    private let session: URLSession
    
    /// Last-Modified header for efficient polling
    private var lastModified: String?
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    // MARK: - Public API
    
    /// Fetch all notifications for the authenticated user
    /// - Parameters:
    ///   - token: GitHub Personal Access Token
    ///   - all: If true, includes read notifications
    ///   - since: Only show notifications updated after this date
    /// - Returns: Array of notifications
    func fetchNotifications(
        token: String,
        all: Bool = false,
        since: Date? = nil,
        useLastModified: Bool = true
    ) async throws -> FetchResult {
        var components = URLComponents(string: "\(baseURL)/notifications")!
        
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "all", value: String(all)),
            URLQueryItem(name: "per_page", value: "50")
        ]
        
        if let since = since {
            let formatter = ISO8601DateFormatter()
            queryItems.append(URLQueryItem(name: "since", value: formatter.string(from: since)))
        }
        
        components.queryItems = queryItems
        
        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"
        configureHeaders(for: &request, token: token)
        
        // Use If-Modified-Since for efficient polling
        if useLastModified, let lastModified = lastModified {
            request.setValue(lastModified, forHTTPHeaderField: "If-Modified-Since")
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GitHubAPIError.invalidResponse
        }
        
        // Store Last-Modified header for next request
        if let newLastModified = httpResponse.value(forHTTPHeaderField: "Last-Modified") {
            self.lastModified = newLastModified
        }
        
        // Handle 304 Not Modified - no new notifications
        if httpResponse.statusCode == 304 {
            return FetchResult(notifications: [], notModified: true, pollInterval: extractPollInterval(from: httpResponse))
        }
        
        try validateResponse(httpResponse)
        
        let decoder = JSONDecoder()
        let dtos = try decoder.decode([GitHubNotificationDTO].self, from: data)
        let notifications = dtos.compactMap { $0.toDomainModel() }
        
        return FetchResult(
            notifications: notifications,
            notModified: false,
            pollInterval: extractPollInterval(from: httpResponse)
        )
    }
    
    /// Mark a single notification thread as read
    /// - Parameters:
    ///   - threadId: The notification thread ID
    ///   - token: GitHub Personal Access Token
    func markThreadAsRead(threadId: String, token: String) async throws {
        let url = URL(string: "\(baseURL)/notifications/threads/\(threadId)")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        configureHeaders(for: &request, token: token)
        
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GitHubAPIError.invalidResponse
        }
        
        // 205 Reset Content is success for this endpoint
        guard httpResponse.statusCode == 205 || httpResponse.statusCode == 304 else {
            throw GitHubAPIError.httpError(statusCode: httpResponse.statusCode)
        }
    }
    
    /// Mark all notifications as read
    /// - Parameter token: GitHub Personal Access Token
    func markAllAsRead(token: String, lastReadAt: Date? = nil) async throws {
        let url = URL(string: "\(baseURL)/notifications")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        configureHeaders(for: &request, token: token)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var body: [String: Any] = ["read": true]
        if let lastReadAt = lastReadAt {
            let formatter = ISO8601DateFormatter()
            body["last_read_at"] = formatter.string(from: lastReadAt)
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GitHubAPIError.invalidResponse
        }
        
        // 202 Accepted or 205 Reset Content are both success
        guard httpResponse.statusCode == 202 || httpResponse.statusCode == 205 else {
            throw GitHubAPIError.httpError(statusCode: httpResponse.statusCode)
        }
    }
    
    /// Validate the token by fetching user info
    /// - Parameter token: GitHub Personal Access Token
    /// - Returns: Username if valid
    func validateToken(_ token: String) async throws -> String {
        let url = URL(string: "\(baseURL)/user")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        configureHeaders(for: &request, token: token)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GitHubAPIError.invalidResponse
        }
        
        try validateResponse(httpResponse)
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let login = json?["login"] as? String else {
            throw GitHubAPIError.invalidToken
        }
        
        return login
    }
    
    /// Reset the Last-Modified header (for fresh fetch)
    func resetLastModified() {
        lastModified = nil
    }
    
    /// Update Last-Modified from stored value
    func setLastModified(_ value: String?) {
        lastModified = value
    }
    
    // MARK: - Private Helpers
    
    private func configureHeaders(for request: inout URLRequest, token: String) {
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(apiVersion, forHTTPHeaderField: "X-GitHub-Api-Version")
        request.setValue("GitNotify/1.0", forHTTPHeaderField: "User-Agent")
    }
    
    private func validateResponse(_ response: HTTPURLResponse) throws {
        switch response.statusCode {
        case 200..<300:
            return
        case 401:
            throw GitHubAPIError.unauthorized
        case 403:
            // Check for rate limiting
            if let remaining = response.value(forHTTPHeaderField: "X-RateLimit-Remaining"),
               remaining == "0" {
                throw GitHubAPIError.rateLimited
            }
            throw GitHubAPIError.forbidden
        case 404:
            throw GitHubAPIError.notFound
        default:
            throw GitHubAPIError.httpError(statusCode: response.statusCode)
        }
    }
    
    private func extractPollInterval(from response: HTTPURLResponse) -> Int? {
        if let interval = response.value(forHTTPHeaderField: "X-Poll-Interval") {
            return Int(interval)
        }
        return nil
    }
}

// MARK: - Fetch Result

struct FetchResult {
    let notifications: [GitHubNotification]
    let notModified: Bool
    let pollInterval: Int?
}

// MARK: - API Errors

enum GitHubAPIError: LocalizedError {
    case invalidResponse
    case invalidToken
    case unauthorized
    case forbidden
    case rateLimited
    case notFound
    case httpError(statusCode: Int)
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from GitHub API."
        case .invalidToken:
            return "The provided token is invalid."
        case .unauthorized:
            return "Authentication failed. Please check your token."
        case .forbidden:
            return "Access forbidden. Your token may lack the required permissions."
        case .rateLimited:
            return "GitHub API rate limit exceeded. Please try again later."
        case .notFound:
            return "The requested resource was not found."
        case .httpError(let statusCode):
            return "HTTP error with status code: \(statusCode)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .unauthorized, .invalidToken:
            return "Please update your GitHub token in Settings."
        case .forbidden:
            return "Ensure your token has the 'notifications' scope."
        case .rateLimited:
            return "GitHub limits API requests. The app will retry automatically."
        default:
            return nil
        }
    }
}
