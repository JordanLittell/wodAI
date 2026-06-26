//
//  GymProfileManager.swift
//  wodAI

import Foundation
import SwiftUI
import WodAiAPI

class GymProfileManager: ObservableObject {
    static let shared = GymProfileManager()
    static let isLoaded: Bool = false

    @Published private(set) var profiles: [GymProfile] = []
    @Published var isLoading = false
    @Published var isSaving = false
    @Published private(set) var togglingId: Int?
    @Published var error: Error?

    var activeProfile: GymProfile? { profiles.first { $0.isActive } }
    var isLoaded: Bool = false

    private let network = Network.shared

    private init() {
        if (!isLoaded) {
            loadProfiles()
        }
    }

    // MARK: - Load

    func loadProfiles() {
        guard !isLoading else { return }
        isLoading = true
        error = nil

        network.client.fetch(
            query: GymProfilesQuery(),
            cachePolicy: .fetchIgnoringCacheCompletely
        ) { [weak self] result in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.isLoading = false
                switch result {
                case .success(let graphQLResult):
                    if let data = graphQLResult.data?.gymProfiles {
                        self.profiles = data.map { Self.mapProfile($0) }
                    }
                    if let errors = graphQLResult.errors {
                        let messages = errors.compactMap { $0.message }.joined(separator: "; ")
                        TelemetryService.captureGraphQLErrors(messages: messages, operation: "GymProfiles")
                        self.error = NSError(domain: "GymProfileManager", code: 0,
                            userInfo: [NSLocalizedDescriptionKey: errors.first?.message ?? "Failed to load profiles"])
                    }
                case .failure(let networkError):
                    TelemetryService.captureError(networkError, tags: ["operation": "GymProfiles"])
                    self.error = networkError
                }
            }
        }
    }

    // MARK: - Create

    func createProfile(name: String, equipmentIds: [Int], completion: @escaping (Error?) -> Void) {
        isSaving = true
        let input = WodAiAPI.CreateGymProfileInput(name: name, equipmentIds: equipmentIds)
        network.client.perform(mutation: CreateGymProfileMutation(input: input)) { [weak self] result in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.isSaving = false
                switch result {
                case .success(let graphQLResult):
                    if let p = graphQLResult.data?.createGymProfile {
                        self.profiles.append(GymProfile(
                            id: p.id, name: p.name,
                            equipment: p.equipment.map { Equipment(id: $0.id, name: $0.name, category: nil) },
                            isActive: p.isActive
                        ))
                        completion(nil)
                    } else if let errors = graphQLResult.errors {
                        let messages = errors.compactMap { $0.message }.joined(separator: "; ")
                        TelemetryService.captureGraphQLErrors(messages: messages, operation: "CreateGymProfile")
                        completion(NSError(domain: "GymProfileManager", code: 0,
                            userInfo: [NSLocalizedDescriptionKey: errors.first?.message ?? "Failed to create profile"]))
                    }
                case .failure(let networkError):
                    TelemetryService.captureError(networkError, tags: ["operation": "CreateGymProfile"])
                    completion(networkError)
                }
            }
        }
    }

    // MARK: - Update

    func updateProfile(id: Int, name: String?, equipmentIds: [Int]?, completion: @escaping (Error?) -> Void) {
        isSaving = true
        let input = WodAiAPI.UpdateGymProfileInput(
            name: name.map { .some($0) } ?? .none,
            equipmentIds: equipmentIds.map { .some($0) } ?? .none
        )
        network.client.perform(mutation: UpdateGymProfileMutation(updateGymProfileId: id, input: input)) { [weak self] result in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.isSaving = false
                switch result {
                case .success(let graphQLResult):
                    if let p = graphQLResult.data?.updateGymProfile,
                       let idx = self.profiles.firstIndex(where: { $0.id == id }) {
                        self.profiles[idx] = GymProfile(
                            id: p.id, name: p.name,
                            equipment: p.equipment.map { Equipment(id: $0.id, name: $0.name, category: nil) },
                            isActive: p.isActive
                        )
                        completion(nil)
                    } else if let errors = graphQLResult.errors {
                        let messages = errors.compactMap { $0.message }.joined(separator: "; ")
                        TelemetryService.captureGraphQLErrors(messages: messages, operation: "UpdateGymProfile")
                        completion(NSError(domain: "GymProfileManager", code: 0,
                            userInfo: [NSLocalizedDescriptionKey: errors.first?.message ?? "Failed to update profile"]))
                    }
                case .failure(let networkError):
                    TelemetryService.captureError(networkError, tags: ["operation": "UpdateGymProfile"])
                    completion(networkError)
                }
            }
        }
    }

    // MARK: - Delete

    func deleteProfile(id: Int, completion: @escaping (Error?) -> Void) {
        isSaving = true
        network.client.perform(mutation: DeleteGymProfileMutation(deleteGymProfileId: id)) { [weak self] result in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.isSaving = false
                switch result {
                case .success(let graphQLResult):
                    if graphQLResult.data?.deleteGymProfile == true {
                        self.profiles.removeAll { $0.id == id }
                        completion(nil)
                    } else if let errors = graphQLResult.errors {
                        let messages = errors.compactMap { $0.message }.joined(separator: "; ")
                        TelemetryService.captureGraphQLErrors(messages: messages, operation: "DeleteGymProfile")
                        completion(NSError(domain: "GymProfileManager", code: 0,
                            userInfo: [NSLocalizedDescriptionKey: errors.first?.message ?? "Failed to delete profile"]))
                    }
                case .failure(let networkError):
                    TelemetryService.captureError(networkError, tags: ["operation": "DeleteGymProfile"])
                    completion(networkError)
                }
            }
        }
    }

    // MARK: - Toggle Active

    func toggleActive(id: Int, completion: @escaping (Error?) -> Void) {
        print("toggling as active")
        guard togglingId == nil else { return }
        togglingId = id
        
        print("toggling as active now running")


        network.client.perform(mutation: ToggleGymProfileMutation(id: id)) { [weak self] result in
            print("finished mutation")
            Task { @MainActor [weak self] in
                guard let self else { return }
                switch result {
                case .success(let graphQLResult):
                    if graphQLResult.data?.toggleGymProfile != nil {
                        print("old profiles: \(self.profiles)")
                        self.profiles = self.profiles.map { profile in
                            var p = profile
                            if p.id == self.togglingId {
                                p.isActive = !p.isActive
                            } else {
                                p.isActive = false
                            }
                            return p
                        }
                        print("new profiles: \(self.profiles)")
                        self.togglingId = nil
                        completion(nil)
                    } else if let errors = graphQLResult.errors {
                        self.togglingId = nil
                        let messages = errors.compactMap { $0.message }.joined(separator: "; ")
                        TelemetryService.captureGraphQLErrors(messages: messages, operation: "ToggleGymProfile")
                        completion(NSError(domain: "GymProfileManager", code: 0,
                            userInfo: [NSLocalizedDescriptionKey: errors.first?.message ?? "Failed to toggle profile"]))
                    }
                case .failure(let networkError):
                    self.togglingId = nil
                    TelemetryService.captureError(networkError, tags: ["operation": "ToggleGymProfile"])
                    completion(networkError)
                }
            }
        }
    }

    // MARK: - Private

    private static func mapProfile(_ p: GymProfilesQuery.Data.GymProfile) -> GymProfile {
        GymProfile(
            id: p.id, name: p.name,
            equipment: p.equipment.map { Equipment(id: $0.id, name: $0.name, category: nil) },
            isActive: p.isActive
        )
    }
}
