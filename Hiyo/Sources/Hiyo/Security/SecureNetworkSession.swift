//
//  SecureNetworkSession.swift
//  Hiyo
//
//  Note: Hiyo uses local MLX only - this is for future extensibility
//  and defense-in-depth. All network requests are blocked by default.
//

import Foundation

final class SecureNetworkSession: NSObject {
    static let shared = SecureNetworkSession()
    
    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.ephemeral
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        config.urlCache = nil
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 300
        config.httpMaximumConnectionsPerHost = 0 // Block by default
        config.waitsForConnectivity = false
        config.urlCredentialPersistence = .none
        config.httpCookieAcceptPolicy = .never
        config.httpShouldSetCookies = false
        
        return URLSession(
            configuration: config,
            delegate: self,
            delegateQueue: .main
        )
    }()
    
    /// Performs request with strict validation
    /// NOTE: Hiyo should not make network requests - this is for defense
    func performRequest(_ request: URLRequest) async throws -> (Data, URLResponse) {
        // Reject all requests by default
        throw NetworkError.networkDisabled
        
        // The following is defense-in-depth if network were ever enabled:
        /*
        guard let url = request.url,
              let host = url.host?.lowercased() else {
            throw NetworkError.invalidURL
        }
        
        // Strict allowlist
        let allowedHosts: [String] = [] // Empty - no external connections
        guard allowedHosts.contains(host) else {
            SecurityLogger.log(.sandboxEscapeAttempt, details: "Blocked: \(host)")
            throw NetworkError.connectionBlocked
        }
        
        return try await session.data(for: request)
        */
    }
}

extension SecureNetworkSession: URLSessionDelegate, URLSessionTaskDelegate {
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge) async -> (URLSession.AuthChallengeDisposition, URLCredential?) {
        // Reject all authentication challenges
        return (.cancelAuthenticationChallenge, nil)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest) async -> URLRequest? {
        // Block all redirects
        return nil
    }
}

enum NetworkError: Error {
    case networkDisabled
    case invalidURL
    case connectionBlocked
    case nonLocalhostConnection
    case invalidPort
    case invalidScheme
    case suspiciousPath
    case invalidResponse
    case responseTooLarge
    case invalidConfiguration
}
