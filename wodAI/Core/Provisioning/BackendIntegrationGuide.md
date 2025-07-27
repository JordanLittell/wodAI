# Backend Integration Guide for Provisioning

## GraphQL Schema Additions

Add these types and mutations to your GraphQL schema:

```graphql
# Enums
enum Gender {
  MALE
  FEMALE
  OTHER
  PREFER_NOT_TO_SAY
}

enum FitnessLevel {
  BEGINNER
  INTERMEDIATE
  ADVANCED
  ELITE
}

enum InjurySeverity {
  MINOR
  MODERATE
  SEVERE
}

# Input Types
input BenchmarkInput {
  type: String!
  value: Float!
  unit: String!
}

input InjuryInput {
  bodyPart: String!
  severity: InjurySeverity!
  description: String
}

input ProvisionUserInput {
  gender: Gender!
  fitnessLevel: FitnessLevel!
  workoutDuration: Int! # in minutes
  benchmarks: [BenchmarkInput!]!
  injuries: [InjuryInput!]
}

# Mutations
type Mutation {
  provisionUser(input: ProvisionUserInput!): ProvisionUserResponse!
}

type ProvisionUserResponse {
  success: Boolean!
  message: String
  user: User
}

# Query
type Query {
  isUserProvisioned: Boolean!
}
```

## iOS Integration Steps

### 1. Generate Apollo Types

After updating the GraphQL schema, regenerate the Apollo types:

```bash
./apollo-ios-cli generate
```

### 2. Create GraphQL Queries/Mutations

Create a new file `ProvisioningAPI.graphql`:

```graphql
query IsUserProvisioned {
  isUserProvisioned
}

mutation ProvisionUser($input: ProvisionUserInput!) {
  provisionUser(input: $input) {
    success
    message
    user {
      id
      email
      firstName
      lastName
    }
  }
}
```

### 3. Update ProvisioningService

Replace the stub implementation in `ProvisioningService.swift`:

```swift
import Apollo
import WodAiAPI

class ProvisioningService {
    static let shared = ProvisioningService()
    
    private init() {}
    
    func checkProvisioningStatus(completion: @escaping (Result<Bool, Error>) -> Void) {
        let query = IsUserProvisionedQuery()
        
        Network.shared.client.fetch(query: query) { result in
            switch result {
            case .success(let graphQLResult):
                if let isProvisioned = graphQLResult.data?.isUserProvisioned {
                    completion(.success(isProvisioned))
                } else if let errors = graphQLResult.errors {
                    completion(.failure(errors.first ?? NSError(domain: "ProvisioningService", code: 0)))
                } else {
                    completion(.failure(NSError(domain: "ProvisioningService", code: 0)))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func provisionUser(request: ProvisionUserRequest, completion: @escaping (Result<ProvisionUserResponse, Error>) -> Void) {
        // Convert to GraphQL input
        let input = ProvisionUserInput(
            gender: GraphQLEnum(Gender(rawValue: request.gender.uppercased()) ?? .other),
            fitnessLevel: GraphQLEnum(FitnessLevel(rawValue: request.fitnessLevel.uppercased()) ?? .beginner),
            workoutDuration: request.workoutDuration,
            benchmarks: request.benchmarks.map { benchmark in
                BenchmarkInput(
                    type: benchmark.type,
                    value: benchmark.value,
                    unit: benchmark.unit
                )
            },
            injuries: request.injuries.map { injury in
                InjuryInput(
                    bodyPart: injury.bodyPart,
                    severity: GraphQLEnum(InjurySeverity(rawValue: injury.severity.uppercased()) ?? .minor),
                    description: injury.description
                )
            }
        )
        
        let mutation = ProvisionUserMutation(input: input)
        
        Network.shared.client.perform(mutation: mutation) { result in
            switch result {
            case .success(let graphQLResult):
                if let data = graphQLResult.data?.provisionUser {
                    let response = ProvisionUserResponse(
                        success: data.success,
                        message: data.message,
                        userId: data.user?.id
                    )
                    completion(.success(response))
                } else if let errors = graphQLResult.errors {
                    completion(.failure(errors.first ?? NSError(domain: "ProvisioningService", code: 0)))
                } else {
                    completion(.failure(NSError(domain: "ProvisioningService", code: 0)))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
```

### 4. Update ProvisioningViewModel

In `submitProvisioning()` method, replace the stub with:

```swift
ProvisioningService.shared.provisionUser(request: request) { [weak self] result in
    DispatchQueue.main.async {
        self?.isLoading = false
        
        switch result {
        case .success(let response):
            if response.success {
                print("✅ User provisioned successfully")
                
                // Mark user as provisioned
                UserDefaults.standard.set(true, forKey: "userProvisioned")
                
                // Update AuthManager
                self?.authManager?.completeProvisioning()
                
                // Notify the app that provisioning is complete
                NotificationCenter.default.post(name: .userDidCompleteProvisioning, object: nil)
            } else {
                self?.errorMessage = response.message ?? "Provisioning failed"
                self?.showError = true
            }
            
        case .failure(let error):
            self?.errorMessage = error.localizedDescription
            self?.showError = true
        }
    }
}
```

## Testing the Integration

1. Update your GraphQL backend with the new schema
2. Regenerate Apollo types
3. Test with a new user account
4. Verify data is properly stored in the backend
5. Confirm subsequent logins skip provisioning

## Error Handling

Make sure to handle these edge cases:

1. Network failures during provisioning check
2. Partial data submission failures
3. Token expiration during provisioning
4. Backend validation errors

## Security Considerations

1. Validate all input on the backend
2. Sanitize free-text fields (injury descriptions)
3. Enforce reasonable limits on benchmark values
4. Ensure provisioning can only be done once per user
