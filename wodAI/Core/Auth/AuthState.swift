//
//  AuthState.swift
//  wodAI
//
//  Centralized authentication state management using Combine
//

import Foundation
import Combine

// MARK: - Authentication Protocols

protocol TokenProvider {
    func getValidToken() async throws -> String?
    var currentToken: String? { get }
}

protocol AuthenticationProvider {
    var isAuthenticated: Bool { get }
    var isAuthenticatedPublisher: AnyPublisher<Bool, Never> { get }
    func logout()
    func handleSessionExpired()
}

protocol ProvisioningProvider {
    var isProvisioned: Bool { get }
    var needsProvisioning: Bool { get }
    var provisioningStatePublisher: AnyPublisher<ProvisioningState, Never> { get }
    func checkProvisioningStatus() async
    func completeProvisioning()
}

// MARK: - Auth State Models

struct ProvisioningState {
    let isProvisioned: Bool
    let needsProvisioning: Bool
}

// MARK: - Centralized Auth State

class AuthState: ObservableObject {
    // MARK: - Published Properties
    @Published var isAuthenticated: Bool = false
    @Published var isProvisioned: Bool = false
    @Published var needsProvisioning: Bool = false
    @Published var currentUserId: Int?
    @Published var currentToken: String?
    @Published var sessionExpiredMessage: String?

    // MARK: - Constants
    private let tokenKey = "authToken"
    private let sessionExpiredKey = "sessionExpiredMessage"
    private let provisionedKey = "userProvisioned"
    private let userIdKey = "currentUserId"
    
    // MARK: - Combine Publishers
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    var provisioningState: ProvisioningState {
        ProvisioningState(
            isProvisioned: isProvisioned,
            needsProvisioning: needsProvisioning
        )
    }
    
    // MARK: - Initialization
    init() {
        loadPersistedState()
        setupPublishers()
    }
    
    // MARK: - Private Methods
    private func loadPersistedState() {
        currentToken = UserDefaults.standard.string(forKey: tokenKey)
        isAuthenticated = currentToken != nil
        isProvisioned = UserDefaults.standard.bool(forKey: provisionedKey)
        currentUserId = UserDefaults.standard.object(forKey: userIdKey) as? Int
        sessionExpiredMessage = UserDefaults.standard.string(forKey: sessionExpiredKey)

        // Set provisioning state based on authentication
        updateProvisioningState()
    }
    
    private func setupPublishers() {
        // Auto-save token changes
        $currentToken
            .sink { [weak self] token in
                UserDefaults.standard.set(token, forKey: self?.tokenKey ?? "")
                self?.isAuthenticated = token != nil
            }
            .store(in: &cancellables)
        
        // Auto-save user ID changes
        $currentUserId
            .sink { [weak self] userId in
                UserDefaults.standard.set(userId, forKey: self?.userIdKey ?? "")
            }
            .store(in: &cancellables)
        
        // Auto-save provisioning state
        $isProvisioned
            .sink { [weak self] isProvisioned in
                UserDefaults.standard.set(isProvisioned, forKey: self?.provisionedKey ?? "")
                self?.updateProvisioningState()
            }
            .store(in: &cancellables)
        
        // Auto-save session expired message
        $sessionExpiredMessage
            .sink { [weak self] message in
                UserDefaults.standard.set(message, forKey: self?.sessionExpiredKey ?? "")
            }
            .store(in: &cancellables)
    }
    
    private func updateProvisioningState() {
        needsProvisioning = isAuthenticated && !isProvisioned
    }
    
    // MARK: - Public Methods
    func authenticate(token: String, userId: Int? = nil) {
        currentToken = token
        currentUserId = userId
        if let userId {
            TelemetryService.identify(userId: String(userId))
        }

        // Check provisioning status after authentication
        Task {
            await checkProvisioningStatus()
        }
    }

    func signOut() {
        currentToken = nil
        currentUserId = nil
        sessionExpiredMessage = nil
        isProvisioned = false
        needsProvisioning = false
        TelemetryService.clearIdentity()

        // Clear UserDefaults
        UserDefaults.standard.removeObject(forKey: tokenKey)
        UserDefaults.standard.removeObject(forKey: userIdKey)
        UserDefaults.standard.removeObject(forKey: sessionExpiredKey)
        UserDefaults.standard.removeObject(forKey: provisionedKey)
    }
    
    func handleSessionExpired() {
        print("🔓 Handling session expiration...")
        sessionExpiredMessage = "Your session has expired. Please log in again."
        signOut()
        
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .userDidLogout, object: nil)
        }
    }
    
    func clearSessionExpiredMessage() {
        sessionExpiredMessage = nil
    }
    
    func completeProvisioning() {
        isProvisioned = true
        needsProvisioning = false
    }
    
    @MainActor
    func checkProvisioningStatus() async {
        guard isAuthenticated else {
            needsProvisioning = false
            return
        }
        
        do {
            let isProvisionedResult = try await ProvisioningService.shared.checkProvisioningStatus()
            isProvisioned = isProvisionedResult
            needsProvisioning = !isProvisionedResult
        } catch {
            print("⚠️ Error checking provisioning status: \(error)")
            // In case of error, assume not provisioned
            isProvisioned = false
            needsProvisioning = true
        }
    }
}

// MARK: - Protocol Conformance

extension AuthState: TokenProvider {
    func getValidToken() async throws -> String? {
        return currentToken
    }
}

extension AuthState: AuthenticationProvider {
    var isAuthenticatedPublisher: AnyPublisher<Bool, Never> {
        $isAuthenticated.eraseToAnyPublisher()
    }
    
    func logout() {
        signOut()
    }
}

extension AuthState: ProvisioningProvider {
    var provisioningStatePublisher: AnyPublisher<ProvisioningState, Never> {
        Publishers.CombineLatest($isProvisioned, $needsProvisioning)
            .map { ProvisioningState(isProvisioned: $0, needsProvisioning: $1) }
            .eraseToAnyPublisher()
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let userDidLogout = Notification.Name("userDidLogout")
}
