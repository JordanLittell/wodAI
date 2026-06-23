# wodAI

An iOS fitness app that generates AI-powered workouts tailored to your equipment, fitness level, and goals.

## What it does

wodAI generates personalized Workout of the Day (WOD) sessions and weekly training schedules. Users describe their available gym equipment, fitness level, injuries, and target muscle groups, and the app produces structured workouts through an AI backend. Users can also chat with an AI coach to modify workouts in real-time, log completed sessions, and track their training history across a weekly calendar view.

**Core use cases:**
- Generate a single WOD based on current energy level, intensity, and equipment
- Generate a full weekly workout schedule
- Chat with an AI agent to adjust or swap exercises in real-time
- Track and complete workouts, building a history of logged sessions
- Manage multiple gym profiles (home gym, commercial gym, etc.) with different equipment sets

---

## Project structure

```
wodAI/
├── Core/           # App entry point, auth, navigation, networking, services
├── ViewModels/     # ObservableObject view models
├── Views/          # SwiftUI views
├── Models/         # Local Swift model types
├── GraphQL/        # .graphql operation files + downloaded schema
└── Config/         # AppConfig (endpoint switching)
wodAiAPI/           # Generated GraphQL Swift package (do not edit by hand)
Configurations/     # .xcconfig files for Debug/Release environments
```

### Build configurations

- **Debug** — points to `http://localhost:3000/graphql`
- **Release** — points to `https://move-adapt.com/graphql`

---

## 1. View Hierarchy

### Entry point

`wodAIApp` (`@main`) creates `AuthState.shared` and `AuthManager` as `@StateObject`s, injects both as environment objects, and renders `ContentView`.

### Root router — `ContentView`

`ContentView` reads `authState` and routes the entire app:

```
ContentView
├── unauthenticated → AuthenticationView (NavigationStack)
│     ├── showingLogin=true  → LoginView  (email/pass + Google + Apple buttons)
│     └── showingLogin=false → SignUpView
│
├── authenticated + needsProvisioning → ProvisioningView
│     9-step onboarding: age → height → weight → gender → fitnessLevel
│                        → restDays → gymFrequency → injuries → equipment
│
└── authenticated + provisioned → RootAppView
      ├── MainTabView (TabView, 4 tabs)
      │     ├── .home     → WeeklyWorkoutView (NavigationStack)
      │     │     ├── DayButton row (drag gesture for week navigation)
      │     │     ├── WeeklyWorkoutCard | EmptyDayCard | WeeklyLoadingCard | WeeklyErrorCard
      │     │     └── .fullScreenCover → WorkoutView
      │     │           ├── WorkoutProgressView
      │     │           ├── ComponentCard(s) (sorted by order)
      │     │           ├── WODSessionStatusBanner
      │     │           └── .sheet → WorkoutStimulusSheet
      │     ├── .workouts → WorkoutsView (NavigationStack)
      │     │     └── NavigationLink → CompletedWorkoutView
      │     ├── .setup    → GymProfilesView
      │     │     ├── GymProfileSelector
      │     │     ├── AddEditGymProfileView (sheet)
      │     │     └── GymEquipmentSummary
      │     └── .profile  → ProfileView
      └── WODMiniPlayer (overlay above TabBar, slides in when a session is active)
```

Tab switches can be triggered programmatically from anywhere via `NotificationCenter.post(name: .navigateToTab, object: AppTab)`.

---

## 2. Authentication

### Three sign-in paths

All three converge at `authManager.authenticate(token:userId:)`:

| Method | Implementation |
|---|---|
| Email / password | `LoginWithCredentialsMutation(email:password:)` |
| Google | `GIDSignIn` → Google ID token → `GoogleLoginMutation(idToken:)` |
| Apple | `ASAuthorizationController` → identity token → `AppleLoginMutation(identityToken:...)` |

### Post-authentication flow

```
authManager.authenticate(token:userId:)
  → AuthState persists token + userId to UserDefaults
  → isAuthenticated = true
  → Task: ProvisioningService.checkProvisioningStatus() [IsUserProvisionedQuery]
        → sets isProvisioned / needsProvisioning
  → ContentView re-routes to ProvisioningView or RootAppView
```

### Key components

**`AuthState.shared`** (`ObservableObject`, singleton)
The single source of truth for session data. Owns `isAuthenticated`, `currentToken`, `currentUserId`, `isProvisioned`, `needsProvisioning`, and `sessionExpiredMessage`. All `@Published` properties auto-persist to UserDefaults via Combine `.sink`.

**`AuthManager`** (`ObservableObject`, environment object)
A backwards-compatible wrapper around `AuthState`. Mirrors all `@Published` properties via Combine `assign(to:)`. Injected at the root so every view can reach it via `@EnvironmentObject`.

### Session expiry

`AuthorizationInterceptor` scans every GraphQL response for error messages containing `"unauthorized"`, `"auth"`, or `"token"`. On a match it calls `authProvider.handleSessionExpired()`, which:
1. Clears all auth state in `AuthState`
2. Posts `.userDidLogout` via `NotificationCenter`

`ContentView` observes `.userDidLogout` and calls `authState.signOut()` on the main thread, returning the user to `LoginView`. The expired-session banner is displayed for 5 seconds then auto-dismissed.

### Apple credential revalidation

On every app launch `AppleSignInService.shared.checkCredentialState()` calls `ASAuthorizationAppleIDProvider.getCredentialState()`. If the credential is revoked or not found, local auth state is cleared.

---

## 3. Data Models

App-level models live in `wodAI/Models/`. GraphQL-generated enums (`WorkoutStatus`, `FitnessLevel`, `Gender`, `RestDay`, `FitnessEquipment`, `AgentMessageRole`, `InjurySeverity`) live in the `wodAiAPI` package and are used directly.

### `Workout`

The central model. `Codable`, `Identifiable`, `Equatable`.

```swift
struct Workout {
    let id: String
    let name: String
    let description: String
    let coaching: String?
    let stimulus: String?
    let scheduledDate: Date?
    let status: WorkoutStatus
    let components: [Component]
    let completedAt: Date?
    let completed: Bool
}
```

Key computed properties: `isScheduledForToday`, `canBeStarted` (`status.isReady && !completed`), `shouldShowLoadingState` (`status.isGenerating`).

`WorkoutStatus` values: `.pending .started .generating .generated .completed .failed .cancelled`

### `Component`

An individual exercise within a workout.

```swift
struct Component {
    let id: UUID           // local only
    let name: String
    let order: Int
    let definition: String // the actual prescription text
    let description: String
    let equipment: [String]?
    let muscles: [String]
    let movements: [String]
    let stimulus: String?
}
```

### `GymProfile`

```swift
struct GymProfile {
    let id: UUID
    var name: String
    var icon: String            // SF Symbol name
    var equipment: Set<Equipment>
    var isSelected: Bool
    let createdAt: Date
}
```

### `ChatMessage`

Used in the AI agent chat UI.

```swift
struct ChatMessage {
    let id: UUID
    var text: String
    let isUser: Bool
    let timestamp: Date
    var isStreaming: Bool    // true while the AI is still producing this message
}
```

### `WODSessionData`

Serialized to UserDefaults for session restoration across app launches.

```swift
struct WODSessionData {
    let workout: Workout
    let startTime: Date
    let elapsedTime: TimeInterval
    let phase: WODPhase     // .notStarted .active .paused .completed
}
```

`WODPhase` carries `.color` and `.icon` computed properties used in the session banner UI.

### `UserWorkoutPreferences`

Persisted generation preferences:

```swift
struct UserWorkoutPreferences: Codable {
    var preferredDuration: Int
    var preferredIntensity: IntensityLevel
    var availableEquipment: Set<Equipment>
    var lastWorkoutDate: Date?
    var totalWorkoutsCompleted: Int
}
```

---

## 4. Networking

### Apollo client — `Network.shared`

A lazy singleton configured in `wodAI/Core/Network.swift` with a `SplitNetworkTransport`:

```
SplitNetworkTransport
├── HTTP (queries & mutations)
│     RequestChainNetworkTransport → AppConfig.graphQLEndpoint
│     Interceptor chain (in order):
│       1. AuthorizationInterceptor     — injects Bearer token; triggers logout on auth errors
│       2. NetworkFetchInterceptor      — executes the URLSession request
│       3. ResponseCodeInterceptor      — validates HTTP status codes
│       4. JSONResponseParsingInterceptor — decodes the GraphQL response
│       5. AutomaticPersistedQueryInterceptor — APQ retry on cache miss
└── WebSocket (subscriptions)
      WebSocketTransport → ws:// / wss:// equivalent of the HTTP endpoint
      Protocol: graphql_transport_ws
```

### Endpoint resolution

Resolved at runtime by `AppConfig.graphQLEndpoint`, which reads from `Bundle.main.infoDictionary["GRAPHQL_ENDPOINT"]` (set via xcconfig) and falls back to a compile-time constant:

- **Debug** → `http://localhost:3000/graphql`
- **Release** → `https://move-adapt.com/graphql`

### Query / mutation pattern

ViewModels call Apollo directly using the generated type-safe operations:

```swift
// Query
Network.shared.client.fetch(query: CurrentWODQuery()) { result in
    switch result {
    case .success(let data): // data fields are strongly typed
    case .failure(let error): // propagate to @Published errorMessage
    }
}

// Mutation
Network.shared.client.perform(mutation: CompleteWodMutation(wodId: id)) { result in ... }
```

### AI streaming — `AgentService`

The AI agent response streams over WebSocket using `AgentResponseSubscription`:

1. `sendMessage(wodId:message:)` — fires `SendAgentMessageMutation`, gets back `conversationId` + `messageId`
2. `subscribeToResponse(wodId:onChunk:onComplete:onError:)` — subscribes to `AgentResponseSubscription(wodId:)`:
   - `onChunk(text)` called for each streamed fragment
   - `onComplete(conversationId)` called when `response.isComplete == true`
3. `cancelSubscription()` — cancels the `Apollo.Cancellable`
4. `approveWorkoutModification(wodId:conversationId:)` — applies agent-suggested changes via `ApproveWorkoutModificationMutation`

### Polling

`WeeklyWorkoutViewModel` polls every 30 seconds for workouts in `.generating` status by re-calling `loadWorkoutForDate()` until the status transitions.

### Schema sync

Generated Swift types live in two places:
- `wodAiAPI/Sources/WodAiAPI/` — schema types (Objects, Enums, InputObjects, scalars) as a local Swift Package
- `wodAI/GraphQL/Operations/` — one `.graphql.swift` per operation, compiled into the main app target

To sync with the API when the backend schema changes:

```bash
./sync-schema.sh
# expands to:
#   ./apollo-ios-cli fetch-schema --path apollo-codegen-config.json
#   ./apollo-ios-cli generate --path apollo-codegen-config.json
```

Then `Cmd+B` in Xcode to rebuild.

---

## 5. Shared State

### Environment objects (injected at root in `wodAIApp`)

| Object | Owns |
|---|---|
| `AuthState.shared` | `isAuthenticated`, `currentToken`, `currentUserId`, `isProvisioned`, `sessionExpiredMessage`. Persisted to UserDefaults. |
| `AuthManager` | Mirrors `AuthState` via Combine. Provides `signInWithGoogle()`, `signInWithApple()`, `signOut()` to views. |

### Singletons (accessed directly by view models and services)

| Object | Owns |
|---|---|
| `Network.shared` | `ApolloClient`. Stateless beyond the Apollo in-memory cache. |
| `WODSessionManager.shared` | `isActive`, `currentWOD`, `sessionPhase`, `elapsedTime`. Drives the `WODMiniPlayer` overlay and `WODSessionStatusBanner`. Persists session to UserDefaults for restoration. |
| `GymProfileManager.shared` | `profiles: [GymProfile]`, `selectedProfile`. Persisted to UserDefaults. Posts `.gymProfileChanged` when the active profile changes. |
| `EquipmentManager.shared` | `equipment: [Equipment]`. 24-hour UserDefaults cache backed by `EquipmentQuery`. |
| `AgentService.shared` | `isStreaming`, `currentConversationId`, active `Apollo.Cancellable`. Scoped to the chat session. |

`WODSessionManager` and `EnhancedWorkoutGeneratorViewModel` are also re-injected as `@EnvironmentObject` in `RootAppView` so the view subtree can read them without reaching for the singleton directly.

### Per-screen view models (`@StateObject`, not shared)

| ViewModel | Owned by | Owns |
|---|---|---|
| `WeeklyWorkoutViewModel` | `WeeklyWorkoutView` | `workouts: [Date: Workout]`, selected date, loading/error state, 30s polling |
| `ProvisioningViewModel` | `ProvisioningView` | Multi-step form state, step index, `ProvisionUserMutation` |
| `ChatViewModel` | Agent chat view | `messages: [ChatMessage]`, streaming state; delegates I/O to `AgentService.shared` |
| `ProfileViewModel` | `ProfileView` | User profile fetch + `UpdateUserMutation` |
| `SignUpViewModel` | `SignUpView` | Registration form state + `RegisterUserMutation` |

### NotificationCenter events

| Notification | Posted by | Consumed by |
|---|---|---|
| `.userDidLogout` | `AuthorizationInterceptor`, `AuthState` | `ContentView` → resets to unauthenticated |
| `.gymProfileChanged` | `GymProfileManager` | `EnhancedWorkoutGeneratorViewModel` → reloads equipment defaults |
| `.navigateToTab` (payload: `AppTab`) | Any view | `MainTabView` → switches `selectedTab` |
| `.wodSessionStarted/Paused/Resumed/Completed` | `WODSessionManager` | `WODMiniPlayer`, `WeeklyWorkoutView` |
| `.workoutCompleted` | `WODSessionManager`, `WorkoutView` | Views showing workout history |
| `.workoutUpdated` | `ChatViewModel` (after agent approval) | Views displaying the current workout |

---

## Contributing

### Prerequisites

- Xcode 15+
- Apollo iOS CLI (bundled as `./apollo-ios-cli`)
- Backend running locally on `http://localhost:3000` for schema sync

### Workflow

1. **Build & run** — open `wodAI.xcodeproj`, select a simulator, press `Cmd+R`
2. **Add a GraphQL operation** — create a `.graphql` file in `wodAI/GraphQL/`, then run `./sync-schema.sh`
3. **Add a feature** — create or update a ViewModel in `wodAI/ViewModels/`, wire it to a SwiftUI view. Views observe `@Published` properties; mutations go through the view model
4. **Test** — `Cmd+U` in Xcode
