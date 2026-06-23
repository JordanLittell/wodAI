//
//  Network.swift
//  wodAI
//

import Foundation
import Apollo
import WodAiAPI
import SwiftUI
import Combine

class Network {
    static let shared = Network()

    private var graphQLEndpoint: String {
        return AppConfig.graphQLEndpoint
    }

    private(set) lazy var client: ApolloClient = {
        let url = URL(string: graphQLEndpoint)!

        if AppConfig.enableLogging {
            print("🔧 WodAI GraphQL Endpoint: \(graphQLEndpoint)")
        }

        let httpTransport = RequestChainNetworkTransport(
            interceptorProvider: NetworkInterceptorProvider(),
            endpointURL: url
        )

        return ApolloClient(networkTransport: httpTransport, store: ApolloStore())
    }()
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

        TelemetryService.addBreadcrumb(category: "graphql", message: "operation: \(Operation.operationName)")

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
                TelemetryService.captureError(error, tags: ["layer": "network", "operation": Operation.operationName])
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
        TelemetryService.captureMessage("session_expired", level: .warning, tags: ["trigger": "graphql_unauthorized"])

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
