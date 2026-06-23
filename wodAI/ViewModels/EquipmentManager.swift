//
//  EquipmentManager.swift
//  wodAI
//
//  Manager for fetching and caching equipment from the database
//

import Foundation
import Apollo
import WodAiAPI


class EquipmentManager: ObservableObject {
    static let shared = EquipmentManager()
    
    @Published var equipment: [Equipment] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private let network = Network.shared
    private let cacheKey = "cachedEquipment"
    private let cacheExpirationKey = "equipmentCacheExpiration"
    private let cacheExpirationTime: TimeInterval = 24 * 60 * 60 // 24 hours
    
    private init() {
        loadCachedEquipment()
    }
    
    // MARK: - Public Methods
    
    /// Fetch equipment from the database
    func fetchEquipment(forceRefresh: Bool = false) {
        // Check if we should use cached data
        if !forceRefresh && isCacheValid() && !equipment.isEmpty {
            return
        }
        
        isLoading = true
        error = nil
        
        network.client.fetch(query: EquipmentQuery()) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let graphQLResult):
                    if let equipmentData = graphQLResult.data?.equipment {
                        self?.equipment = equipmentData.map { 
                            Equipment(id: $0.id, name: $0.name, category: "") 
                        }
                        self?.cacheEquipment()
                    }
                    
                    if let errors = graphQLResult.errors {
                        let messages = errors.compactMap { $0.message }.joined(separator: "; ")
                        TelemetryService.captureGraphQLErrors(messages: messages, operation: "EquipmentQuery")
                        self?.error = NSError(
                            domain: "EquipmentManager",
                            code: 0,
                            userInfo: [NSLocalizedDescriptionKey: "Failed to fetch equipment"]
                        )
                    }

                case .failure(let error):
                    TelemetryService.captureError(error, tags: ["operation": "EquipmentQuery"])
                    self?.error = error
                }
            }
        }
    }
    
    /// Get Equipment by ID
    func getEquipment(by id: Int) -> Equipment? {
        return equipment.first { $0.id == id }
    }
    
    /// Get Equipment by name
    func getEquipment(by name: String) -> Equipment? {
        return equipment.first { $0.name == name }
    }
    
    // MARK: - Private Methods
    
    private func loadCachedEquipment() {
        guard let data = UserDefaults.standard.data(forKey: cacheKey),
              let cachedEquipment = try? JSONDecoder().decode([Equipment].self, from: data) else {
            return
        }
        
        self.equipment = cachedEquipment
    }
    
    private func cacheEquipment() {
        if let data = try? JSONEncoder().encode(equipment) {
            UserDefaults.standard.set(data, forKey: cacheKey)
            UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: cacheExpirationKey)
        }
    }
    
    private func isCacheValid() -> Bool {
        let expirationTime = UserDefaults.standard.double(forKey: cacheExpirationKey)
        let currentTime = Date().timeIntervalSince1970
        return currentTime - expirationTime < cacheExpirationTime
    }
    
    func clearCache() {
        UserDefaults.standard.removeObject(forKey: cacheKey)
        UserDefaults.standard.removeObject(forKey: cacheExpirationKey)
        equipment = []
    }
}
