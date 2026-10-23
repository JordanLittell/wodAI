//
//  AssistantViewModel.swift
//  wodAI
//
//  Assistant: a week's sessions, one day at a time, starting on this week
//  and swiping back or forward through any other. A day can hold
//  several sessions (the programmed one plus any whiteboard imports), each
//  laid out block by block — "Block A - …", "Block B - …" in session order.
//  Strength blocks are written like a whiteboard; HIIT blocks reuse the feed's
//  WOD card and open in `MetconView`.
//

import Foundation
import WodAiAPI

/// How a session got onto the calendar; labels its section.
enum SessionSource: Equatable {
    case generated
    case planned
    case imported
    case whiteboard
    /// From the athlete's own request ("Create with AI").
    case created

    init(_ value: GraphQLEnum<WorkoutSource>) {
        switch value.value {
        case .planned: self = .planned
        case .imported: self = .imported
        case .whiteboard: self = .whiteboard
        case .created: self = .created
        // Generated, or a source this build doesn't know.
        default: self = .generated
        }
    }

    var label: String {
        switch self {
        case .generated, .planned: return "Programmed"
        case .imported: return "Imported"
        case .whiteboard: return "Whiteboard"
        case .created: return "Created"
        }
    }

    var systemImage: String {
        switch self {
        case .generated, .planned: return "sparkles"
        case .imported: return "square.and.arrow.down"
        case .whiteboard: return "camera.viewfinder"
        case .created: return "wand.and.stars"
        }
    }
}

struct AssistantSession: Identifiable {
    /// The server's Workout id. A whiteboard import still being read has a
    /// temporary "pending-…" id until the saved session replaces it.
    var id: String = UUID().uuidString
    let name: String
    let description: String
    let stimulus: String?
    let coaching: String?
    /// The day the session is programmed for; nil if the server's value didn't parse.
    let scheduledDate: Date?
    var blocks: [AssistantBlock]
    var source: SessionSource = .generated
    /// A rest day's light activity, which the athlete may skip.
    var isOptional = false
    /// True while the session streams in. Its blocks aren't saved yet, so
    /// they can't be opened.
    var isPending = false

    /// True once every block that can be opened is done.
    var isCompleted: Bool {
        let openable = blocks.filter(\.isOpenable)
        return !openable.isEmpty && openable.allSatisfy(\.isCompleted)
    }
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
    /// The session's WorkoutHiitPiece id for a HIIT block, sent with the
    /// result so the server records which piece it completes.
    var hiitPieceId: Int? = nil
    /// Whether this HIIT block has a result. Loaded from the piece's
    /// `completion`, and set locally the moment a result is saved in the pager
    /// so the block turns done before the next reload.
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

/// Opens the block pager on block `blockId` of session `sessionId`.
struct AssistantBlockRoute: Hashable {
    let sessionId: String
    let blockId: Int
}

/// A whiteboard photo ready to send: JPEG bytes plus what on-device text
/// recognition read, which the server uses as a hint.
struct WhiteboardCapture {
    let jpeg: Data
    let recognizedText: String
}

/// A session being added to a day by streaming it from the server.
enum NewSession: Equatable {
    case whiteboard
    /// "Create with AI", with what the athlete asked for.
    case created(request: String)

    /// What the section shows before the server sends the session's name.
    var placeholderName: String {
        switch self {
        case .whiteboard: return "Reading whiteboard…"
        case .created: return "Creating your session…"
        }
    }

    var source: SessionSource {
        switch self {
        case .whiteboard: return .whiteboard
        case .created: return .created
        }
    }

    var stoppedEarlyMessage: String {
        switch self {
        case .whiteboard: return "The whiteboard import stopped early. Please try again."
        case .created: return "Creating your session stopped early. Please try again."
        }
    }
}

enum SessionDeletion {
    /// The confirmation's message: a stronger warning when the session holds
    /// logged work, since deleting it deletes those sets.
    static func message(for session: AssistantSession) -> String {
        let hasLoggedWork = session.blocks.contains { block in
            switch block.kind {
            case let .strength(workout): return workout.components.contains { $0.completed != nil }
            case .hiit: return block.hiitCompleted
            case .other: return false
            }
        }
        return hasLoggedWork
            ? "Sets you logged in it will be deleted too. Results you saved for its metcons stay in your history."
            : "This can't be undone."
    }
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
/// The banner shown while the server plans the rest of the week.
enum PlanningNotice: Equatable {
    case planning
    case failed(String)
}

final class AssistantViewModel: ObservableObject {
    /// Every loaded week's sessions, keyed by local start-of-day, in the
    /// order the server lists them (imports added later go last). Days with
    /// nothing scheduled have no entry. Weeks stay here once loaded, so
    /// swiping back to one shows it at once.
    @Published private(set) var sessions: [Date: [AssistantSession]]
    /// The day being shown. Always a day of `week`.
    @Published private(set) var selectedDay: Date {
        // Changing days hides any Delete button left showing.
        didSet { revealedSessionId = nil }
    }
    /// The week being shown.
    @Published private(set) var week: AssistantWeek
    /// Weeks (by first day) that have come back once, and weeks with a
    /// spinner-showing fetch under way.
    @Published private var loadedWeeks: Set<Date> = []
    @Published private var loadingWeeks: Set<Date> = []
    /// True while the shown week is first loading.
    var isLoading: Bool { loadingWeeks.contains(week.first) }
    @Published private(set) var errorMessage: String?
    /// True once the shown week has come back, found or not. Lets the view
    /// tell "still looking" apart from "nothing scheduled".
    var hasLoaded: Bool { loadedWeeks.contains(week.first) }
    /// True while a new session (whiteboard import or "Create with AI")
    /// streams in. One at a time.
    @Published private(set) var isAddingSession = false
    /// Why the last new session failed, until the next one starts.
    @Published private(set) var addError: String?
    /// What failed last, so "Try again" can reopen it (with the request, for
    /// "Create with AI"). Nil after a cancel or a success.
    @Published private(set) var lastFailedAdd: NewSession?
    /// A session the page should scroll to (a new one streaming in).
    @Published private(set) var focusedSessionId: String?
    /// The session whose Delete button is showing; at most one at a time.
    @Published private(set) var revealedSessionId: String?
    /// Shown while the server is still planning this athlete's week (right
    /// after onboarding), or briefly if that planning failed.
    @Published private(set) var planningNotice: PlanningNotice? {
        didSet { if planningNotice == nil { replanDays = nil } }
    }
    /// The days a re-plan from the trainer chat is programming, while it runs.
    /// Only these can show as being built; nil for a full week's planning.
    private var replanDays: Set<Date>?
    /// Sections the athlete opened or closed, by session id. Others follow
    /// `isExpanded`'s defaults.
    @Published private var expansion: [String: Bool] = [:]

    /// The week containing today, which planning fills in.
    let currentWeek: AssistantWeek
    // Server calls, swapped out in tests.
    /// Every session scheduled in a week.
    var weekSessions: (AssistantWeek) async throws -> [AssistantSession] = AssistantViewModel.fetchSessions
    /// Starts a whiteboard import on the server.
    var whiteboardEvents: (WhiteboardImportInput) -> AsyncThrowingStream<GenerationEvent, Error> = {
        // Reading the photo comes before the first event, so allow longer.
        WorkoutGenerationStream(stallTimeout: 90).whiteboardEvents($0)
    }
    /// Starts generating a session from a request, saved on the given day.
    var createEvents: (_ request: String, _ scheduledDate: String) -> AsyncThrowingStream<GenerationEvent, Error> = {
        // Writing to a request can take longer before the first event.
        WorkoutGenerationStream(stallTimeout: 90).events(request: $0, scheduledDate: $1)
    }
    /// Starts re-planning the picked days on the server (Program My Week).
    var replanWeek: (_ dates: [String], _ request: String?, _ replaceWorkoutIds: [String]?) async throws -> Void = AssistantViewModel.performReplan
    /// Deletes a session on the server.
    var deleteWorkout: (_ id: String) async throws -> Void = AssistantViewModel.performDelete
    /// The latest background planning run; nil when there's never been one.
    var planStatus: () async throws -> PlanStatus? = { try await ApolloOnboardingAPI().planStatus() }
    /// How often to check on a run that's still planning.
    var planPollInterval: Duration = .seconds(5)
    /// Work in a session was saved on the server (a set logged, a metcon's
    /// result). Saves or updates its workout in Apple Health.
    var sessionProgressed: (_ id: String, _ completed: Bool) -> Void = { id, completed in
        Task { @MainActor in HealthSync.shared.sessionProgressed(id: id, completed: completed) }
    }
    /// Refetches the week as planning lands days; `then` runs once it's back.
    lazy var refetchWeek: (_ then: @escaping () -> Void) -> Void = { [weak self] then in
        guard let self else { return then() }
        self.reloadWeek(then: then)
    }
    /// Only touched on the main actor, except to cancel it in `deinit`.
    nonisolated(unsafe) private var planTask: Task<Void, Never>?
    /// A reload that had to wait for a new session to finish streaming in.
    private var reloadAfterAdding = false
    /// Only touched on the main actor, except to cancel it in `deinit`.
    nonisolated(unsafe) private var importTask: Task<Void, Never>?
    /// The id of the session streaming in (the placeholder's, then the saved
    /// one's), so a week fetch that was already under way keeps it.
    private var addingSessionId: String?

    /// Starts on `week`'s today, which should be in it.
    init(week: AssistantWeek = AssistantWeek(), sessions: [Date: [AssistantSession]] = [:]) {
        self.week = week
        self.currentWeek = week
        self.sessions = sessions
        self.selectedDay = week.today
        if !sessions.isEmpty { loadedWeeks = [week.first] }
    }

    /// Leaving the page stops a new session streaming in, which unsubscribes
    /// and stops the server.
    deinit {
        importTask?.cancel()
        planTask?.cancel()
    }

    /// Seeds `session` as today's (previews and tests).
    convenience init(session: AssistantSession) {
        let week = AssistantWeek()
        self.init(week: week, sessions: [week.today: [session]])
    }

    /// The selected day's sessions; empty when nothing is scheduled.
    var daySessions: [AssistantSession] { sessions[selectedDay] ?? [] }

    /// True for an empty day from today on while the server is still planning
    /// the week. The planner picks its own rest days, so which days stay empty
    /// is only known once it finishes; until then every one may be coming.
    func isGenerating(_ day: Date) -> Bool {
        let day = week.calendar.startOfDay(for: day)
        if let replanDays, !replanDays.contains(day) { return false }
        return planningNotice == .planning
            && currentWeek.contains(day)
            && day >= currentWeek.today
            && (sessions[day] ?? []).isEmpty
    }

    /// The selected day's session with this id.
    func session(id: String) -> AssistantSession? {
        daySessions.first { $0.id == id }
    }

    func hasSession(on day: Date) -> Bool { !(sessions[day]?.isEmpty ?? true) }

    // MARK: - Expand / collapse

    /// Whether a session's section shows its blocks. Until the athlete
    /// toggles it: a day's only session is open; with several, the first one
    /// not yet completed is open and the rest are closed, so the day reads as
    /// a short list.
    func isExpanded(_ session: AssistantSession) -> Bool {
        if let chosen = expansion[session.id] { return chosen }
        // A rest day's light activity stays closed until the athlete wants it.
        if session.isOptional { return false }
        let day = daySessions
        guard day.count > 1 else { return true }
        return day.first(where: { !$0.isCompleted })?.id == session.id
    }

    func toggleExpanded(_ session: AssistantSession) {
        expansion[session.id] = !isExpanded(session)
    }

    /// Closes a session's section, e.g. once its last block is finished.
    func collapse(sessionId: String) {
        expansion[sessionId] = false
    }

    /// Opens one session on `day` and closes the rest.
    private func expandOnly(_ id: String, on day: Date) {
        for session in sessions[day] ?? [] {
            expansion[session.id] = session.id == id
        }
        expansion[id] = true
    }

    // MARK: - Navigation

    /// Moves one day later, into the next week after the last day.
    func goForward() {
        show(week.day(after: selectedDay) ?? week.shifted(by: 1).first)
    }

    /// Moves one day earlier, into the previous week before the first day.
    func goBack() {
        show(week.day(before: selectedDay) ?? week.shifted(by: -1).last)
    }

    /// Moves `offset` weeks, to the same day of the week.
    func showWeek(offset: Int) {
        let other = week.shifted(by: offset)
        show(other.days[week.index(of: selectedDay) ?? 0])
    }

    /// Back to today, in this week.
    func showToday() {
        show(currentWeek.today)
    }

    /// Shows any day, moving to its week if it's in another.
    func select(_ day: Date) {
        show(week.calendar.startOfDay(for: day))
    }

    private func show(_ day: Date) {
        let other = week.week(containing: day)
        if other != week {
            week = other
            // An error belongs to the week that failed to load.
            errorMessage = nil
            loadIfNeeded(other)
        }
        selectedDay = day
    }

    // MARK: - Loading

    /// Fetches every session scheduled in the shown week in one query, and
    /// watches planning. Only fetches until the week has loaded once.
    func loadWeek() {
        if !hasLoaded { fetchWeek(week, quietly: false) }
        watchPlanning()
    }

    /// A week's first visit fetches it with a spinner; a later one refreshes
    /// it quietly, since its sessions may have changed (a result edited in
    /// Activity, a day planned).
    private func loadIfNeeded(_ week: AssistantWeek) {
        guard !loadingWeeks.contains(week.first) else { return }
        if loadedWeeks.contains(week.first) {
            reloadWeek(week)
        } else {
            fetchWeek(week, quietly: false)
        }
    }

    /// Fetches a week (by default this one) again without a spinner,
    /// keeping the selected day. Waits while a new session streams in, since
    /// the fetch replaces the week's sessions. `then` runs once the fetch is
    /// back (or at once, if it had to wait).
    func reloadWeek(_ week: AssistantWeek? = nil, then: (() -> Void)? = nil) {
        guard importTask == nil else {
            reloadAfterAdding = true
            then?()
            return
        }
        fetchWeek(week ?? currentWeek, quietly: true, then: then)
    }

    /// `quietly`: a background refresh, which shows no spinner and no error.
    /// `then` runs on the main actor when the fetch is back, whatever it found.
    /// Replaces only `week`'s days, so a late answer can't touch another week.
    private func fetchWeek(_ week: AssistantWeek, quietly: Bool, then: (() -> Void)? = nil) {
        if !quietly {
            loadingWeeks.insert(week.first)
            if week == self.week { errorMessage = nil }
        }
        Task { @MainActor [weak self, weekSessions] in
            defer { then?() }
            let found: [AssistantSession]
            do {
                found = try await weekSessions(week)
            } catch {
                guard let self else { return }
                if !quietly {
                    self.loadingWeeks.remove(week.first)
                    if week == self.week { self.errorMessage = error.localizedDescription }
                }
                return
            }
            guard let self else { return }
            if !quietly { self.loadingWeeks.remove(week.first) }
            var sessions = self.sessions.filter { !week.contains($0.key) }
            for session in found {
                guard let date = session.scheduledDate, week.contains(date) else { continue }
                sessions[week.calendar.startOfDay(for: date), default: []].append(session)
            }
            // A fetch begun before a new session started streaming in doesn't
            // have it; keep it, or later events have nothing to replace.
            if let addingId = self.addingSessionId, !found.contains(where: { $0.id == addingId }) {
                for (day, list) in self.sessions where week.contains(day) {
                    if let adding = list.first(where: { $0.id == addingId }) {
                        sessions[day, default: []].append(adding)
                    }
                }
            }
            self.sessions = sessions
            self.loadedWeeks.insert(week.first)
        }
    }

    private static func fetchSessions(in week: AssistantWeek) async throws -> [AssistantSession] {
        try await withCheckedThrowingContinuation { continuation in
            Network.shared.client.fetch(
                query: WeekSessionsQuery(
                    startDate: week.serverArgument(for: week.first),
                    endDate: week.serverArgument(for: week.last)
                ),
                cachePolicy: .fetchIgnoringCacheCompletely
            ) { result in
                switch result {
                case let .success(graphQLResult):
                    if let errors = graphQLResult.errors, !errors.isEmpty {
                        let messages = errors.compactMap { $0.message }.joined(separator: "; ")
                        TelemetryService.captureGraphQLErrors(messages: messages, operation: "WeekSessions")
                        continuation.resume(throwing: WorkoutGenerationError.server(errors.first?.message ?? "Unable to load this week's workouts."))
                        return
                    }
                    let sessions = (graphQLResult.data?.getWorkoutsByDateRange ?? []).map {
                        Self.session(from: $0.fragments.sessionDetails)
                    }
                    continuation.resume(returning: sessions)
                case let .failure(error):
                    TelemetryService.captureError(error, tags: ["operation": "WeekSessions"])
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// The current copy of strength block `id` in session `sessionId`.
    func strengthWorkout(sessionId: String, id: Int) -> StrengthWorkout? {
        for block in session(id: sessionId)?.blocks ?? [] {
            if case let .strength(workout) = block.kind, workout.id == id { return workout }
        }
        return nil
    }

    /// A session's blocks that the pager can show, in session order. None
    /// while the session is still streaming in.
    func openableBlocks(in sessionId: String) -> [AssistantBlock] {
        guard let session = session(id: sessionId), !session.isPending else { return [] }
        return session.blocks.filter(\.isOpenable)
    }

    /// Marks a HIIT block done after its result is saved in the pager.
    func markHiitCompleted(sessionId: String, blockId: Int) {
        updateSession(sessionId) { session in
            guard let index = session.blocks.firstIndex(where: { $0.id == blockId }),
                  case .hiit = session.blocks[index].kind
            else { return }
            session.blocks[index].hiitCompleted = true
        }
    }

    /// Takes a strength block's latest set results (after a save in
    /// StrengthWorkoutView), so reopening the block shows what was logged.
    /// Applies to the selected day: the strength screen is pushed from it,
    /// and swiping is behind that screen.
    func updateStrength(_ workout: StrengthWorkout, sessionId: String) {
        updateSession(sessionId) { session in
            guard let index = session.blocks.firstIndex(where: {
                if case let .strength(existing) = $0.kind { return existing.id == workout.id }
                return false
            }) else { return }
            session.blocks[index].kind = .strength(workout)
        }
    }

    /// Edits the selected day's session with this id in place, and reports
    /// the progress. Callers run after the server saved the work.
    private func updateSession(_ id: String, _ change: (inout AssistantSession) -> Void) {
        let day = selectedDay
        guard var list = sessions[day], let index = list.firstIndex(where: { $0.id == id }) else { return }
        change(&list[index])
        sessions[day] = list
        sessionProgressed(id, list[index].isCompleted)
    }

    // MARK: - Adding a session

    /// Reads a whiteboard photo into a new session on the selected day.
    func importWhiteboard(_ capture: WhiteboardCapture) {
        let day = selectedDay
        let text = capture.recognizedText.trimmingCharacters(in: .whitespacesAndNewlines)
        let input = WhiteboardImportInput(
            imageJpegBase64: capture.jpeg.base64EncodedString(),
            recognizedText: text.isEmpty ? nil : .some(text),
            scheduledDate: week.calendarDate(for: day)
        )
        streamNewSession(.whiteboard, on: day) { [whiteboardEvents] in whiteboardEvents(input) }
    }

    /// Generates a session from what the athlete asked for, on the selected day.
    func createSession(request: String) {
        let request = request.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !request.isEmpty else { return }
        let day = selectedDay
        let date = week.calendarDate(for: day)
        streamNewSession(.created(request: request), on: day) { [createEvents] in createEvents(request, date) }
    }

    /// Adds a session to `day` as the server streams it. It appears at once
    /// as a placeholder, fills in block by block, then becomes the saved
    /// session. On failure the placeholder goes away and `addError` says why.
    private func streamNewSession(
        _ kind: NewSession,
        on day: Date,
        start: () -> AsyncThrowingStream<GenerationEvent, Error>
    ) {
        guard importTask == nil else { return }
        let pendingId = "pending-\(UUID().uuidString)"

        addError = nil
        lastFailedAdd = nil
        isAddingSession = true
        revealedSessionId = nil
        sessions[day, default: []].append(Self.pendingSession(id: pendingId, kind: kind, day: day))
        expandOnly(pendingId, on: day)
        focusedSessionId = pendingId
        addingSessionId = pendingId
        let events = start()

        importTask = Task { [weak self] in
            // The session's id: the placeholder's, then the saved one's.
            var currentId = pendingId
            var progress = GenerationProgress(scheduledDate: day)
            do {
                for try await event in events {
                    progress.apply(event)
                    guard let self, var session = progress.session else { continue }
                    session.source = kind.source
                    if !progress.isComplete {
                        session.id = currentId
                        session.isPending = true
                    }
                    self.replaceSession(currentId, with: session, on: day)
                    currentId = session.id
                    self.addingSessionId = session.id
                }
                guard let self else { return }
                if !progress.isComplete {
                    // A cancelled task ends the loop rather than throwing.
                    self.failNewSession(currentId, kind, on: day, message: Task.isCancelled ? nil : kind.stoppedEarlyMessage)
                }
            } catch {
                guard let self else { return }
                // Cancelled means the page went away; nothing to tell anyone.
                self.failNewSession(currentId, kind, on: day, message: error is CancellationError ? nil : error.localizedDescription)
            }
            self?.isAddingSession = false
            self?.addingSessionId = nil
            self?.importTask = nil
            if let self, self.reloadAfterAdding {
                self.reloadAfterAdding = false
                self.reloadWeek()
                if self.week != self.currentWeek { self.reloadWeek(self.week) }
            }
        }
    }

    // MARK: - Planning still under way

    /// Right after onboarding the server is still planning the rest of the
    /// week. While it is, show a notice, mark the empty days still to come as
    /// generating (`isGenerating`), and reload whenever another day lands.
    /// Does nothing for an athlete whose planning finished long ago.
    func watchPlanning() {
        guard planTask == nil else { return }
        planTask = Task { [weak self] in
            var known: Set<String>?
            while !Task.isCancelled {
                guard let self else { return }
                guard let status = try? await self.planStatus() else {
                    self.planningNotice = nil
                    break
                }
                if let known, status.plannedDates != known { self.refetchWeek {} }
                known = status.plannedDates
                switch status.state {
                case .running:
                    self.planningNotice = .planning
                    let interval = self.planPollInterval
                    try? await Task.sleep(for: interval)
                    continue
                case .done:
                    if self.planningNotice == .planning {
                        // Clear the generating cards only once the last days
                        // are fetched, so none reads "No workout scheduled"
                        // in between.
                        self.refetchWeek { [weak self] in self?.planningNotice = nil }
                    } else {
                        self.planningNotice = nil
                    }
                case .failed:
                    // Only worth saying if this run was the one just watched.
                    if self.planningNotice != nil {
                        // Show whatever was saved before it failed.
                        self.refetchWeek {}
                        self.planningNotice = .failed(status.message ?? "We couldn't plan the rest of your week.")
                        try? await Task.sleep(for: .seconds(6))
                        self.planningNotice = nil
                    }
                }
                break
            }
            self?.planTask = nil
        }
    }

    /// Re-plans the days picked in the trainer chat (Program My Week) in the
    /// background, then watches the run as after onboarding: the banner,
    /// "Building this session…" on picked days left empty, and a reload as
    /// each day lands. The server replaces each day's old sessions once its
    /// new one is saved. `replaceWorkoutIds` goes through as is (nil: the
    /// server's default; []: none).
    func replan(dates: [String], request: String?, replaceWorkoutIds: [String]?) {
        replanDays = Set(dates.compactMap(localDay))
        planningNotice = .planning
        Task { [weak self, replanWeek] in
            do {
                try await replanWeek(dates, request, replaceWorkoutIds)
                self?.watchPlanning()
            } catch {
                guard let self else { return }
                self.planningNotice = .failed("We couldn't start planning those days. Please try again.")
                try? await Task.sleep(for: .seconds(6))
                if case .failed = self.planningNotice { self.planningNotice = nil }
            }
        }
    }

    /// Generates a session from what the athlete asked the trainer for, on
    /// today, whichever day is showing.
    func createSessionToday(request: String) {
        showToday()
        createSession(request: request)
    }

    /// "YYYY-MM-DD" as that local day.
    private func localDay(_ date: String) -> Date? {
        let parts = date.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        return currentWeek.calendar.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2]))
    }

    /// Stops a new session streaming in; its placeholder is removed.
    func cancelNewSession() {
        importTask?.cancel()
    }

    func dismissAddError() {
        addError = nil
        lastFailedAdd = nil
    }

    // MARK: - Deleting a session

    /// Shows one session's Delete button (hiding any other), or hides it
    /// with nil. A session still streaming in has none.
    func reveal(_ id: String?) {
        if let id, session(id: id)?.isPending ?? true { return }
        revealedSessionId = id
    }

    /// Deletes a session from the selected day. It goes at once; if the
    /// server refuses, it comes back where it was and `errorMessage` says so.
    func deleteSession(id: String) {
        let day = selectedDay
        guard var list = sessions[day],
              let index = list.firstIndex(where: { $0.id == id }),
              !list[index].isPending
        else { return }

        let removed = list.remove(at: index)
        sessions[day] = list.isEmpty ? nil : list
        let wasExpanded = expansion.removeValue(forKey: id)
        if revealedSessionId == id { revealedSessionId = nil }
        errorMessage = nil

        Task { [weak self, deleteWorkout] in
            do {
                try await deleteWorkout(id)
            } catch {
                guard let self else { return }
                TelemetryService.captureError(error, tags: ["operation": "DeleteWorkout"])
                var restored = self.sessions[day] ?? []
                restored.insert(removed, at: min(index, restored.count))
                self.sessions[day] = restored
                self.expansion[id] = wasExpanded
                self.errorMessage = "Couldn't delete that session. Please try again."
            }
        }
    }

    private static func performReplan(dates: [String], request: String?, replaceWorkoutIds: [String]?) async throws {
        let mutation = ReplanWeekMutation(
            timezone: TimeZone.current.identifier,
            dates: .some(dates),
            request: request.map { .some($0) } ?? .none,
            replaceWorkoutIds: replaceWorkoutIds.map { .some($0) } ?? .none
        )
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            Network.shared.client.perform(mutation: mutation) { result in
                switch result {
                case let .success(graphQLResult):
                    if let errors = graphQLResult.errors, !errors.isEmpty {
                        let messages = errors.compactMap(\.message).joined(separator: "; ")
                        TelemetryService.captureGraphQLErrors(messages: messages, operation: "ReplanWeek")
                        continuation.resume(throwing: WorkoutGenerationError.server(errors.first?.message ?? "Couldn't plan those days."))
                    } else {
                        continuation.resume()
                    }
                case let .failure(error):
                    TelemetryService.captureError(error, tags: ["operation": "ReplanWeek"])
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private static func performDelete(_ id: String) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            Network.shared.client.perform(mutation: DeleteWorkoutMutation(id: id)) { result in
                switch result {
                case let .success(graphQLResult):
                    if let errors = graphQLResult.errors, !errors.isEmpty {
                        let messages = errors.compactMap(\.message).joined(separator: "; ")
                        TelemetryService.captureGraphQLErrors(messages: messages, operation: "DeleteWorkout")
                        continuation.resume(throwing: WorkoutGenerationError.server(errors.first?.message ?? "Couldn't delete that session."))
                    } else {
                        continuation.resume()
                    }
                case let .failure(error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Swaps session `id` on `day` for `session`, keeping its place and
    /// whether it's open (the saved session arrives with a new id).
    private func replaceSession(_ id: String, with session: AssistantSession, on day: Date) {
        guard var list = sessions[day], let index = list.firstIndex(where: { $0.id == id }) else { return }
        list[index] = session
        sessions[day] = list
        if session.id != id {
            expansion[session.id] = expansion.removeValue(forKey: id)
            if focusedSessionId == id { focusedSessionId = session.id }
        }
    }

    private func failNewSession(_ id: String, _ kind: NewSession, on day: Date, message: String?) {
        sessions[day]?.removeAll { $0.id == id && $0.isPending }
        if sessions[day]?.isEmpty == true { sessions[day] = nil }
        expansion[id] = nil
        if focusedSessionId == id { focusedSessionId = nil }
        addError = message
        lastFailedAdd = message == nil ? nil : kind
    }

    /// What shows before the server has sent the session's name.
    private static func pendingSession(id: String, kind: NewSession, day: Date) -> AssistantSession {
        AssistantSession(
            id: id,
            name: kind.placeholderName,
            description: "",
            stimulus: nil,
            coaching: nil,
            scheduledDate: day,
            blocks: [],
            source: kind.source,
            isPending: true
        )
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
                            muscleGroups: ExerciseName.muscleGroups(fromCatalog: $0.exercise.muscleGroups),
                            videoURL: $0.exercise.videoUrl.flatMap(URL.init(string:))
                        ), id: $0.id, completed: CompletedSet(
                            completedAt: $0.completedAt,
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
                if let piece = block.asWorkoutHiitPiece {
                    let hiit = piece.hiitWorkout
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
                        name: hiit.name,
                        pieceStimulus: piece.pieceStimulus
                    )
                    return AssistantBlock(
                        id: block.order,
                        label: "\(hiit.name ?? "Metcon")",
                        letter: letter,
                        kind: .hiit(item),
                        hiitPieceId: piece.id,
                        hiitCompleted: piece.completion != nil
                    )
                }
                return AssistantBlock(
                    id: block.order,
                    label: "\(block.__typename)",
                    letter: letter,
                    kind: .other)
            }

        return AssistantSession(
            id: workout.id,
            name: workout.name,
            description: workout.description,
            stimulus: workout.stimulus,
            coaching: workout.coaching,
            // The local calendar day, not the raw UTC-midnight instant.
            scheduledDate: AssistantWeek().localDay(fromServer: workout.scheduledDate),
            blocks: blocks,
            source: SessionSource(workout.source),
            isOptional: workout.optional
        )
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
