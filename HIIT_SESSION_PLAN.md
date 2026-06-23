# HIIT Session Integration Plan

Apple Watch sensor integration for real-time workout tracking — buffered sensor stream → GraphQL HIITSession.

---

## Goal

When a user starts a WOD in the app, the Apple Watch begins collecting sensor data (motion, heart rate, altitude, GPS). Data is streamed to the iPhone via WatchConnectivity, buffered locally, and flushed to a `HIITSession` GraphQL mutation on a regular interval. At session end, the full timeline is finalized and movement intervals are computed.

---

## Architecture Overview

```
Apple Watch                   iPhone App                    Backend API
─────────────────────         ──────────────────────────    ──────────────────
HKWorkoutSession              WCSessionDelegate             HIITSession mutations
  └─ heart rate (1Hz)           └─ WatchDataReceiver
CMMotionManager (50Hz)                │
  └─ accel/gyro                       ▼
CMAltimeter (1Hz)             SensorFrameBuffer
CLLocationManager (1Hz)         └─ in-memory ring buffer
       │                              │
       │ WCSession.sendMessage()      ▼   every 10s or 200 frames
       ────────────────────────▶ HIITSessionManager ──────────────────────▶ AppendSensorFramesMutation
                                      │
                                      │   on session end
                                      ▼
                               MovementClassifier ──────────────────────────▶ CompleteHIITSessionMutation
                                 └─ heuristic segmentation
                                 └─ rep count per interval
```

---

## GraphQL Schema Additions

### New Types

```graphql
enum HIITSessionStatus {
  ACTIVE
  COMPLETED
  ABANDONED
}

type SensorFrame {
  timestamp: Float!        # seconds since session start
  # Motion (g-force, radians/sec)
  accelX: Float
  accelY: Float
  accelZ: Float
  gyroX: Float
  gyroY: Float
  gyroZ: Float
  # Orientation
  pitch: Float
  roll: Float
  yaw: Float
  # Vitals
  heartRate: Float         # BPM
  # Environmental
  relativeAltitude: Float  # meters above session start point
  lat: Float
  lng: Float
  horizontalAccuracy: Float
}

type MovementInterval {
  movement: String!        # matches movement name from WOD definition
  startTimestamp: Float!
  endTimestamp: Float!
  repCount: Int
  avgHeartRate: Float
  peakAcceleration: Float
  confidence: Float        # 0.0–1.0, heuristic quality score
}

type HIITSession {
  id: ID!
  wodId: ID!
  userId: ID!
  startedAt: DateTime!
  endedAt: DateTime
  status: HIITSessionStatus!
  durationSeconds: Float
  totalFrames: Int
  sensorFrames: [SensorFrame!]!
  movementIntervals: [MovementInterval!]!
}
```

### New Mutations

```graphql
# Called when user taps Start — establishes the session record
mutation CreateHIITSession(
  $wodId: ID!
  $startedAt: DateTime!
): HIITSession!

# Called every ~10 seconds — appends buffered frames
mutation AppendSensorFrames(
  $sessionId: ID!
  $frames: [SensorFrameInput!]!
): Boolean!

# Called when user ends the workout — finalizes with movement timeline
mutation CompleteHIITSession(
  $sessionId: ID!
  $endedAt: DateTime!
  $movementIntervals: [MovementIntervalInput!]!
): HIITSession!

# Called if user abandons mid-session
mutation AbandonHIITSession(
  $sessionId: ID!
): Boolean!
```

---

## New Files / Targets

### 1. watchOS App Target (`wodAI Watch`)

```
wodAI Watch/
  WatchWorkoutManager.swift     — HKWorkoutSession lifecycle, HR collection
  MotionCollector.swift         — CMMotionManager at 50Hz, CMAltimeter, CLLocation
  WatchSessionRelay.swift       — WCSession sender; batches frames, sends to iPhone
  WatchRootView.swift           — minimal watchOS UI (start/stop/elapsed)
  Info.plist
```

### 2. iPhone-side additions (`wodAI/Core/HIITSession/`)

```
wodAI/Core/HIITSession/
  HIITSessionManager.swift      — session lifecycle, owns buffer, drives mutations
  WatchDataReceiver.swift       — WCSessionDelegate; decodes incoming frames
  SensorFrameBuffer.swift       — thread-safe ring buffer (max ~2,000 frames)
  MovementClassifier.swift      — segments frame stream into movement intervals
  HIITSessionService.swift      — wraps the three GraphQL mutations
```

### 3. GraphQL operation files (`wodAI/GraphQL/`)

```
wodAI/GraphQL/
  CreateHIITSession.graphql
  AppendSensorFrames.graphql
  CompleteHIITSession.graphql
  AbandonHIITSession.graphql
```

---

## Data Flow Detail

### Session Start (user taps "Start" on WeeklyWorkoutCard)

1. `HIITSessionManager.startSession(wod:)` is called.
2. Fires `CreateHIITSession` mutation → receives `sessionId`.
3. Sends WCSession activation message to Watch with `{ "action": "startSession", "movements": [...] }` — the known movement list from the WOD so the Watch can display it.
4. Watch starts `HKWorkoutSession`, `CMMotionManager`, and `CMAltimeter`.
5. A 10-second `Timer` begins on the iPhone to trigger periodic flushes.

### Data Collection (Watch → iPhone)

Watch batches 50 frames (~1s at 50Hz) into a `[String: Any]` dict and calls `WCSession.shared.sendMessage(batch, replyHandler: nil)`.

```swift
// Example batch payload from Watch
[
  "t": 0,          // batch start offset in ms from session start
  "hz": 50,
  "frames": [
    [0.12, -0.31, 0.89, 0.22, -1.87, 0.09, nil, nil, nil, nil, nil],
    // [accelX, accelY, accelZ, gyroX, gyroY, gyroZ, hr, alt, lat, lng, hacc]
    // nil = not available at this sample
    ...
  ],
  "hr": 168.0,     // latest HR reading (may not update every frame)
  "alt": 0.23      // relative altitude in meters
]
```

Keeping the payload compact (array-of-arrays rather than array-of-dicts) keeps WatchConnectivity message size well under the 65KB limit.

### Buffer & Flush (iPhone)

`WatchDataReceiver` decodes batches and appends decoded `SensorFrame` values to `SensorFrameBuffer`. Every 10 seconds, `HIITSessionManager` drains the buffer and fires `AppendSensorFrames`.

If the app is backgrounded, `SensorFrameBuffer` can spill to a local SQLite write-ahead log (Phase 2 concern).

### Session End (user taps "Finish")

1. iPhone sends `{ "action": "stopSession" }` to Watch via WCSession.
2. Watch ends `HKWorkoutSession`.
3. iPhone flushes remaining buffer with one final `AppendSensorFrames` call.
4. `MovementClassifier.classify(sessionId:)` runs synchronously on the buffered timeline.
5. `CompleteHIITSession` mutation fires with the movement interval list.
6. UI navigates to a session summary screen.

---

## Movement Classification — Phase 1 (Heuristic)

No training data required. Each WOD already declares its component movements in order. The classifier uses that structure as a prior.

### Algorithm

```
1. Load movement sequence from WOD (e.g. ["Thruster", "Pull-up", "Thruster", "Pull-up"])
2. Detect rep boundaries using vertical acceleration (userAcceleration.y) threshold crossing:
   - Threshold: +1.5g → rep peak
   - Minimum rep duration: 400ms (debounce)
3. Assign movements to rep clusters using rest detection:
   - Rest = |accel| < 0.15g for > 2s
   - Each rest boundary separates one movement block from the next
4. Map blocks to WOD movement sequence in order
5. Compute per-interval stats: repCount, avgHR, peakAccel
```

This approach correctly handles AMRAPs and rounds because the movement sequence repeats — the classifier cycles through the WOD's movement list and wraps.

### Expected Accuracy (Phase 1)

| Scenario | Expected accuracy |
|---|---|
| Barbell cycling (thrusters, C&J) | ~80% — strong vertical signature |
| Gymnastics (pull-ups, T2B) | ~70% — wrist rotation is distinct |
| Mixed modal (burpees + box jumps) | ~65% — altitude helps differentiate |
| Mono-structural (row, bike) | ~50% — similar cadence makes segmentation harder |

Accuracy is against correctly identifying *which movement* is being performed in a given time window. Rep count accuracy is higher (~85–90%) since it only requires peak detection on the primary axis.

---

## Implementation Phases

### Phase 1 — Core Pipeline (3–4 weeks)

**Goal:** End-to-end sensor stream reaches the backend. No movement classification yet.

- [ ] Add watchOS app target to Xcode project
- [ ] Implement `WatchWorkoutManager` (HKWorkoutSession, HR from HKLiveWorkoutBuilder)
- [ ] Implement `MotionCollector` (CMMotionManager @ 50Hz, CMAltimeter)
- [ ] Implement `WatchSessionRelay` (WCSession sender, compact batch encoding)
- [ ] Implement `WatchDataReceiver` + `SensorFrameBuffer` on iPhone
- [ ] Wire `HIITSessionManager` into `WeeklyWorkoutCard` start action
- [ ] Add `CreateHIITSession`, `AppendSensorFrames`, `AbandonHIITSession` mutations
- [ ] 10-second flush timer with retry on network error
- [ ] Sync schema and regenerate Apollo types

**Deliverable:** Starting a WOD creates a HIITSession record; sensor frames appear in the DB in near real-time.

---

### Phase 2 — Movement Timeline (2–3 weeks)

**Goal:** Completed sessions include a classified movement interval timeline.

- [ ] Implement `MovementClassifier` with vertical-axis threshold algorithm
- [ ] Load WOD movement list into Watch at session start
- [ ] Add `CompleteHIITSession` mutation with `movementIntervals` payload
- [ ] Session summary screen: timeline strip showing movement blocks + HR overlay
- [ ] Sync schema and regenerate Apollo types

**Deliverable:** After a WOD, the session shows which movements were performed and when, with rep counts.

---

### Phase 3 — Enrichment (2 weeks)

**Goal:** Higher-quality data and better differentiation between similar movements.

- [ ] Add GPS tracking (outdoor runs, distances)
- [ ] Use `relativeAltitude` to differentiate box jumps, double-unders, and rope climbs
- [ ] Detect rest intervals and flag them separately in the timeline
- [ ] Handle missed Watch connection gracefully (phone-only fallback using microphone motion, none of the IMU data)
- [ ] Background app refresh to flush pending frames after app resumes

---

### Phase 4 — ML Classification (Future, data-dependent)

**Goal:** Replace heuristic segmentation with a trained model.

- Accumulate labeled sessions from Phase 1–3 (ground-truth movement sequences known from WOD definition)
- Use `CreateML` Activity Classifier on a sliding window of `[accelX, accelY, accelZ, gyroX, gyroY, gyroZ]`
- Ship as a Core ML model embedded in the Watch app for on-device inference
- Fall back to heuristic if model confidence < 0.6

---

## Key Implementation Notes

### WatchConnectivity Message Size
Each 50-frame batch at 50Hz covers 1 second of data. An 11-field frame as array takes ~88 bytes. 50 frames = ~4.4KB. WCSession limit is 65KB per message — 14× headroom.

### Battery Impact
`CMMotionManager` at 50Hz is moderate; 100Hz would double motion processing. 50Hz gives 10ms resolution (enough for CrossFit movements, shortest rep peaks ~400ms). Heart rate via `HKLiveWorkoutBuilder` is free — it uses the optical sensor already active during workout mode.

### iPhone-side Buffer Size
At 50Hz for a 60-minute WOD: 180,000 frames. At ~88 bytes each = ~15MB in memory. This is acceptable. We flush every 10s so the in-flight buffer is at most ~500 frames (~44KB). After flush, frames are dropped from memory (backend is the source of truth).

### Error Recovery
If `AppendSensorFrames` fails, frames stay in the buffer and the next tick retries. If the session is lost entirely (crash), frames are unrecoverable in Phase 1. Phase 3 adds write-ahead log to Core Data as a durability backstop.

### Watch Pairing UX
No explicit pairing step required — WatchConnectivity handles device pairing. The app should:
1. Check `WCSession.isReachable` before showing the Start button
2. Show a "Connect your Watch" prompt if not paired/reachable
3. Allow starting a session without a Watch (no sensor data, just session record)

---

## Open Questions for Backend

1. **Compression**: Should `AppendSensorFrames` accept a base64-encoded binary blob instead of a JSON array to reduce payload size?
2. **Frame deduplication**: If a flush is retried, will duplicate frames be silently ignored by the backend?
3. **Movement interval storage**: Are `movementIntervals` stored on the session record or in a separate table (affects query shape for the timeline view)?
4. **Real-time access**: Does the backend need to support querying in-progress sessions, or is the data only needed after `CompleteHIITSession`?
