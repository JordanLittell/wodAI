# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

wodAI is an iOS fitness app (SwiftUI, iOS 18+) that serves users AI-generated HIIT workouts. The core loop is a single-workout "feed": the app shows one workout at a time, the user can filter by tag, swap it for another, save/like it, run it with a built-in timer, and complete it. The app talks to a GraphQL backend via Apollo iOS and follows MVVM.

Note: `README.md` and `manifest.llm` at the repo root describe an earlier, more ambitious version of this app (weekly AI-generated schedules, an in-app AI chat agent, `WODSessionManager`, `EnhancedWorkoutGeneratorViewModel`, a tab-bar `MainTabView`, etc.). That scope was cut (see commit "Implementing wodAI (cutting a lot of scope)"). None of those types exist in the current codebase — treat those two files as historical, not authoritative, and prefer reading the code described below instead.

## Development Commands

### Building and running
This is an Xcode project; there is no CLI build/test toolchain installed in this environment beyond Xcode itself (only Command Line Tools are active by default — `xcodebuild` requires switching `xcode-select` to a full Xcode install).
- **Build**: open `wodAI.xcodeproj` in Xcode, `Cmd+B`
- **Run**: select a simulator/device, `Cmd+R` (scheme: `wodAI`)
- **Test**: `Cmd+U`, or Test Navigator to run a single test. Tests use Swift Testing (`import Testing`, `@Test func ...`, `#expect(...)`), not XCTest.
  - `wodAITests/WodTimerEngineTests.swift` is the meaningful test target today — it covers `WodTimerConfig.readout(atElapsed:)` (For Time, AMRAP/countdown, EMOM, Tabata). Any change to `WodTimerEngine.swift` should be re-verified against this file.

### GraphQL code generation
```bash
./sync-schema.sh
# runs, in order:
#   ./apollo-ios-cli fetch-schema --path apollo-codegen-config.json   (requires backend running on localhost:3000)
#   ./apollo-ios-cli generate --path apollo-codegen-config.json
```
Then rebuild in Xcode. Never hand-edit files under `wodAiAPI/Sources/` or `wodAI/GraphQL/Operations/` — they're regenerated wholesale.

To add a new operation: write a `.graphql` file anywhere under `wodAI/GraphQL/`, then run `./sync-schema.sh`.

### Configuration
Build settings live in `Configurations/*.xcconfig` (`Base`, `Debug`, `Release`), referenced by the Xcode project (the root-level `Base.xcconfig`/`Debug.xcconfig`/`Release.xcconfig` are stale duplicates left over from an earlier layout — don't edit those, edit the ones in `Configurations/`).
- `GRAPHQL_ENDPOINT` is set per-config and piped into `Info.plist` at build time (`INFOPLIST_KEY_GRAPHQL_ENDPOINT`); `AppConfig.graphQLEndpoint` reads it back out at runtime.
  - Debug → `http://localhost:3000/graphql`
  - Release → `https://move-adapt.com/graphql`
- Sentry DSN is wired the same way (`SENTRY_DSN` → `INFOPLIST_KEY_SENTRY_DSN` → `AppConfig.sentryDSN`), currently blank in `Base.xcconfig`.

## Architecture

### Navigation
There is no tab bar. `wodAIApp` → `ContentView` routes on `AuthState.shared`:
```
ContentView
├── unauthenticated              → AuthenticationView (Login/SignUp toggle)
├── authenticated + needsProvisioning → ProvisioningView (onboarding)
└── authenticated + provisioned  → RootAppView → AppNavigationView
```
`AppNavigationView` is a single `NavigationStack` with a hamburger-triggered side menu (`SideMenuView`), not a `TabView`. Destinations are switched by local `@State`, no deep-link/notification-based tab switching:
- `.workout` → `AssistantView` (default landing screen; the week's sessions, block by block, menu label "Workout")
- `.saved` → `SavedWorkoutsView`
- `.activity` → `ActivityView` (weekly completed-workout history)
- `.equipment` → `GymProfilesView`
- `.skills` → `SkillsView`

Tapping a session block pushes `BlockPagerView` (swipe between blocks, dot indicator, auto-advance on completion), which shows `StrengthWorkoutView` or `MetconView`. `MetconView` (formerly `HIITWorkoutView`) has no menu entry: it opens only from a block or a saved workout.

### Workout domain — HIIT feed
Note: the feed UI (filters, Generate, the `.shared` instance) no longer has an entry point — `MetconView` always builds a `HIITWorkoutViewModel(preloaded:advancesAfterCompletion: false)`. The feed-fetching logic below still exists in the view model but is unused by any screen.

`HIITWorkoutViewModel` (`Core/HIIT/HIITWorkoutViewModel.swift`, singleton `.shared`) was the center of the app:
- Holds one `currentWorkout: HIITWorkoutItem?` at a time, fetched via `HIITWorkoutsQuery` and swapped via `GenerateHiitWorkoutMutation(skipWorkoutId:tagIds:)`.
- `selectedTags`/`availableTags` drive tag filtering; changing `selectedTags` debounces 500ms then auto-calls `nextWorkout()`.
- Save (`SaveHiitWorkoutMutation`/`UnsaveHiitWorkoutMutation`) and like/dislike (`LikeHiitWorkoutMutation`, -1/0/1 score) are separate from the workout fetch and update local state optimistically, rolling back on failure.
- `executionState: WorkoutExecutionState` (`.idle` / `.running(startTime:priorElapsed:)` / `.paused(elapsed:)`) drives the run/pause/resume/finish controls. `finishExecution()` calls `CompleteHiitWorkoutMutation`, then chains straight into `nextWorkout()`.

### Timer engine
`Core/HIIT/WodTimerEngine.swift` is a pure, Apollo-free timer model — deliberately decoupled so it's unit-testable without mocking the network:
- `WodTimerConfig` = ordered `[TimerSegment]`; each segment repeats its `[TimerPhase]` `rounds` times. A `TimerPhase` counts up or down over an optional duration (`nil` = open-ended, for uncapped "For Time").
- `WodTimerConfig.readout(atElapsed:)` is the single function that maps elapsed seconds → `TimerReadout` (round number, display seconds, phase label, completion). This one model expresses For Time, AMRAP, EMOM/E2MOM, and Tabata.
- Backend timing schemes arrive as generated Apollo selection-set types; `TimingPhaseFragment`/`TimingSegmentFragment`/`TimingSchemeFragment` are structural protocols that let `WodTimerConfig.init(fragment:)` build from *any* operation's generated types without per-operation glue code.
- `HIITWorkoutViewModel.activeConfig` picks: the editable-cap config for For-Time workouts (`editableTimeCap` is user-adjustable pre-start), otherwise the workout's own `timingScheme`, otherwise `.fallback(timeCap:)`.
- When editing this file, run/extend `wodAITests/WodTimerEngineTests.swift` rather than testing manually — the round/phase math has edge cases (exact-boundary completion, open-ended phases).

### Authentication
Three sign-in paths converge on one call: `AuthState.shared.authenticate(token:userId:)`.
| Method | Entry point |
|---|---|
| Email/password | `LoginWithCredentialsMutation` |
| Google | `GIDSignIn` → `GoogleLoginMutation(idToken:)` |
| Apple | `ASAuthorizationController` → `AppleLoginMutation(identityToken:...)` |

- **`AuthState.shared`** (`Core/Auth/AuthState.swift`) is the actual source of truth: `@Published isAuthenticated/currentToken/currentUserId/isProvisioned/needsProvisioning/sessionExpiredMessage`, all auto-persisted to `UserDefaults` via Combine `.sink`. Conforms to `TokenProvider`/`AuthenticationProvider`/`ProvisioningProvider` protocols used by the network layer.
- **`AuthManager`** (`Core/AuthManager.swift`) is a thinner `ObservableObject` kept around for view convenience/back-compat (`@EnvironmentObject`); don't add new state here, add it to `AuthState`.
- Post-auth, `authenticate()` kicks off `checkProvisioningStatus()` (`IsUserProvisionedQuery`), which flips `ContentView`'s routing between `ProvisioningView` and `RootAppView`.
- Session expiry: `AuthorizationInterceptor` (in `Network.swift`) scans every GraphQL response for error text containing "unauthorized"/"auth"/"token" → calls `AuthState.handleSessionExpired()` → posts `.userDidLogout`. `ContentView` observes that notification and force-signs-out on the main thread.
- `AppleSignInService.shared.checkCredentialState()` runs on every launch (from `ContentView.onAppear`) to revoke local auth if the Apple credential was revoked externally.

### Networking
`Network.shared` (`Core/Network.swift`) is a lazy singleton `ApolloClient` built from `AppConfig.graphQLEndpoint`, with an interceptor chain (HTTP only — no WebSocket/subscription transport currently wired):
```
AuthorizationInterceptor      → injects Bearer token, watches for auth errors, triggers logout, sends breadcrumbs to Sentry
NetworkFetchInterceptor       → executes the URLSession request
ResponseCodeInterceptor       → validates HTTP status
JSONResponseParsingInterceptor → decodes GraphQL response
AutomaticPersistedQueryInterceptor → APQ retry on cache miss
```
ViewModels call `Network.shared.client.fetch(query:)` / `.perform(mutation:)` directly and handle the `Result` inline — there's no repository/service abstraction layer beyond that. Errors are consistently: (1) surfaced to a `@Published error`/`errorMessage`, and (2) reported to Sentry via `TelemetryService.captureError`/`captureGraphQLErrors`.

### Shared state (singletons, not injected)
| Object | Owns |
|---|---|
| `HIITWorkoutViewModel.shared` | Current workout, execution state, tags, save/like state |
| `GymProfileManager.shared` | `[GymProfile]`, active profile, CRUD via `*GymProfileMutation` operations |
| `EquipmentManager.shared` | `[Equipment]` catalog, 24h `UserDefaults` cache (`fetchEquipment(forceRefresh:)`) |
| `AuthState.shared` | see Authentication above |
| `Network.shared` | Apollo client |

`AuthState` and `AuthManager` are the only two injected as `@EnvironmentObject` (from `wodAIApp`/`ContentView`); everything else is reached via `.shared`.

### Error monitoring
`TelemetryService` (`Core/Services/TelemetryService.swift`) wraps Sentry: `initialize()` (called once from `wodAIApp.init()`), `identify`/`clearIdentity` on login/logout, `captureError`, `captureMessage`, `captureGraphQLErrors`, and breadcrumbs per GraphQL operation from the interceptor. Prefer routing new error paths through this rather than `print()`.

### Legacy/unused code — do not build on without checking first
`Models/Workout.swift`, `Core/Workout/`, `Core/WorkoutGenerationForm/`, `Core/Fixtures/WorkoutFixture.swift`, and `Core/Components/WorkoutLoadingView.swift` implement the older multi-step "generate a custom workout with components" flow. They are not reachable from `AppNavigationView` and are not part of the live app. If a task looks like it wants the `HIITWorkoutItem` feed model, use that; don't assume the `Workout`/`Component` models in `Models/Workout.swift` are current.
