//
//  Network.swift
//  wodAI
//
//  Enhanced Network layer with automatic logout on unauthorized responses
//

import Foundation
import Apollo
import WodAiAPI
import SwiftUI

class Network {
    static let shared = Network()
    let graphql = "http://localhost:3000/graphql"
    
    // Use a custom initializer for Apollo client with authorization header
    private(set) lazy var client: ApolloClient = {
        let url = URL(string: graphql)!
        
        // Create a custom transport with authorization header
        let transport = RequestChainNetworkTransport(
            interceptorProvider: NetworkInterceptorProvider(),
            endpointURL: url
        )
        
        return ApolloClient(networkTransport: transport, store: ApolloStore())
    }()
}

// Simplified authorization interceptor - GraphQL errors only
class AuthorizationInterceptor: ApolloInterceptor {
    var id: String = "AuthorizationInterceptor"
    
    let authManager: AuthManager = AuthManager()
    
    func interceptAsync<Operation>(
        chain: RequestChain,
        request: HTTPRequest<Operation>,
        response: HTTPResponse<Operation>?,
        completion: @escaping (Result<GraphQLResult<Operation.Data>, Error>) -> Void
    ) where Operation: GraphQLOperation {
        
        // Add authorization header if token exists
        if let token = authManager.token {
            request.addHeader(name: "Authorization", value: "Bearer \(token)")
        }
        
        // Continue with the request
        chain.proceedAsync(request: request, response: response) { [weak self] result in
            switch result {
            case .success(let graphqlResult):
                // ONLY check for GraphQL authentication errors
                if let errors = graphqlResult.errors {
                    for error in errors {
                        if self?.isUnauthorizedGraphQLError(error) == true {
                            print("🔒 GraphQL Unauthorized Error: \(error.message ?? "")")
                            self?.handleUnauthorizedAccess()
                            break
                        }
                    }
                }
                completion(result)
                
            case .failure(let error):
                // Pass through all network errors without auth handling
                completion(result)
            }
        }
    }
    
    private func isUnauthorizedGraphQLError(_ error: GraphQLError) -> Bool {
        // Simple check: just look for "Unauthorized" in message
        return error.message?.contains("Unauthorized") == true
    }
    
    private func handleUnauthorizedAccess() {
        print("⚠️ Session expired. Logging user out...")
        
        DispatchQueue.main.async { [weak self] in
            self?.authManager.clearToken()
            NotificationCenter.default.post(name: .userDidLogout, object: nil)
        }
    }
}

// Simplified interceptor provider - no HTTP status code handling
class NetworkInterceptorProvider: InterceptorProvider {
    func interceptors<Operation>(for operation: Operation) -> [ApolloInterceptor] where Operation: GraphQLOperation {
        return [
            AuthorizationInterceptor(),
            NetworkFetchInterceptor(client: URLSessionClient()),
            ResponseCodeInterceptor(),  // Standard Apollo interceptor
            JSONResponseParsingInterceptor(),
            AutomaticPersistedQueryInterceptor()
        ]
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let userDidLogout = Notification.Name("userDidLogout")
}
