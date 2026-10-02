//
//  AssistantViewModel.swift
//  wodAI
//
//  Assistant: asks the backend's workout agent (`workoutGeneration`
//  subscription) for a session and lays it out block by block as the agent
//  writes it — "Block A - …", "Block B - …" in session order. Strength blocks are written like a whiteboard; HIIT blocks
//  reuse the feed's WOD card and open in `HIITWorkoutView`.
//

import Foundation
import WodAiAPI

struct AssistantSession {
    let name: String
    let description: String
    let stimulus: String?
    let coaching: String?
    /// The day the session is programmed for; nil if the server's value didn't parse.
    let scheduledDate: Date?
    var blocks: [AssistantBlock]
}

struct AssistantBlock: Identifiable {
    enum Kind {
        case strength(StrengthWorkout)
        case hiit(HIITWorkoutItem)
        /// A block type this build doesn't know how to draw; shown label-only
        /// so it isn't silently dropped.
        case other
    }

    /// The block's position in the session (`order`), unique within it.
    let id: Int
    let label: String
    let letter: String
    var kind: Kind

    /// The destination a tap on this block should push, or `nil` for blocks
    /// this build can't open (`.other`).
    var route: AssistantRoute? {
        switch kind {
        case let .strength(workout):
            return .strength(workout)
        case let .hiit(workout):
            return .hiit(workout)
        case .other:
            return nil
        }
    }
}

/// A pushable destination for a session block. Value-typed so a single
/// `navigationDestination(for:)` can fan out to the right screen.
enum AssistantRoute: Hashable {
    case strength(StrengthWorkout)
    case hiit(HIITWorkoutItem)
}

/// The strength data carried to `StrengthWorkoutView`, decoupled from the
/// generated Apollo type.
struct StrengthDetail: Hashable {
    let title: String
    let instructions: String
    let lines: [String]
    let components: [StrengthComponent]
}

/// One strength set, decoupled from the generated Apollo type so the
/// whiteboard formatting is testable on its own.
struct WhiteboardSet: Equatable {
    let exercise: String
    let reps: Int
    let weight: Double?
    let rpe: Int?
}

enum AssistantFormatting {
    /// 0 → "A", 25 → "Z", 26 → "AA", 27 → "AB", … (spreadsheet columns).
    static func blockLetter(_ index: Int) -> String {
        var n = index
        var letters = ""
        repeat {
            letters = String(UnicodeScalar(UInt8(65 + n % 26))) + letters
            n = n / 26 - 1
        } while n >= 0
        return letters
    }

    /// Sets (already in order) as they'd be written on a whiteboard: each run of
    /// the same exercise under its name, identical consecutive sets collapsed.
    ///
    ///     Back Squat
    ///       3 × 5 @ 185 lb, RPE 7
    ///       2 × 3 @ 205 lb, RPE 8
    static func whiteboardLines(_ sets: [WhiteboardSet]) -> [String] {
        var lines: [String] = []
        var i = 0
        while i < sets.count {
            let exercise = sets[i].exercise
            lines.append(exercise)
            while i < sets.count, sets[i].exercise == exercise {
                let set = sets[i]
                var count = 0
                while i < sets.count, sets[i] == set {
                    count += 1
                    i += 1
                }
                var line = "  \(count) × \(set.reps)"
                if let weight = set.weight { line += " @ \(weight.formatted()) lb" }
                if let rpe = set.rpe { line += ", RPE \(rpe)" }
                lines.append(line)
            }
        }
        return lines
    }
}

@MainActor
final class AssistantViewModel: ObservableObject {
    @Published private(set) var session: AssistantSession?
    /// Fetching the user's latest session when the page opens.
    @Published private(set) var isLoadingLatest = false
    /// Running the agent for a brand-new session.
    @Published private(set) var isGenerating = false
    @Published private(set) var errorMessage: String?
    /// True once the latest-session lookup has come back, found or not. Lets
    /// the view tell "still looking" apart from "there's nothing yet".
    @Published private(set) var hasLoadedLatest = false

    private let network = Network.shared
    private var generation: Task<Void, Never>?

    init(session: AssistantSession? = nil) {
        self.session = session
        self.hasLoadedLatest = session != nil
    }

    deinit {
        // Unsubscribing stops the agent on the server.
        generation?.cancel()
    }

    /// Opens the subscription socket while the user is still reading the page,
    /// so tapping Generate doesn't wait on the connection handshake.
    func warmUpGeneration() {
        network.connectSubscriptions()
    }

    /// Show the user's newest not-yet-completed session, so the page opens on
    /// their workout rather than blank. Only runs until it has succeeded once.
    func loadLatest() {
        guard !hasLoadedLatest, !isLoadingLatest else { return }
        isLoadingLatest = true
        errorMessage = nil

        network.client.fetch(
            query: CurrentWorkoutQuery(),
            cachePolicy: .fetchIgnoringCacheCompletely
        ) { [weak self] result in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.isLoadingLatest = false
                switch result {
                case .success(let graphQLResult):
                    if let errors = graphQLResult.errors, !errors.isEmpty {
                        let messages = errors.compactMap { $0.message }.joined(separator: "; ")
                        TelemetryService.captureGraphQLErrors(messages: messages, operation: "CurrentWorkout")
                        self.errorMessage = errors.first?.message ?? "Unable to load your latest workout."
                        return
                    }
                    self.hasLoadedLatest = true
                    // A generate that finished first is newer; don't overwrite it.
                    if self.session == nil, let workout = graphQLResult.data?.currentWorkout {
                        self.session = Self.session(from: workout.fragments.sessionDetails)
                    }
                case .failure(let networkError):
                    TelemetryService.captureError(networkError, tags: ["operation": "CurrentWorkout"])
                    self.errorMessage = networkError.localizedDescription
                }
            }
        }
    }

    /// Streams a new session in: the page switches to it when its header
    /// arrives and fills in each block as the agent writes it, then settles on
    /// the saved session. On failure the previous session comes back, since a
    /// half-streamed one was never saved.
    func generate() {
        guard !isGenerating else { return }
        isGenerating = true
        errorMessage = nil
        let previous = session

        generation = Task { [weak self] in
            var progress = GenerationProgress()
            do {
                for try await event in WorkoutGenerationStream().events() {
                    progress.apply(event)
                    guard let self else { return }
                    if let session = progress.session {
                        self.session = session
                    }
                }
                guard let self else { return }
                self.isGenerating = false
            } catch {
                guard let self else { return }
                self.isGenerating = false
                if !progress.isComplete {
                    self.session = previous
                }
                if !(error is CancellationError) {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    /// The current copy of the strength block with session identity `id`.
    func strengthWorkout(id: Int) -> StrengthWorkout? {
        for block in session?.blocks ?? [] {
            if case let .strength(workout) = block.kind, workout.id == id { return workout }
        }
        return nil
    }

    /// Takes a strength block's latest set results (after a save in
    /// StrengthWorkoutView), so reopening the block shows what was logged.
    func updateStrength(_ workout: StrengthWorkout) {
        guard var session,
              let index = session.blocks.firstIndex(where: {
                  if case let .strength(existing) = $0.kind { return existing.id == workout.id }
                  return false
              })
        else { return }
        session.blocks[index].kind = .strength(workout)
        self.session = session
    }

    // MARK: - Mapping

    /// Nonisolated so the generation stream can map the saved session off the
    /// main actor.
    nonisolated static func session(from workout: SessionDetails) -> AssistantSession {
        let blocks = workout.blocks
            .sorted { $0.order < $1.order }
            .enumerated()
            .map { index, block in
                let letter = AssistantFormatting.blockLetter(index)
                
                if let strength = block.asStrengthWorkout {
                    let sets = strength.components
                        .map { StrengthComponent(order: $0.order, reps: $0.reps, weight: $0.weight, rpe: $0.rpe, exercise: ExerciseName(
                            name: $0.exercise.name,
                            muscleGroups: ExerciseName.muscleGroups(fromCatalog: $0.exercise.muscleGroups)
                        ), id: $0.id, completed: completedSet(
                            at: $0.completedAt,
                            reps: $0.completedReps,
                            weight: $0.completedWeight,
                            rpe: $0.completedRpe
                        ))}
                    let strengthWorkout = StrengthWorkout(
                        id: index,
                        name: strength.name ?? "Strength",
                        instructions: strength.instructions,
                        components: sets,
                        serverId: strength.id
                    )
                    return AssistantBlock(
                        id: block.order,
                        label: "\(strength.name ?? "Strength")",
                        letter: letter,
                        kind:.strength(strengthWorkout)
                    )
                }
                if let hiit = block.asWorkoutHiitPiece?.hiitWorkout {
                    let item = HIITWorkoutItem(
                        id: hiit.id,
                        format: hiit.format,
                        displayText: hiit.displayText,
                        stimulus: hiit.stimulus,
                        constraintType: hiit.constraintType,
                        constraintMagnitude: hiit.constraintMagnitude,
                        timeCap: hiit.timeCap,
                        timingScheme: hiit.timingScheme.flatMap { WodTimerConfig(fragment: $0) },
                        tags: []
                    )
                    return AssistantBlock(
                        id: block.order,
                        label: "\(hiit.name ?? "Metcon")",
                        letter: letter,
                        kind: .hiit(item)
                    )
                }
                return AssistantBlock(
                    id: block.order,
                    label: "\(block.__typename)",
                    letter: letter,
                    kind: .other)
            }

        return AssistantSession(
            name: workout.name,
            description: workout.description,
            stimulus: workout.stimulus,
            coaching: workout.coaching,
            scheduledDate: DateParser().parseDate(workout.scheduledDate),
            blocks: blocks
        )
    }

    /// A logged set from the server's completed* fields. completedAt is what
    /// marks a set done; the rest can be null (an unloaded set has no weight).
    nonisolated private static func completedSet(at completedAt: String?, reps: Int?, weight: Double?, rpe: Int?) -> CompletedSet? {
        guard completedAt != nil, let reps else { return nil }
        return CompletedSet(weightUsed: weight, reps: reps, rpe: rpe)
    }

    // MARK: - Preview factory

    static func preview() -> AssistantViewModel {
        AssistantViewModel(session: AssistantSession(
            name: "Lower Body Strength + Engine",
            description: "Heavy squats, then a short aerobic piece.",
            stimulus: "Build lower-body strength, then push the aerobic engine.",
            coaching: nil,
            scheduledDate: Date(),
            blocks: [
                AssistantBlock(
                    id: 0,
                    label: "Back Squat",
                    letter: "A",
                    kind: .strength(StrengthWorkout(id: 0, name: "Back Squats", instructions: "Do back squats at a moderate intensity for building strength.", components: [
                        StrengthComponent(order: 0, reps: 3, weight: nil, rpe: 7, exercise: ExerciseName(name: "Back Squat")),
                        StrengthComponent(order: 0, reps: 3, weight: nil, rpe: 7, exercise: ExerciseName(name: "Back Squat")),
                        StrengthComponent(order: 0, reps: 3, weight: nil, rpe: 7, exercise: ExerciseName(name: "Back Squat"))
                    ]))
                ),
                AssistantBlock(
                    id: 1,
                    label: "Metcon",
                    letter: "B",
                    kind: .hiit(HIITWorkoutItem(
                        id: 1,
                        format: "AMRAP 12",
                        displayText: "12 Cal Row\n9 Burpees\n6 KB Swings (53/35)",
                        stimulus: "Steady, sustainable pace.",
                        constraintType: "time",
                        constraintMagnitude: 720,
                        timeCap: 720,
                        timingScheme: nil,
                        tags: []
                    ))
                ),
            ]
        ))
    }
}
