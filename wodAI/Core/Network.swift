//
//  Network.swift
//  wodAI
//
//  Enhanced Network layer with automatic logout on unauthorized responses
//  and environment-specific GraphQL endpoints
//

import Foundation
import Apollo
import WodAiAPI
import SwiftUI
import Combine

class Network {
    static let shared = Network()
    
    // Use AppConfig for environment-specific endpoint
    private var graphQLEndpoint: String {
        return AppConfig.graphQLEndpoint
    }
    
    // Use a custom initializer for Apollo client with authorization header
    private(set) lazy var client: ApolloClient = {
        let url = URL(string: graphQLEndpoint)!
        
        // Print configuration in debug builds
        if AppConfig.enableLogging {
            print("🔧 WodAI GraphQL Endpoint: \(graphQLEndpoint)")
        }
        
        // Create a custom transport with authorization header
        let transport = RequestChainNetworkTransport(
            interceptorProvider: NetworkInterceptorProvider(),
            endpointURL: url
        )
        
        return ApolloClient(networkTransport: transport, store: ApolloStore())
    }()
}

// Updated authorization interceptor using dependency injection
class AuthorizationInterceptor: ApolloInterceptor {
    var id: String = "AuthorizationInterceptor"
    
    // MARK: - Dependencies
    private let tokenProvider: TokenProvider
    private let authProvider: AuthenticationProvider
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(tokenProvider: TokenProvider = AuthState.shared, 
         authProvider: AuthenticationProvider = AuthState.shared) {
        self.tokenProvider = tokenProvider
        self.authProvider = authProvider
    }
    
    func interceptAsync<Operation>(
        chain: RequestChain,
        request: HTTPRequest<Operation>,
        response: HTTPResponse<Operation>?,
        completion: @escaping (Result<GraphQLResult<Operation.Data>, Error>) -> Void
    ) where Operation: GraphQLOperation {
        
        // Add authorization header if token exists
        if let token = tokenProvider.currentToken {
            request.addHeader(name: "Authorization", value: "Bearer \(token)")
        }
        
        // Continue with the request
        chain.proceedAsync(request: request, response: response, interceptor: self, completion: { [weak self] result in
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
                // Log network errors in debug mode
                if AppConfig.enableLogging {
                    print("🌐 Network Error: \(error.localizedDescription)")
                    print("   Endpoint: \(AppConfig.graphQLEndpoint)")
                }
                // Pass through all network errors without auth handling
                completion(result)
            }
        })
    }
    
    private func isUnauthorizedGraphQLError(_ error: GraphQLError) -> Bool {
        // Check for various unauthorized patterns
        let message = error.message?.lowercased() ?? ""
        return message.contains("unauthorized") || 
               message.contains("auth") || 
               message.contains("token") ||
               message == "unauthorized" ||
               error.message == "Unauthorized"
    }
    
    private func handleUnauthorizedAccess() {
        print("⚠️ Session expired. Redirecting to login...")
        
        DispatchQueue.main.async { [weak self] in
            self?.authProvider.handleSessionExpired()
            NotificationCenter.default.post(name: .userDidLogout, object: nil)
        }
    }
}

// Updated interceptor provider using dependency injection
class NetworkInterceptorProvider: InterceptorProvider {
    private let authorizationInterceptor: AuthorizationInterceptor
    
    init(authorizationInterceptor: AuthorizationInterceptor = AuthorizationInterceptor()) {
        self.authorizationInterceptor = authorizationInterceptor
    }
    
    func interceptors<Operation>(for operation: Operation) -> [ApolloInterceptor] where Operation: GraphQLOperation {
        return [
            authorizationInterceptor,
            NetworkFetchInterceptor(client: URLSessionClient()),
            ResponseCodeInterceptor(),  // Standard Apollo interceptor
            JSONResponseParsingInterceptor(),
            AutomaticPersistedQueryInterceptor()
        ]
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let workoutCompleted = Notification.Name("workoutCompleted")
}
