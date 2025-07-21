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
        #if DEBUG
        return "http://localhost:3000/graphql"
        #else
        return "https://move-adapt.com/graphql"
        #endif
    }
    
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
