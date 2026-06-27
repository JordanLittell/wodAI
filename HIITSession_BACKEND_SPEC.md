# HIITSession Backend Spec — Watch Telemetry Mutations

**Audience:** backend engineer implementing the GraphQL API for Apple Watch workout sessions.
**Status:** the iOS/watchOS client is built and codegens against a local stand-in
(`wodAI/GraphQL/HIITSession.additions.graphqls`). This spec is the contract the real server
must implement. **Field names and types below must match exactly** — the client's generated
Apollo types are derived from them.

---

## Context

When a user starts a HIIT workout in the app, their Apple Watch streams telemetry
(heart rate + motion + altitude) sampled at up to 50Hz. The watch relays frames to the phone,
which **buffers them in memory and flushes a batch every ~10 seconds** via `appendSensorFrames`.
You are storing a per-session time-series and a session lifecycle record. The phone is the only
caller — the watch never hits the API directly.

Lifecycle: `createHIITSession` (on Start) → many `appendSensorFrames` (every 10s) →
`completeHIITSession` (on Finish) **or** `abandonHIITSession` (on quit/crash-recovery).

---

## Auth (applies to all four mutations)

- All mutations require an authenticated user (reuse the existing JWT `@auth` directive).
- A `HIITSession` is **owned by the creating user**. `appendSensorFrames`, `completeHIITSession`,
  and `abandonHIITSession` MUST verify the `sessionId` belongs to the caller and reject otherwise.
- ⚠️ **Gotcha:** the iOS Apollo interceptor force-logs-out the user on any GraphQL error whose
  message contains `"unauthorized"`, `"auth"`, or `"token"`
  (`wodAI/Core/Network.swift` → `isUnauthorizedGraphQLError`). For non-auth failures (validation,
  not-found, etc.) **do not** use those words in the error message, or you'll bounce users to login.
  Reserve that wording for genuine 401s.

---

## Data model

```graphql
enum HIITSessionStatus { ACTIVE  COMPLETED  ABANDONED }

type HIITSession {
  id: ID!
  wodId: ID!            # references HIITWorkout.id (sent as a stringified Int)
  userId: ID!
  startedAt: DateTime!
  endedAt: DateTime
  status: HIITSessionStatus!
  durationSeconds: Float
  totalFrames: Int
}

input SensorFrameInput {
  timestamp: Float!         # seconds since session t=0 (end of the watch countdown)
  accelX: Float  accelY: Float  accelZ: Float     # g, gravity removed
  gyroX: Float   gyroY: Float   gyroZ: Float       # rad/s
  heartRate: Float          # BPM (may be null on frames where no new HR sample landed)
  relativeAltitude: Float   # meters relative to session start
  lat: Float  lng: Float  horizontalAccuracy: Float  # GPS; null in v1 (indoor)
}

input MovementIntervalInput {   # accepted but EMPTY in v1 (classification is future work)
  movement: String!
  startTimestamp: Float!  endTimestamp: Float!
  repCount: Int  avgHeartRate: Float  peakAcceleration: Float  confidence: Float
}
```

**Storage shape:** keep frames in a separate high-volume time-series table keyed by
`sessionId`, NOT as an array column on the session row. A 60-min session at 50Hz is up to
~180,000 frames. The session record itself is small.

---

## Mutations

### 1. `createHIITSession(wodId: ID!, startedAt: DateTime!): HIITSession!`

Called once when the user taps Start.
- Create a session row: `userId` = caller, `wodId`, `startedAt`, `status = ACTIVE`.
- Return the full `HIITSession` (client only reads `id`, `status`, `startedAt`, but return all).
- `wodId` arrives as a stringified integer (the client's `HIITWorkout.id` is an `Int`). Validate
  it references a real workout if you want, but don't hard-fail if you'd rather keep it loose.

### 2. `appendSensorFrames(sessionId: ID!, frames: [SensorFrameInput!]!): Boolean!`

Called every ~10 seconds with a batch (typically ~500 frames, up to a few thousand on retry).
- Append the batch to the session's time-series. Return `true` on success.
- **Idempotency is required.** On a network failure the client **re-enqueues the same frames and
  resends them on the next tick**, so you WILL receive duplicates. Dedupe on `(sessionId, timestamp)`
  — `timestamp` is unique within a session (frames are ~0.02s apart at 50Hz). Upsert or
  ignore-on-conflict; never double-count toward `totalFrames`.
- Only append to an `ACTIVE` session. If the session is already `COMPLETED`/`ABANDONED`, return
  `false` (or a non-auth-worded error) rather than mutating it.
- Frames may have many `null` fields (HR/altitude don't update every 50Hz sample); store nulls
  as-is. Do not reject a frame for missing optional fields — only `timestamp` is required.

### 3. `completeHIITSession(sessionId: ID!, endedAt: DateTime!, movementIntervals: [MovementIntervalInput!]!): HIITSession!`

Called once when the user finishes. The phone has already sent a final `appendSensorFrames` before
this call, so all frames are in.
- Set `status = COMPLETED`, `endedAt`.
- Compute and persist `durationSeconds` (= `endedAt − startedAt`) and `totalFrames`
  (count of stored frames for the session).
- `movementIntervals` is **empty in v1** — accept and ignore (or store if you stand the table up
  now). When movement classification ships, these become the per-movement timeline.
- Idempotent: completing an already-`COMPLETED` session should return the existing record, not error.
- Return the finalized `HIITSession`.

### 4. `abandonHIITSession(sessionId: ID!): Boolean!`

Called if the user quits mid-session. Set `status = ABANDONED`, set `endedAt = now`. Return `true`.
Idempotent. Keep whatever frames were collected (useful for debugging / partial data).

---

## Non-functional requirements

- **Throughput:** one active session emits a batch every 10s; size the write path for many
  concurrent sessions each doing bulk inserts of a few hundred rows.
- **Payload format (v1):** plain JSON arrays of `SensorFrameInput`, as above. This is fine within
  WatchConnectivity/HTTP limits (batches are ~tens of KB). If frame volume becomes a cost problem
  later, we can add a base64 binary-blob variant — **out of scope for v1**, flag it if you foresee issues.
- **In-progress reads:** v1 does **not** need to query a live/in-progress session — data is consumed
  after `completeHIITSession`. A `hiitSession(id:)` query and a frames/timeline query will be wanted
  later for the session-summary UI; design the schema so they're easy to add, but you don't have to
  build them now.

---

## Decisions we need from you (please confirm)

1. **Dedup strategy** for `appendSensorFrames` retries — confirm you'll key on `(sessionId, timestamp)`.
2. **Time-series storage** — which table/engine (partitioned table, timescale, columnar, etc.)?
3. **`movementIntervals` table** now vs later — affects whether v1 stores the (empty) field.
4. Whether `wodId` should be a hard FK to `HIITWorkout` or kept loose.

---

## When the schema is live

We currently codegen against `wodAI/GraphQL/HIITSession.additions.graphqls` (a local stand-in).
Once these types are in the real SDL:
1. We run `sync-schema.sh` to pull the server SDL into `schema.graphqls`.
2. We **delete** `HIITSession.additions.graphqls` to avoid duplicate-type definitions.
3. We re-run `apollo-ios-cli generate`.

So please keep the deployed field names/types identical to this spec — any drift breaks our
generated client at compile time.
