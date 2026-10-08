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
- `GRAPHQL_ENDPOINT` is set per-config (Debug `http://localhost:3000/graphql`, Release `https://move-adapt.com/graphql`), but **it never reaches the app**: Xcode only copies Apple's own `INFOPLIST_KEY_*` keys into the generated `Info.plist`, so `AppConfig.graphQLEndpoint` always falls back to `https://api.wodai.run` — the live backend — in Debug builds too. To run against a local backend, add `GRAPHQL_ENDPOINT` to the built app's `Info.plist` (or fix the plist wiring) — otherwise a Debug run writes to prod.
- Sentry DSN is wired the same way (`SENTRY_DSN` → `INFOPLIST_KEY_SENTRY_DSN` → `AppConfig.sentryDSN`), currently blank in `Base.xcconfig`.

## Architecture

### Navigation
There is no tab bar. `wodAIApp` → `ContentView` routes on `AuthState.shared`:
```
ContentView
├── unauthenticated              → AuthenticationView (Login/SignUp toggle)
├── authenticated + needsProvisioning → OnboardingView
└── authenticated + provisioned  → RootAppView → AppNavigationView
```
`AppNavigationView` is a single `NavigationStack` with a hamburger-triggered side menu (`SideMenuView`), not a `TabView`. Destinations are switched by local `@State`, no deep-link/notification-based tab switching:
- `.workout` → `AssistantView` (default landing screen; the week's sessions, block by block, menu label "Workout")
- `.saved` → `SavedWorkoutsView`
- `.activity` → `ActivityView` (menu label "Stats"): weekly charts, then the week's completed strength and HIIT workouts under a divider for each day with activity. `Core/Stats/ActivityFeed.swift` holds the Apollo-free grouping and card text (rep scheme, weight progression, RPE band; tested in `wodAITests/ActivityFeedTests.swift`). `ActivityFeedStore` loads `CompletedHiitWorkoutsQuery` and `CompletedStrengthWorkouts` per week. HIIT cards are tinted by RPE (`RPEEasy`…`RPEMax` color assets) and show the `heartRateSeries` sparkline when one was recorded. Tapping a card edits it: HIIT pushes `EditHiitCompletionView` (`HIITWorkoutCompletionView` with `isEditing`, saved via `UpdateHiitCompletion`, sending effort always and a score only if changed: `CompletedHiitEntry.edit(from:)`); strength pushes `StrengthWorkoutView` on the piece, where re-logging a set overwrites it. Edits patch the feed in place (`ActivityFeedStore.replace`/`remove`) and the week's charts reload on return.
- `.equipment` → `GymProfilesView`
- `.skills` → `SkillsView`
- `.devices` → `HeartRateDevicesView` (menu label "Heart Rate Monitor")

Tapping a session block pushes `BlockPagerView` (swipe between blocks, dot indicator, auto-advance on completion; once every block in the session is done it pops back to the Workout page and collapses that session, which shows its completed check), which shows `StrengthWorkoutView` or `MetconView`. `MetconView` (formerly `HIITWorkoutView`) has no menu entry: it opens only from a block or a saved workout.

**How-to videos:** the strength header (`ExerciseSummaryHeader`) plays the current exercise's `videoUrl` inline, or shows a placeholder when there's none. Links are curated in the backend's admin tool. `Core/Components/ExerciseVideo.swift` decides how to play a URL (`ExerciseVideoSource`, tested in `wodAITests/ExerciseVideoSourceTests.swift`): YouTube links play in a `youtube-nocookie` embed in a `WKWebView`, loaded with a `Referer` header because YouTube refuses embeds without one ("Error 153"); any other URL (later, self-hosted video) plays in AVKit.

A day can hold several sessions (`AssistantViewModel.sessions: [Date: [AssistantSession]]`): the programmed one plus any imports. On a rest day the planner writes an optional light activity (`Workout.optional` → `AssistantSession.isOptional`): it shows an "Optional" chip and starts collapsed. Each renders as a collapsible `SessionSectionView` (source chip, done count, colored rail). Anything block-addressed is scoped by session id (`AssistantBlockRoute(sessionId:blockId:)`, `openableBlocks(in:)`, `markHiitCompleted(sessionId:blockId:)`, `updateStrength(_:sessionId:)`), and the pager only pages within one session.

**Deleting a session:** swipe its header left to reveal Delete (`SessionSectionView`), then confirm. Deletion is optimistic (`AssistantViewModel.deleteSession`, `DeleteWorkoutMutation`) and restores the session if the server refuses. `DaySwipeGuard` stops the page's day swipe from also firing during a header swipe. Sessions still streaming in can't be deleted.

**Create with AI:** a + menu action opening `CreateSessionSheet`. `AssistantViewModel.createSession(request:)` streams `workoutGeneration(request:scheduledDate:)` into the selected day through the same pending → streamed → saved flow as the whiteboard import (`streamNewSession`).

### Whiteboard import
The floating + on the Workout page (`Core/Components/FloatingActionMenu.swift`; add actions as `QuickAction` cases) opens `WhiteboardScannerView` (`Core/Import/`). VisionKit live text runs on the phone. When `WhiteboardHeuristic.looksLikeWorkout` passes and holds for about 1s (`WhiteboardStabilityGate`), it captures, downscales (`WhiteboardImageEncoder`) and closes. Where the live camera is unavailable (the Simulator, camera access denied) it falls back to the photo library plus Vision OCR. `AssistantViewModel.importWhiteboard` then streams the backend's `whiteboardImport` subscription into the selected day: a pending placeholder, then blocks via `GenerationProgress`, then the saved session. The server has the final say: a non-workout comes back as `GenerationFailed`, shown in a banner with Try again.

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
- Post-auth, `authenticate()` kicks off `checkProvisioningStatus()` (`IsUserProvisionedQuery`), which flips `ContentView`'s routing between `OnboardingView` and `RootAppView`.

### Onboarding
New athletes (`needsProvisioning`) go through `Core/Onboarding/`: one short question per screen under a progress bar — goal, experience, schedule (rest days and session length; every other day is a training day, and the server derives days per week), gym preset, equipment, skill questions, lifts, about you. `OnboardingFlow` is the Apollo-free step order and progress math (tested in `wodAITests/OnboardingFlowTests.swift`). Skill questions come from the backend's skill ladders, hardest first: the athlete is asked down a ladder until their first yes (`setSkillLevel` saves that rung; "no" to all saves none). Moving on never waits for the network: each answer is saved in the background, one save at a time in order (`OnboardingAPI`: `UpdateUser`, gym create/update, `SetSkillLevel`, `SetStrengthBenchmark` — lifts are always 1RMs), and Finish waits for every save, retrying failures, then calls `CompleteOnboarding(timezone:)`, which starts planning the athlete's first week on the server. The last screen (`OnboardingPlanningView`, "Hang tight") polls `WeeklyPlanStatus` until today's date is planned (or the run finishes), then `AuthState.completeProvisioning()` hands off to the Workout page; `PlanWait` decides waiting/slow/failed/ready. An athlete who leaves mid-planning resumes on that screen (`load()` checks `IsUserProvisioned` first). On the Workout page, `AssistantViewModel.watchPlanning()` shows "Planning the rest of your week…" and quietly reloads (`refetchWeek`, no spinner) as more days land. While the run is RUNNING, every empty day from today to the end of the week shows a "Building this session…" card (`isGenerating(_:)`) instead of "No workout scheduled". The planner picks its own rest days, so the app can't tell which days will stay empty; once the run ends (after a final reload) the days it skipped read "No workout scheduled". The status comes from the backend's `JobStatus` (`COMPLETE` → done; `FAILED`/`CANCELED` → failed). Single-choice steps advance on tap; the rest only from their button. Every view-model action names its step and is ignored unless that step is current, so a tap landing on a screen as it slides away can't answer twice or skip ahead (`wodAITests/OnboardingViewModelTests.swift`).
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
| `SensorManager.shared` | Remembered heart-rate device, connection state, latest reading (see Heart rate below) |
| `AuthState.shared` | see Authentication above |
| `Network.shared` | Apollo client |

`AuthState` and `AuthManager` are the only two injected as `@EnvironmentObject` (from `wodAIApp`/`ContentView`); everything else is reached via `.shared`.

### Heart rate / wearables
`Core/Sensors/` records heart rate during a metcon. Everything except `ApolloSessionTelemetryUploader.swift` and the views is Apollo-free and unit-tested (`wodAITests/HeartRateSensorTests.swift`, `WorkoutSensorRecorderTests.swift`).
- **Device layer**: `SensorProvider` is one way of connecting. `BluetoothHeartRateProvider` handles the standard BLE Heart Rate Service (0x180D/0x2A37, parsed by `HeartRateMeasurementParser`): chest straps, and Garmin/Polar/etc. watches in heart-rate broadcast mode. They connect in-app, never through iPhone Settings. Its `CBCentralManager` is created lazily because creating it shows the Bluetooth prompt. Debug builds also register `SimulatedHeartRateProvider` so the flow works in the Simulator. A new device type (Apple Watch app, vendor SDK) is a new provider plus a `SensorProviderKind` case.
- **Brand setup**: `DeviceBrand` detects the brand from the advertised name and carries a per-brand `DeviceSetupGuide` shown in `DeviceConnectSheet`. Brand-specific setup goes here.
- **Recording**: `HIITWorkoutViewModel` starts a `WorkoutSensorRecorder` when the clock starts. It opens a backend `HIITSession`, batches frames every 15 s (retry-safe; the server dedups on timestamp), and on finish returns the server-computed `HeartRateSummary`. `completeHiitWorkout(sessionId:)` links it to the completion. Heart rate never blocks a workout: without a device, or if the session fails to open, the run just isn't recorded.
- **Analytics are server-side** (`workout-generator/src/lib/trainingLoad.ts`): zones, Edwards TRIMP load, calories, `recoveryStatus` (7- vs 28-day load), and the downsampled `CompletedHIITWorkout.heartRateSeries` the Stats feed draws (`HeartRateSparkline`). The client only shows the live zone from the thresholds the session returns.

### Error monitoring
`TelemetryService` (`Core/Services/TelemetryService.swift`) wraps Sentry: `initialize()` (called once from `wodAIApp.init()`), `identify`/`clearIdentity` on login/logout, `captureError`, `captureMessage`, `captureGraphQLErrors`, and breadcrumbs per GraphQL operation from the interceptor. Prefer routing new error paths through this rather than `print()`.

### Legacy/unused code — do not build on without checking first
`Models/Workout.swift`, `Core/Workout/`, `Core/WorkoutGenerationForm/`, `Core/Fixtures/WorkoutFixture.swift`, and `Core/Components/WorkoutLoadingView.swift` implement the older multi-step "generate a custom workout with components" flow. They are not reachable from `AppNavigationView` and are not part of the live app. If a task looks like it wants the `HIITWorkoutItem` feed model, use that; don't assume the `Workout`/`Component` models in `Models/Workout.swift` are current.
