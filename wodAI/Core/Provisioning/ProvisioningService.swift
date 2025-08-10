//
//  ProvisioningService.swift
//  wodAI
//
//  Created for WodAI provisioning workflow
//

import Foundation
import Apollo
import WodAiAPI

class ProvisioningService {
    static let shared = ProvisioningService()
    
    // MARK: - Dependencies
    private let tokenProvider: TokenProvider
    private let networkClient: ApolloClient
    
    // MARK: - Initialization
    private init(tokenProvider: TokenProvider = AuthState.shared, networkClient: ApolloClient = Network.shared.client) {
        self.tokenProvider = tokenProvider
        self.networkClient = networkClient
    }
    
    // MARK: - Public Methods
    func checkProvisioningStatus() async throws -> Bool {
        let query = IsUserProvisionedQuery()
        
        return try await withCheckedThrowingContinuation { continuation in
            networkClient.fetch(query: query) { result in
                switch result {
                case .success(let graphQLResult):
                    if let isProvisioned = graphQLResult.data?.isUserProvisioned {
                        continuation.resume(returning: isProvisioned)
                    } else if let errors = graphQLResult.errors {
                        continuation.resume(throwing: errors.first ?? ProvisioningError.unknownError)
                    } else {
                        continuation.resume(throwing: ProvisioningError.noDataReturned)
                    }
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // Legacy callback-based method for backwards compatibility
    func checkProvisioningStatus(completion: @escaping (Result<Bool, Error>) -> Void) {
        Task {
            do {
                let result = try await checkProvisioningStatus()
                completion(.success(result))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    func provisionUser(request: ProvisionUserInput) async throws -> ProvisionUserResponse {
        
        let mutation = ProvisionUserMutation(input: ProvisionUserInput(
            age: request.age,
            heightInches: request.heightInches,
            weight: request.weight,
            gender: request.gender,
            fitnessLevel: request.fitnessLevel,
            workoutDuration: request.workoutDuration,
            benchmarks: request.benchmarks,
            injuries: request.injuries,
            availableEquipment: request.availableEquipment,
            sessionDurationMinutes: request.sessionDurationMinutes,
            restDays: request.restDays
        ))
        
        return try await withCheckedThrowingContinuation { continuation in
            networkClient.perform(mutation: mutation) { result in
                switch result {
                case .success(let graphQLResult):
                    if let data = graphQLResult.data?.provisionUser {
                        let response = ProvisionUserResponse(
                            success: data.success,
                            message: data.message,
                            userId: data.user?.id.description
                        )
                        continuation.resume(returning: response)
                    } else if let errors = graphQLResult.errors {
                        continuation.resume(throwing: errors.first ?? ProvisioningError.unknownError)
                    } else {
                        continuation.resume(throwing: ProvisioningError.noDataReturned)
                    }
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
}

// MARK: - Custom Errors
enum ProvisioningError: LocalizedError {
    case unknownError
    case noDataReturned
    
    var errorDescription: String? {
        switch self {
        case .unknownError:
            return "An unknown error occurred"
        case .noDataReturned:
            return "No data returned from server"
        }
    }
}
