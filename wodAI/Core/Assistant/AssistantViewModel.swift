//
//  AssistantViewModel.swift
//  wodAI
//
//  Assistant: the current week's sessions, one day at a time, laid out block
//  by block — "Block A - …", "Block B - …" in session order. Strength blocks
//  are written like a whiteboard; HIIT blocks reuse the feed's WOD card and
//  open in `MetconView`.
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
    /// Set once the athlete saves a result for this HIIT block in the
    /// pager. Local only: the session query has no per-piece HIIT
    /// completion, so it resets when the week reloads.
    var hiitCompleted = false

    /// Whether a tap can open this block in the pager (`.other` can't).
    var isOpenable: Bool {
        if case .other = kind { return false }
        return true
    }

    /// True once every component is done. Strength blocks track completion
    /// per set; HIIT blocks once a result is saved; unknown blocks never.
    var isCompleted: Bool {
        switch kind {
        case let .strength(workout): return workout.isCompleted
        case .hiit: return hiitCompleted
        case .other: return false
        }
    }
}

/// Opens the block pager on the block with session identity `blockId`.
struct AssistantBlockRoute: Hashable {
    let blockId: Int
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
    /// This week's sessions, keyed by local start-of-day. Days with nothing
    /// scheduled have no entry.
    @Published private(set) var sessions: [Date: AssistantSession]
    /// The day being shown. Always a day of `week`.
    @Published private(set) var selectedDay: Date
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    /// True once the week has come back, found or not. Lets the view tell
    /// "still looking" apart from "nothing scheduled".
    @Published private(set) var hasLoaded = false

    let week: AssistantWeek
    private let network = Network.shared

    init(week: AssistantWeek = AssistantWeek(), sessions: [Date: AssistantSession] = [:]) {
        self.week = week
        self.sessions = sessions
        self.selectedDay = week.today
        self.hasLoaded = !sessions.isEmpty
    }

    /// Seeds `session` as today's (previews and tests).
    convenience init(session: AssistantSession) {
        let week = AssistantWeek()
        self.init(week: week, sessions: [week.today: session])
    }

    /// The selected day's session, or nil when nothing is scheduled.
    var session: AssistantSession? { sessions[selectedDay] }

    func hasSession(on day: Date) -> Bool { sessions[day] != nil }

    // MARK: - Navigation (clamped to this week)

    var canGoForward: Bool { week.day(after: selectedDay) != nil }
    var canGoBack: Bool { week.day(before: selectedDay) != nil }

    /// Moves one day later. Returns false at the end of the week.
    @discardableResult
    func goForward() -> Bool {
        guard let next = week.day(after: selectedDay) else { return false }
        selectedDay = next
        return true
    }

    /// Moves one day earlier. Returns false at the start of the week.
    @discardableResult
    func goBack() -> Bool {
        guard let previous = week.day(before: selectedDay) else { return false }
        selectedDay = previous
        return true
    }

    func select(_ day: Date) {
        guard week.contains(day) else { return }
        selectedDay = week.calendar.startOfDay(for: day)
    }

    // MARK: - Loading

    /// Fetches every session scheduled this week in one query. Only runs
    /// until it has succeeded once.
    func loadWeek() {
        guard !hasLoaded, !isLoading else { return }
        isLoading = true
        errorMessage = nil

        let week = week
        network.client.fetch(
            query: WeekSessionsQuery(
                startDate: week.serverArgument(for: week.first),
                endDate: week.serverArgument(for: week.last)
            ),
            cachePolicy: .fetchIgnoringCacheCompletely
        ) { [weak self] result in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.isLoading = false
                switch result {
                case .success(let graphQLResult):
                    if let errors = graphQLResult.errors, !errors.isEmpty {
                        let messages = errors.compactMap { $0.message }.joined(separator: "; ")
                        TelemetryService.captureGraphQLErrors(messages: messages, operation: "WeekSessions")
                        self.errorMessage = errors.first?.message ?? "Unable to load this week's workouts."
                        return
                    }
                    var sessions: [Date: AssistantSession] = [:]
                    // Ordered by scheduledDate, so with two on one day the
                    // later one in the list wins.
                    for workout in graphQLResult.data?.getWorkoutsByDateRange ?? [] {
                        let details = workout.fragments.sessionDetails
                        guard let day = week.localDay(fromServer: details.scheduledDate), week.contains(day) else { continue }
                        sessions[day] = Self.session(from: details)
                    }
                    self.sessions = sessions
                    self.hasLoaded = true
                case .failure(let networkError):
                    TelemetryService.captureError(networkError, tags: ["operation": "WeekSessions"])
                    self.errorMessage = networkError.localizedDescription
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

    /// The selected day's blocks that the pager can show, in session order.
    var openableBlocks: [AssistantBlock] {
        session?.blocks.filter(\.isOpenable) ?? []
    }

    /// Marks a HIIT block done after its result is saved in the pager.
    func markHiitCompleted(blockId: Int) {
        let day = selectedDay
        guard var session = sessions[day],
              let index = session.blocks.firstIndex(where: { $0.id == blockId }),
              case .hiit = session.blocks[index].kind
        else { return }
        session.blocks[index].hiitCompleted = true
        sessions[day] = session
    }

    /// Takes a strength block's latest set results (after a save in
    /// StrengthWorkoutView), so reopening the block shows what was logged.
    /// Applies to the selected day: the strength screen is pushed from it,
    /// and swiping is behind that screen.
    func updateStrength(_ workout: StrengthWorkout) {
        let day = selectedDay
        guard var session = sessions[day],
              let index = session.blocks.firstIndex(where: {
                  if case let .strength(existing) = $0.kind { return existing.id == workout.id }
                  return false
              })
        else { return }
        session.blocks[index].kind = .strength(workout)
        sessions[day] = session
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
                        tags: [],
                        name: hiit.name
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
            // The local calendar day, not the raw UTC-midnight instant.
            scheduledDate: AssistantWeek().localDay(fromServer: workout.scheduledDate),
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
                        StrengthComponent(order: 0, reps: 3, weight: nil, rpe: 7, exercise: ExerciseName(name: "Back Squat"), completed: CompletedSet(weightUsed: 225, reps: 3)),
                        StrengthComponent(order: 0, reps: 3, weight: nil, rpe: 7, exercise: ExerciseName(name: "Back Squat"), completed: CompletedSet(weightUsed: 225, reps: 3)),
                        StrengthComponent(order: 0, reps: 3, weight: nil, rpe: 7, exercise: ExerciseName(name: "Back Squat"), completed: CompletedSet(weightUsed: 225, reps: 3))
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
