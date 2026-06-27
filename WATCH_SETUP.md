# Apple Watch Workout Execution — Setup & Wiring

This is the manual Xcode wiring for the watch workout feature. The Swift sources are
already written; they will not compile until the watchOS target exists and target
memberships / capabilities / codegen are configured below. (Adding a target safely means
editing `project.pbxproj`, which is why it's done in Xcode's UI, not by script.)

See the architecture doc for the why; this is the how.

## 1. Add the watchOS App target

`File ▸ New ▸ Target… ▸ watchOS ▸ App`
- Product Name: **wodAI Watch**
- "Watch App for iOS App" / companion → choose **wodAI** as the companion app.
- Language: Swift, Interface: SwiftUI.
- After creation, **delete** the generated `ContentView.swift` and the generated
  `…App.swift` for the watch target — `wodAI Watch/wodAIWatchApp.swift` (already written)
  is the single `@main`. Confirm there is exactly one `@main` in the watch target.

## 2. File inventory & target membership

Set Target Membership (File Inspector ▸ Target Membership) exactly as below.

**Shared — membership in BOTH `wodAI` and `wodAI Watch`:**
- `wodAI/Core/HIITSession/Shared/WorkoutExecutionPayload.swift`
- `wodAI/Core/HIITSession/Shared/SensorFrame.swift`
- `wodAI/Core/HIITSession/Shared/ExecutionEngine.swift`
- `wodAI/Core/HIITSession/Shared/WatchConnectivityProtocol.swift`

**Watch only — membership in `wodAI Watch`:** (these live in the `wodAI Watch/` folder)
- `wodAIWatchApp.swift`, `WatchExecutionView.swift`, `WatchSessionCoordinator.swift`
- `WatchWorkoutSession.swift`, `MotionCollector.swift`, `WatchConnectivityRelay.swift`
- `WKHaptics.swift`

**iPhone only — membership in `wodAI`:**
- `wodAI/Core/HIITSession/SensorFrameBuffer.swift`
- `wodAI/Core/HIITSession/PhoneConnectivityBridge.swift`
- `wodAI/Core/HIITSession/HIITSessionService.swift`
- `wodAI/Core/HIITSession/HIITSessionManager.swift`

**Tests — membership in `wodAITests`:**
- `wodAITests/HIITExecutionTests.swift`

> The shared files live under the `wodAI/` folder. Because the project uses
> `PBXFileSystemSynchronizedRootGroup`, new files are auto-added to the `wodAI` target;
> you must then ALSO check `wodAI Watch` for the four shared files, and UNCHECK `wodAI`
> for the watch-only files if Xcode added them.

## 3. Capabilities & Info.plist (watch target)

Add to the **wodAI Watch** target:
- **HealthKit** capability (Signing & Capabilities ▸ + Capability ▸ HealthKit). This adds
  a `*.entitlements` with `com.apple.developer.healthkit`.
- Info.plist usage strings:
  - `NSHealthShareUsageDescription` — "Reads your heart rate during workouts."
  - `NSHealthUpdateUsageDescription` — "Records your workout."
  - `NSMotionUsageDescription` — "Uses motion to track how you move during a workout."
- Background runtime: add `WKBackgroundModes` = `["workout-processing"]` to the watch
  Info.plist so the `HKWorkoutSession` keeps the app alive screen-off.

No new capabilities are required on the **wodAI** (iPhone) target — it only receives data
over WatchConnectivity and reuses the existing GraphQL transport/auth.

## 4. Regenerate the GraphQL API

The four mutations + the local schema stand-in are in `wodAI/GraphQL/`:
- `HIITSession.additions.graphqls` (local stand-in — DELETE once the backend ships these
  types and `sync-schema.sh` pulls them into `schema.graphqls`)
- `CreateHIITSession.graphql`, `AppendSensorFrames.graphql`, `CompleteHIITSession.graphql`,
  `AbandonHIITSession.graphql`

Regenerate (config already globs `wodAI/GraphQL/**`):
```bash
apollo-ios-cli generate --config apollo-codegen-config.json
```
This produces `CreateHIITSessionMutation`, `AppendSensorFramesMutation`,
`CompleteHIITSessionMutation`, `AbandonHIITSessionMutation`, and `SensorFrameInput` in the
`WodAiAPI` package — which is what `HIITSessionService.swift` imports.

## 5. Wire into the app

- App launch (`wodAIApp.swift`): `HIITSessionManager.shared.activate()` to bring up
  WatchConnectivity early.
- Start action (where `HIITWorkoutViewModel.startExecution()` is called today): also call
  `await HIITSessionManager.shared.start(workout: item, movements: …)`. Pass the workout's
  ordered movement names when available (used for the EMOM movement display); empty is fine
  for v1 — the watch degrades gracefully.
- Finish / exit: call `await HIITSessionManager.shared.finish()` (or `.abandon()`).
- Gate the Start button's "watch ready" affordance on
  `HIITSessionManager.shared.bridge.isWatchAppInstalled` (NOT `isReachable`).

## 6. Verify

- **Unit tests** (no device): `Cmd+U`, or filter to `HIITExecutionTests` — covers timing
  math (AMRAP/EMOM/Tabata/For Time), interval parsing, frame wire round-trip, buffer.
- **Watch standalone** (real device — HR/motion aren't in the simulator): run the
  `wodAI Watch` scheme; confirm 3 swipeable screens, countdown → timer, format behaviors,
  live BPM.
- **End-to-end**: point `GRAPHQL_ENDPOINT` at a backend implementing the contract; start a
  workout from the phone; confirm `CreateHIITSession` returns an id, `AppendSensorFrames`
  fires ~every 10s, `CompleteHIITSession` on finish. Toggle airplane mode briefly to confirm
  frames are retained and retried (buffer re-enqueue) and that locked-phone frames arrive via
  `transferUserInfo`.

## Known v1 limitations / follow-ups

- `startedAt` sent to `CreateHIITSession` is the Start-tap time; frame timestamps are
  relative to the watch's countdown-end t=0 (~10s later). Acceptable offset for v1; reconcile
  server-side or send the countdown-end time if exact alignment is needed.
- Movement classification / `movementIntervals` is out of scope — `CompleteHIITSession` is
  sent with an empty list.
- Tabata/EMOM interval structure is parsed heuristically from `displayText` (`IntervalConfig.parse`);
  add structured schema fields later for reliability.
