//
//  ComponentCompletionManager.swift
//  wodAI
//
//  Manages the completion state of workout components
//

import Foundation
import SwiftUI

class ComponentCompletionManager: ObservableObject {
    static let shared = ComponentCompletionManager()
    
    @Published private(set) var completedComponents: Set<String> = []
    
    private let storageKey = "completedComponents"
    
    private init() {
        loadCompletedComponents()
    }
    
    // MARK: - Public Methods
    
    func isCompleted(workoutId: String, componentOrder: Int) -> Bool {
        let key = generateKey(workoutId: workoutId, componentOrder: componentOrder)
        return completedComponents.contains(key)
    }
    
    func setCompleted(_ completed: Bool, workoutId: String, componentOrder: Int) {
        let key = generateKey(workoutId: workoutId, componentOrder: componentOrder)
        
        if completed {
            completedComponents.insert(key)
        } else {
            completedComponents.remove(key)
        }
        
        saveCompletedComponents()
    }
    
    func toggleCompleted(workoutId: String, componentOrder: Int) {
        let isCurrentlyCompleted = isCompleted(workoutId: workoutId, componentOrder: componentOrder)
        setCompleted(!isCurrentlyCompleted, workoutId: workoutId, componentOrder: componentOrder)
    }
    
    func clearCompletedComponents(for workoutId: String) {
        completedComponents = completedComponents.filter { key in
            !key.hasPrefix("\(workoutId)_")
        }
        saveCompletedComponents()
    }
    
    func clearAllCompletedComponents() {
        completedComponents.removeAll()
        saveCompletedComponents()
    }
    
    func completedComponentsCount(for workoutId: String) -> Int {
        return completedComponents.filter { key in
            key.hasPrefix("\(workoutId)_")
        }.count
    }
    
    // MARK: - Private Methods
    
    private func generateKey(workoutId: String, componentOrder: Int) -> String {
        return "\(workoutId)_\(componentOrder)"
    }
    
    private func loadCompletedComponents() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode(Set<String>.self, from: data) {
            completedComponents = decoded
        }
    }
    
    private func saveCompletedComponents() {
        if let encoded = try? JSONEncoder().encode(completedComponents) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }
}

// MARK: - Binding Extension
extension ComponentCompletionManager {
    func binding(for workoutId: String, componentOrder: Int) -> Binding<Bool> {
        Binding(
            get: { self.isCompleted(workoutId: workoutId, componentOrder: componentOrder) },
            set: { self.setCompleted($0, workoutId: workoutId, componentOrder: componentOrder) }
        )
    }
}
