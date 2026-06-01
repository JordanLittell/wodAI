//
//  Network.swift
//  wodAI
//
//  Enhanced Network layer with WebSocket support for subscriptions,
//  automatic logout on unauthorized responses, and environment-specific endpoints
//

import Foundation
import Apollo
import ApolloWebSocket
import WodAiAPI
import SwiftUI
import Combine

class Network {
    static let shared = Network()
    
    // MARK: - Configuration
    private var graphQLEndpoint: String {
        return AppConfig.graphQLEndpoint
    }
    
    private var webSocketEndpoint: String {
        return graphQLEndpoint
            .replacingOccurrences(of: "http://", with: "ws://")
            .replacingOccurrences(of: "https://", with: "wss://")
    }
    
    // MARK: - Apollo Client with WebSocket Support
    private(set) lazy var client: ApolloClient = {
        let url = URL(string: graphQLEndpoint)!
        let wsURL = URL(string: webSocketEndpoint)!
        
        if AppConfig.enableLogging {
            print("🔧 WodAI GraphQL Endpoint: \(graphQLEndpoint)")
            print("🔧 WodAI WebSocket Endpoint: \(webSocketEndpoint)")
        }
        
        // HTTP transport for queries and mutations
        let httpTransport = RequestChainNetworkTransport(
            interceptorProvider: NetworkInterceptorProvider(),
            endpointURL: url
        )
        
        // WebSocket transport for subscriptions
        let webSocket = WebSocket(
            url: wsURL,
            protocol: .graphql_transport_ws
        )
        
        let webSocketTransport = WebSocketTransport(
            websocket: webSocket
        )
        
        // Split transport: HTTP for queries/mutations, WebSocket for subscriptions
        let splitTransport = SplitNetworkTransport(
            uploadingNetworkTransport: httpTransport,
            webSocketNetworkTransport: webSocketTransport
        )
        
        return ApolloClient(networkTransport: splitTransport, store: ApolloStore())
    }()
    
    // MARK: - Auth Payload for WebSocket
    private var authPayload: [String: Any]? {
        guard let token = AuthState.shared.currentToken else { return nil }
        return ["Authorization": "Bearer \(token)"]
    }
    
    // MARK: - Reconnect WebSocket (e.g., after token refresh)
    func reconnectWebSocket() {
        // In Apollo iOS, we'd need to recreate the client to update the auth payload
        // For now, this is a placeholder - full implementation would require
        // managing the WebSocketTransport lifecycle
        if AppConfig.enableLogging {
            print("🔄 WebSocket reconnection requested")
        }
    }
}

// MARK: - Authorization Interceptor
class AuthorizationInterceptor: ApolloInterceptor {
    var id: String = "AuthorizationInterceptor"
    
    private let tokenProvider: TokenProvider
    private let authProvider: AuthenticationProvider
    private var cancellables = Set<AnyCancellable>()
    
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
                // Check for GraphQL authentication errors
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
                if AppConfig.enableLogging {
                    print("🌐 Network Error: \(error.localizedDescription)")
                    print("   Endpoint: \(AppConfig.graphQLEndpoint)")
                }
                completion(result)
            }
        })
    }
    
    private func isUnauthorizedGraphQLError(_ error: GraphQLError) -> Bool {
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

// MARK: - Interceptor Provider
class NetworkInterceptorProvider: InterceptorProvider {
    private let authorizationInterceptor: AuthorizationInterceptor
    
    init(authorizationInterceptor: AuthorizationInterceptor = AuthorizationInterceptor()) {
        self.authorizationInterceptor = authorizationInterceptor
    }
    
    func interceptors<Operation>(for operation: Operation) -> [ApolloInterceptor] where Operation: GraphQLOperation {
        return [
            authorizationInterceptor,
            NetworkFetchInterceptor(client: URLSessionClient()),
            ResponseCodeInterceptor(),
            JSONResponseParsingInterceptor(),
            AutomaticPersistedQueryInterceptor()
        ]
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let workoutCompleted = Notification.Name("workoutCompleted")
}
