//
//  Network.swift
//  wodAI
//
//  Created by Jordan Littell on 4/20/25.
//

import Foundation
import Apollo
import WodAiAPI

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

// Create a custom interceptor to add the authorization token
class AuthorizationInterceptor: ApolloInterceptor {
    var id: String = ""
    
    let authManager: AuthManager = AuthManager()
    
    func interceptAsync<Operation>(
        chain: RequestChain,
        request: HTTPRequest<Operation>,
        response: HTTPResponse<Operation>?,
        completion: @escaping (Result<GraphQLResult<Operation.Data>, Error>) -> Void
    ) where Operation: GraphQLOperation {
        if let token = authManager.token {
            request.addHeader(name: "Authorization", value: "Bearer \(token)")
        }
        
        chain.proceedAsync(request: request, response: response, completion: completion)
    }
}

// Create a custom interceptor provider
class NetworkInterceptorProvider: InterceptorProvider {
    func interceptors<Operation>(for operation: Operation) -> [ApolloInterceptor] where Operation: GraphQLOperation {
        return [
            AuthorizationInterceptor(),
            NetworkFetchInterceptor(client: URLSessionClient()),
            ResponseCodeInterceptor(),
            JSONResponseParsingInterceptor(),
            AutomaticPersistedQueryInterceptor()
        ]
    }
}
