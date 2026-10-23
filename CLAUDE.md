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
- **Test**: `Cmd+U`, or Test Navigator to run a single test. Tests use Swift Testing (`import Testing`, `@Test func ...`, `#expect(...)`), not XCTest (UI tests in `wodAIUITests/` are XCTest).
- **CLI / CI**: `scripts/run-tests.sh` (optionally `SIMULATOR="iPhone 17"`) runs the unit tests plus `WeekNavigationUITests` on a simulator, results in `build/TestResults.xcresult`. `.github/workflows/ios-tests.yml` runs the same script on pushes and PRs to `main`. UI tests launch the app with `-uiTesting` (`Core/UITesting/UITestMode.swift`, Debug only): a stand-in athlete is signed in and the Workout page reads fixtures (`AssistantViewModel.uiTesting()`, sessions named "W-1 D3" by week offset and day), so no backend is involved. Running them on a simulator leaves that stand-in signed in there.
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
- `.workout` → `AssistantView` (default landing screen; a week's sessions, block by block, menu label "Workout"; opens on this week, swipe the week strip to move a week (same day of the week), swiping days carries on across week edges, "Today" returns)
- `.saved` → `SavedWorkoutsView`
- `.activity` → `ActivityView` (menu label "Activity"): the "This week vs your usual" card (`RecoveryStatusCard`, 7- vs 28-day load, strength and WODs; worded as a comparison with the athlete's own usual, never as injury risk), then the week's charts in one card (`StatsChartsSection`: a segmented toggle between Volume, Intensity minutes, Training load and Muscles; Muscles (`StatKind.recovery`) isn't a weekly chart but "Recovery right now" (`MuscleRecoverySection` in `Core/Stats/MuscleRecovery.swift`: every region still fatigued from the backend's `muscleReadiness`, the same scores the planner uses, with when it's ready to train and when it's fully recovered, whatever week is selected; Apollo-free `MuscleReadiness` tested in `wodAITests/MuscleReadinessTests.swift`); the others each show their chart and a definition from the Apollo-free `StatKind` in `Core/Stats/StatGuide.swift`, tested in `wodAITests/StatGuideTests.swift`; the three daily series draw as a running total, this week solid over last week dotted, with `ActivityStatsStore` loading the previous week alongside as `previousStats`), each chart also shows the server's `provenance` line (what was measured, estimated, left out). Both recovery cards have an info button opening a plain-language "how we work this out" sheet (`Core/Stats/ExplainerButton.swift`, tested in `wodAITests/ExplainerTests.swift`). Then the week's completed strength and HIIT workouts under a divider for each day with activity; a lift with a set that beat the athlete's best shows a PR badge (`StrengthComponent.personalRecord`). `Core/Stats/ActivityFeed.swift` holds the Apollo-free grouping and card text (rep scheme, weight progression, RPE band; tested in `wodAITests/ActivityFeedTests.swift`). `ActivityFeedStore` loads `CompletedHiitWorkoutsQuery` and `CompletedStrengthWorkouts` per week. HIIT cards are tinted by RPE (`RPEEasy`…`RPEMax` color assets) and show the `heartRateSeries` sparkline when one was recorded. Tapping a card edits it: HIIT pushes `EditHiitCompletionView` (`HIITWorkoutCompletionView` with `isEditing`, saved via `UpdateHiitCompletion`, sending effort always and a score only if changed: `CompletedHiitEntry.edit(from:)`); strength pushes `StrengthWorkoutView` on the piece, where re-logging a set overwrites it. Edits patch the feed in place (`ActivityFeedStore.replace`/`remove`) and the week's charts reload on return.
- `.equipment` → `GymProfilesView`
- `.skills` → `SkillsView`
- `.devices` → `HeartRateDevicesView` (menu label "Heart Rate Monitor")
- `.connect` → `ConnectView` (menu label "Connect"): integrations that pull and publish fitness data. Apple Health is the only one so far (`AppleHealthSettingsView`, see Apple Health below).

Tapping a session block pushes `BlockPagerView` (swipe between blocks, dot indicator, auto-advance on completion; once every block in the session is done it pops back to the Workout page and collapses that session, which shows its completed check), which shows `StrengthWorkoutView` or `MetconView`. `MetconView` (formerly `HIITWorkoutView`) has no menu entry: it opens only from a block or a saved workout. Under the WOD card it shows the piece's own "Stimulus" (`HIITWorkoutItem.pieceStimulus`, the backend's per-athlete `WorkoutHiitPiece.pieceStimulus`), then the workout's generic `stimulus` folded under "About this workout".

**How-to videos:** the strength header (`ExerciseSummaryHeader`) plays the current exercise's `videoUrl` inline, or shows a placeholder when there's none. Links are curated in the backend's admin tool. `Core/Components/ExerciseVideo.swift` decides how to play a URL (`ExerciseVideoSource`, tested in `wodAITests/ExerciseVideoSourceTests.swift`): YouTube links play in a `youtube-nocookie` embed in a `WKWebView`, loaded with a `Referer` header because YouTube refuses embeds without one ("Error 153"); any other URL (later, self-hosted video) plays in AVKit.

`AssistantViewModel.week` is the shown week and `currentWeek` today's; planning (`isGenerating`, the planning banner, `refetchWeek`) only concerns `currentWeek`. Each week loads once through `weekSessions` (stubbed in tests) and stays cached in `sessions`, refreshed quietly on revisits; a fetch replaces only its own week's days. Week math is `AssistantWeek.shifted(by:)`.

A day can hold several sessions (`AssistantViewModel.sessions: [Date: [AssistantSession]]`): the programmed one plus any imports. On a rest day the planner writes an optional light activity (`Workout.optional` → `AssistantSession.isOptional`): it shows an "Optional" chip and starts collapsed. Each renders as a collapsible `SessionSectionView` (source chip, done count, colored rail). Anything block-addressed is scoped by session id (`AssistantBlockRoute(sessionId:blockId:)`, `openableBlocks(in:)`, `markHiitCompleted(sessionId:blockId:)`, `updateStrength(_:sessionId:)`), and the pager only pages within one session.

**Deleting a session:** swipe its header left to reveal Delete (`SessionSectionView`), then confirm. Deletion is optimistic (`AssistantViewModel.deleteSession`, `DeleteWorkoutMutation`) and restores the session if the server refuses. `DaySwipeGuard` stops the page's day swipe from also firing during a header swipe. Sessions still streaming in can't be deleted.

**Create with AI:** the trainer chat's "Create with AI" option (a stopgap until Write Workout for Today runs in the chat) opens `CreateSessionSheet`. `AssistantViewModel.createSession(request:)` streams `workoutGeneration(request:scheduledDate:)` into the selected day through the same pending → streamed → saved flow as the whiteboard import (`streamNewSession`).

**Trainer chat:** `AssistantButton` (bottom-right of the Workout page, where the + menu was; never disabled, hidden while the chat is open) opens `AssistantChatView` ("Coach"), a panel over the dimmed Workout page (✕, swipe the header down, or tap the page to close), with a new `AssistantChatViewModel` each time (`AssistantView.makeChat`; `-uiTesting` passes `AssistantChatViewModel.uiTesting`, which stays off the network because the live API rejects the stand-in token and that signs the app out). `AssistantView.runClientAction` closes the chat and opens the scanner or Create sheet, or has the trainer `say` why not while a session is still streaming in; an import's result stays on the Workout page. UI test: `wodAIUITests/AssistantChatUITests.swift`. `AssistantChatViewModel` shows a greeting at once (the last one the server sent, cached in `UserDefaults`, else `ChatTranscript.bundled`) and swaps in `AssistantGreetingQuery`'s. `ChatTranscript` is the Apollo-free model and its rules (one tap per turn, unknown actions hidden, streamed replies, retry), tested in `wodAITests/AssistantChatTests.swift`. A reply chip or typed text runs a turn (`AssistantTurnStream`, the `assistantTurn` subscription): the whole transcript (greeting included, errors left out), the flow and the time zone go up (`AssistantTurnRequest`), and the reply streams into the transcript with its suggestions; the final `AssistantTurnComplete` text replaces what streamed. A failure shows the server's message with Try again (`retry` re-sends the same turn); closing the chat or dropping the view model cancels the turn (unsubscribes). An `AssistantAction` the trainer ends on isn't run in the chat: it goes to `onAction` once the turn completes, and `AssistantView.runAction` runs it on the Workout page, closing the chat (the result shows on the page, as with the whiteboard): `generateSession` → `AssistantViewModel.createSessionToday(request:)`; `planWeek` → `replan(dates:request:replaceWorkoutIds:)` (`ReplanWeekMutation`, i.e. `startWeeklyPlan` with dates, then `watchPlanning()`; only the picked days can show "Building this session…"; `replaceWorkoutIds` stays optional end to end, since nil means the server's default and [] means none); `openWhiteboardScanner` → the scanner. While a session is still coming in or a plan is running, the coach says so instead. Program My Week's `PICK_DAYS` suggestion (`ChatSuggestion.Action.pickDays`, dates from its JSON payload) renders as a day grid; Done sends `ChatTranscript.pickedDaysMessage` as the athlete's reply (tested in `wodAITests/AssistantActionsTests.swift`). The view model takes an injected `AssistantTurnRunner`, so `wodAITests/AssistantTurnTests.swift` runs it against a fake. Subscriptions share `subscriptionStream` (`Core/SubscriptionStream.swift`: stall timeout, Sentry reporting), as `WorkoutGenerationStream` does.

### Whiteboard import
The trainer chat's Import Workout From Whiteboard option opens `WhiteboardScannerView` (`Core/Import/`). VisionKit live text runs on the phone. When `WhiteboardHeuristic.looksLikeWorkout` passes and holds for about 1s (`WhiteboardStabilityGate`), it captures, downscales (`WhiteboardImageEncoder`) and closes. Where the live camera is unavailable (the Simulator, camera access denied) it falls back to the photo library plus Vision OCR. `AssistantViewModel.importWhiteboard` then streams the backend's `whiteboardImport` subscription into the selected day: a pending placeholder, then blocks via `GenerationProgress`, then the saved session. The server has the final say: a non-workout comes back as `GenerationFailed`, shown in a banner with Try again.

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
New athletes (`needsProvisioning`) go through `Core/Onboarding/`: one short question per screen under a progress bar — goal, Apple Health (see below), experience, schedule (rest days and session length; every other day is a training day, and the server derives days per week), gym preset, equipment, skill questions, lifts, about you. `OnboardingFlow` is the Apollo-free step order and progress math (tested in `wodAITests/OnboardingFlowTests.swift`). Skill questions come from the backend's skill ladders, hardest first: the athlete is asked down a ladder until their first yes (`setSkillLevel` saves that rung; "no" to all saves none). Moving on never waits for the network: each answer is saved in the background, one save at a time in order (`OnboardingAPI`: `UpdateUser`, gym create/update, `SetSkillLevel`, `SetStrengthBenchmark` — lifts are always 1RMs), and Finish waits for every save, retrying failures, then calls `CompleteOnboarding(timezone:)`, which starts planning the athlete's first week on the server. The last screen (`OnboardingPlanningView`, "Hang tight") polls `WeeklyPlanStatus` until today's date is planned (or the run finishes), then `AuthState.completeProvisioning()` hands off to the Workout page; `PlanWait` decides waiting/slow/failed/ready. An athlete who leaves mid-planning resumes on that screen (`load()` checks `IsUserProvisioned` first). On the Workout page, `AssistantViewModel.watchPlanning()` shows "Planning the rest of your week…" and quietly reloads (`refetchWeek`, no spinner) as more days land. While the run is RUNNING, every empty day from today to the end of the week shows a "Building this session…" card (`isGenerating(_:)`) instead of "No workout scheduled". The planner picks its own rest days, so the app can't tell which days will stay empty; once the run ends (after a final reload) the days it skipped read "No workout scheduled". The status comes from the backend's `JobStatus` (`COMPLETE` → done; `FAILED`/`CANCELED` → failed). Single-choice steps advance on tap; the rest only from their button. Every view-model action names its step and is ignored unless that step is current, so a tap landing on a screen as it slides away can't answer twice or skip ahead (`wodAITests/OnboardingViewModelTests.swift`).
- Session expiry: `AuthorizationInterceptor` (in `Network.swift`) scans every GraphQL response for error text containing "unauthorized"/"auth"/"token" → calls `AuthState.handleSessionExpired()` → posts `.userDidLogout`. `ContentView` observes that notification and force-signs-out on the main thread.
- `AppleSignInService.shared.checkCredentialState()` runs on every launch (from `ContentView.onAppear`) to revoke local auth if the Apple credential was revoked externally.

### Apple Health
`Core/Health/`. `HealthKitDataSource` (`HealthStore.swift`) is the only code that touches HealthKit; everything else goes through the `HealthDataSource` protocol, and `HealthModels.swift` is HealthKit- and Apollo-free (tested in `wodAITests/HealthTests.swift`).
- **Reading** (onboarding's step after the goal, and Connect → Apple Health → Sync now): one snapshot from the phone's own database, every query at once, with no per-workout queries (each `HKWorkout` carries its heart-rate statistics). The last 90 days of workouts are summarized on the device (`WorkoutHistorySummary`; walks aren't cardio) and only the summary goes up (`ImportHealthSnapshot`). The server backfills resting/max heart rate and, in onboarding, sets the level. iOS doesn't say whether a read was denied, so denied and no-data look the same and never block anything.
- **Onboarding**: connecting fills in About you at once (never over what was typed) and moves on; only the read is waited for. The upload is queued with the other onboarding saves (`applyLevel: true`), so Finish waits for it and retries it, and the server sets the athlete's level from Health; the athlete never picks a level. When the snapshot can suggest one (`HealthSnapshot.canSuggestLevel`, mirroring the server's rule), Experience saves only years; otherwise Experience sets the level as before. The step is left out where Health isn't available (`OnboardingFlow(includesAppleHealth:)`). Sync now in Connect → Apple Health refreshes the data but never changes the level.
- **Writing** (on by default, `HealthSync.writesWorkouts`; only while connected): a Workout-page session is written as its work is logged, finished or not. `AssistantViewModel.sessionProgressed` fires after every server-confirmed set or metcon result, then `HealthSync.sessionProgressed` waits ~20 s for more (no wait once the session is complete), fetches it (`HealthSession`) and writes one workout from the first logged work to the last, with the heart rate its metcons recorded. Each write's sync version is its end time, so more work replaces the earlier workout. A metcon done on its own (a saved workout) is written when its result saves. Workouts carry a sync identifier (`wodai-session-<id>`, `wodai-hiit-<completionId>`), so a repeat replaces instead of adding; a workout from another app at the same time (an Apple Watch workout) means nothing is written. A skipped write (not connected, fetch failed, overlap, not allowed) is reported to Sentry as `health.write_skipped` with a `reason` tag.
- **Disconnect** deletes what the server keeps from Health; iOS permissions can only be revoked in the Health app.

### Networking
`Network.shared` (`Core/Network.swift`) is a lazy singleton `ApolloClient` built from `AppConfig.graphQLEndpoint` on a `SplitNetworkTransport`. Subscriptions (`workoutGeneration`, `whiteboardImport`, consumed via `WorkoutGenerationStream`) go over a `WebSocketTransport` speaking `graphql-transport-ws` on the same path, authenticated once per socket from `connection_init`; it connects only when `connectSubscriptions()` is called and reconnects when the token changes. Queries and mutations go over HTTP through this interceptor chain:
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

### Product analytics
`AnalyticsService` (`Core/Services/AnalyticsService.swift`) wraps PostHog (US cloud): `initialize()` next to Sentry's (off when `POSTHOG_API_KEY` in `Info.plist` is empty, and never in `-uiTesting`), `identify`/`reset` on login/logout, every event tagged `is_debug_build`. Events are the typed `AnalyticsEvent` (`Core/Services/AnalyticsEvent.swift`): add a case rather than a string, and send ids and counts only, never what anyone typed or anything from Apple Health. The coach chat sends `assistant_opened`, `assistant_option_tapped`, `assistant_turn`, `assistant_flow_completed` (the Workout page ran what the chat ended on; the backend's `generation_*` / `weekly_plan_*` events say whether it saved), `assistant_flow_failed` and `assistant_closed` (with `stage`: greeting, chatting, error, handed_off); `AssistantChatViewModel` takes the tracker as `track:` so `wodAITests/AssistantAnalyticsTests.swift` checks them.

### Legacy/unused code — do not build on without checking first
`Models/Workout.swift`, `Core/Workout/`, `Core/WorkoutGenerationForm/`, `Core/Fixtures/WorkoutFixture.swift`, and `Core/Components/WorkoutLoadingView.swift` implement the older multi-step "generate a custom workout with components" flow. They are not reachable from `AppNavigationView` and are not part of the live app. If a task looks like it wants the `HIITWorkoutItem` feed model, use that; don't assume the `Workout`/`Component` models in `Models/Workout.swift` are current.
