//
//  Network.swift
//  wodAI
//

import Foundation
import Apollo
import ApolloWebSocket
import WodAiAPI
import SwiftUI
import Combine

class Network {
    static let shared = Network()

    private var graphQLEndpoint: String {
        return AppConfig.graphQLEndpoint
    }

    private var cancellables = Set<AnyCancellable>()

    /// Queries and mutations go over HTTP through the interceptor chain;
    /// subscriptions go over the websocket.
    private(set) lazy var client: ApolloClient = {
        let url = URL(string: graphQLEndpoint)!

        if AppConfig.enableLogging {
            print("🔧 WodAI GraphQL Endpoint: \(graphQLEndpoint)")
        }

        let httpTransport = RequestChainNetworkTransport(
            interceptorProvider: NetworkInterceptorProvider(),
            endpointURL: url
        )

        let transport = SplitNetworkTransport(
            uploadingNetworkTransport: httpTransport,
            webSocketNetworkTransport: webSocketTransport
        )
        return ApolloClient(networkTransport: transport, store: ApolloStore())
    }()

    /// The subscription socket, speaking `graphql-transport-ws` (the protocol
    /// the backend's graphql-ws server expects) on the same path as HTTP.
    ///
    /// It doesn't connect on its own: call `connectSubscriptions()` ahead of
    /// subscribing so the TCP/TLS handshake and `connection_init` round trip
    /// are already done when the first subscription is sent. Anything sent
    /// before the server acks the connection is queued, not dropped.
    ///
    /// No store: streamed events are provisional, so they aren't written to
    /// the normalized cache.
    private(set) lazy var webSocketTransport: WebSocketTransport = {
        let url = Self.webSocketURL(for: URL(string: graphQLEndpoint)!)
        let socket = WebSocket(request: URLRequest(url: url), protocol: .graphql_transport_ws)
        let transport = WebSocketTransport(
            websocket: socket,
            config: WebSocketTransport.Configuration(
                connectOnInit: false,
                connectingPayload: Self.connectingPayload(token: AuthState.shared.currentToken)
            )
        )

        // The server authenticates once per socket from connection_init, so a
        // new token means a new connection; a sign-out closes it.
        AuthState.shared.$currentToken
            .dropFirst()
            .removeDuplicates()
            .sink { [weak self, weak transport] token in
                guard let self, let transport else { return }
                transport.updateConnectingPayload(Self.connectingPayload(token: token), reconnectIfConnected: true)
                if token == nil {
                    self.disconnectSubscriptions()
                }
            }
            .store(in: &cancellables)

        return transport
    }()

    private var subscriptionsRequested = false

    /// Opens the subscription socket if it isn't already open or opening.
    /// Cheap to call repeatedly; call it as soon as a subscription is likely
    /// (e.g. when the screen that starts one appears) to take the connection
    /// setup off the critical path.
    func connectSubscriptions() {
        guard AuthState.shared.currentToken != nil else { return }
        guard !subscriptionsRequested || !webSocketTransport.isConnected() else { return }
        subscriptionsRequested = true
        webSocketTransport.resumeWebSocketConnection(autoReconnect: true)
    }

    /// Closes the subscription socket and stops it reconnecting.
    func disconnectSubscriptions() {
        guard subscriptionsRequested else { return }
        subscriptionsRequested = false
        webSocketTransport.pauseWebSocketConnection()
    }

    /// http → ws, https → wss, same host and path.
    static func webSocketURL(for endpoint: URL) -> URL {
        var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: false)!
        components.scheme = endpoint.scheme == "https" ? "wss" : "ws"
        return components.url!
    }

    /// The connection_init payload; the backend reads `Authorization` the same
    /// way it reads the HTTP header.
    static func connectingPayload(token: String?) -> JSONEncodableDictionary {
        guard let token else { return [:] }
        return ["Authorization": "Bearer \(token)"]
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
