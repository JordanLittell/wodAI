//
//  Network.swift
//  wodAI
//
//  Created by Jordan Littell on 4/20/25.
//

import Foundation
import Apollo

class Network {
    static let shared = Network()
    let graphql = "http://localhost:3000/graphql"
    
    
    private(set) lazy var client = ApolloClient(url: URL(string: graphql)!)
    
    func get () {
        client.perform(mutation: GenereateWODMutation(input: CreateWodInput(description: "generate a workout")))
    }
    
}
