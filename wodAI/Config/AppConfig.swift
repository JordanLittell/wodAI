//
//  AppConfig.swift
//  wodAI
//
//  Simple environment-specific configuration for GraphQL endpoints
//

import Foundation

struct AppConfig {
    
    // MARK: - GraphQL Endpoint
    static var graphQLEndpoint: String {
        // Try to read from Info.plist first
        if let endpoint = Bundle.main.object(forInfoDictionaryKey: "GRAPHQL_ENDPOINT") as? String {
            return endpoint
        }
        
        // Fallback based on build configuration
        return "https://api.wodai.run"
        
    }
    
    // MARK: - Sentry DSN
    static var sentryDSN: String {
        Bundle.main.object(forInfoDictionaryKey: "SENTRY_DSN") as? String ?? "https://5741d0c7fcb30adbe2e019fb37a1f972@o4511588501749760.ingest.us.sentry.io/4511588506468352"
    }

    // MARK: - PostHog
    // The project API key (phc_…) only sends events, so it's safe to ship in
    // the app, like the Sentry DSN above. Empty leaves analytics off.
    static var posthogAPIKey: String {
        Bundle.main.object(forInfoDictionaryKey: "POSTHOG_API_KEY") as? String ?? ""
    }

    static let posthogHost = "https://us.i.posthog.com"

    // MARK: - Environment Detection
    static var isProduction: Bool {
        #if DEBUG
        return false
        #else
        return true
        #endif
    }
    
    static var enableLogging: Bool {
        return !isProduction
    }
}
