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
    
    func provisionUser(request: ProvisionUserRequest) async throws -> ProvisionUserResponse {
        // Convert to GraphQL input
        let benchmarks = request.benchmarks.map { benchmark in
            BenchmarkInput(
                type: benchmark.type,
                value: benchmark.value,
                unit: benchmark.unit
            )
        }
        
        let injuries = request.injuries.map { injury in
            InjuryInput(
                bodyPart: injury.bodyPart,
                severity: GraphQLEnum(mapInjurySeverity(injury.severity)),
                description: GraphQLNullable.some(injury.description ?? "")
            )
        }
        
        let mutation = ProvisionUserMutation(input: ProvisionUserInput(
            gender: GraphQLEnum(request.gender.rawValue),
            fitnessLevel: GraphQLEnum(request.fitnessLevel.rawValue),
            workoutDuration: request.workoutDuration,
            benchmarks: benchmarks,
            injuries: GraphQLNullable.some(injuries)
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
    
    // Legacy callback-based method for backwards compatibility
    func provisionUser(request: ProvisionUserRequest, completion: @escaping (Result<ProvisionUserResponse, Error>) -> Void) {
        Task {
            do {
                let result = try await provisionUser(request: request)
                completion(.success(result))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Helper Methods for Mapping
    
    private func mapGender(_ gender: String) -> Gender {
        switch gender.lowercased() {
        case "male":
            return .male
        case "female":
            return .female
        case "other":
            return .other
        case "prefer_not_to_say":
            return .preferNotToSay
        default:
            return .preferNotToSay
        }
    }
    
    private func mapFitnessLevel(_ fitnessLevel: String) -> FitnessLevel {
        switch fitnessLevel.lowercased() {
        case "beginner":
            return .beginner
        case "intermediate":
            return .intermediate
        case "advanced":
            return .advanced
        case "elite":
            return .elite
        default:
            return .beginner
        }
    }
    
    private func mapInjurySeverity(_ severity: String) -> InjurySeverity {
        switch severity.lowercased() {
        case "minor":
            return .minor
        case "moderate":
            return .moderate
        case "severe":
            return .severe
        default:
            return .minor
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
