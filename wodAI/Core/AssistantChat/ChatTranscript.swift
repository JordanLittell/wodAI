//
//  ChatTranscript.swift
//  wodAI
//
//  The trainer chat as the athlete sees it, and the rules for what they can
//  tap or send when. Apollo-free: the view model maps the backend's
//  assistantGreeting / assistantTurn into these types.
//

import Foundation

/// An option under a trainer message (the backend's `AssistantSuggestion`).
struct ChatSuggestion: Identifiable, Equatable {
    enum Action: Equatable {
        /// Post the label as the athlete's message.
        case reply
        case openWhiteboardScanner
        /// Stopgap: today's Create with AI sheet, until Write Workout for
        /// Today runs in the chat.
        case openCreateSheet
        /// Program My Week: pick any of these days ("YYYY-MM-DD"); the picked
        /// ones go back as the athlete's message.
        case pickDays([String])
        /// One this version of the app doesn't know. Never shown, so the
        /// server can add actions without breaking released apps.
        case unsupported(String)

        init(serverValue: String, payload: String? = nil) {
            switch serverValue {
            case "REPLY": self = .reply
            case "OPEN_WHITEBOARD_SCANNER": self = .openWhiteboardScanner
            case "OPEN_CREATE_SHEET": self = .openCreateSheet
            case "PICK_DAYS":
                // `{"dates": [...]}`; a picker with nothing to pick is hidden.
                struct Days: Decodable { let dates: [String] }
                let days = payload.flatMap { try? JSONDecoder().decode(Days.self, from: Data($0.utf8)) }
                if let dates = days?.dates, !dates.isEmpty {
                    self = .pickDays(dates)
                } else {
                    self = .unsupported(serverValue)
                }
            default: self = .unsupported(serverValue)
            }
        }
    }

    /// The flow it starts ("whiteboard", "program_week", …); sent back with
    /// each turn.
    let id: String
    let label: String
    let action: Action
    var payload: String? = nil

    var isSupported: Bool {
        if case .unsupported = action { return false }
        return true
    }

    /// The days a day picker offers; nil for any other suggestion.
    var pickableDates: [String]? {
        if case let .pickDays(dates) = action { return dates }
        return nil
    }
}

struct ChatMessage: Identifiable, Equatable {
    enum Author: Equatable { case trainer, athlete }

    let id: UUID
    let author: Author
    var text: String
    /// Only supported suggestions are kept.
    var suggestions: [ChatSuggestion] = []
    /// Set once one of `suggestions` is used, or the athlete answers another
    /// way: they stay on screen but can't be tapped again.
    var answered = false
    /// A trainer message that is an error; the view offers Retry.
    var isError = false

    init(id: UUID = UUID(), author: Author, text: String, suggestions: [ChatSuggestion] = []) {
        self.id = id
        self.author = author
        self.text = text
        self.suggestions = suggestions.filter(\.isSupported)
    }
}

struct ChatTranscript: Equatable {
    private(set) var messages: [ChatMessage]
    /// The option the athlete started from, sent with each turn.
    private(set) var flow: String?
    /// While the trainer is answering nothing can be tapped or sent.
    private(set) var isAwaitingTrainer = false

    init(greeting: String, suggestions: [ChatSuggestion]) {
        messages = [ChatMessage(author: .trainer, text: greeting, suggestions: suggestions)]
    }

    /// Shown at once when the chat opens, before the server's greeting
    /// arrives (or if it never does). Mirrors the backend's default.
    static func bundled(firstName: String?) -> ChatTranscript {
        ChatTranscript(greeting: greetingText(firstName: firstName), suggestions: [
            ChatSuggestion(id: "whiteboard", label: "Import Workout From Whiteboard", action: .openWhiteboardScanner),
            ChatSuggestion(id: "create_with_ai", label: "Create with AI", action: .openCreateSheet),
        ])
    }

    /// "Hey Jordan, how can I help you today?", or no name when there's none
    /// (Apple sign-ins can store an empty string).
    static func greetingText(firstName: String?) -> String {
        let name = firstName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return name.isEmpty ? "Hey, how can I help you today?" : "Hey \(name), how can I help you today?"
    }

    /// Swaps in the server's greeting, unless the athlete has already started.
    mutating func replaceGreeting(text: String, suggestions: [ChatSuggestion]) {
        guard messages.count == 1, !messages[0].answered else { return }
        messages[0] = ChatMessage(id: messages[0].id, author: .trainer, text: text, suggestions: suggestions)
    }

    // MARK: Athlete

    /// The suggestions the athlete can tap now: the last message's, if it's
    /// the trainer's and not yet answered.
    var tappableSuggestions: [ChatSuggestion] {
        guard !isAwaitingTrainer, let last = messages.last, last.author == .trainer, !last.answered else { return [] }
        return last.suggestions
    }

    var canSend: Bool { !isAwaitingTrainer }

    /// Taps a suggestion. Returns it when the tap counts, so the caller runs
    /// its action; nil when it doesn't (an older turn's, or a second tap).
    /// A reply is posted as the athlete's message.
    @discardableResult
    mutating func tap(_ suggestionID: String) -> ChatSuggestion? {
        guard let suggestion = tappableSuggestions.first(where: { $0.id == suggestionID }) else { return nil }
        markLastAnswered()
        if flow == nil, messages.count == 1 { flow = suggestion.id }
        if suggestion.action == .reply {
            messages.append(ChatMessage(author: .athlete, text: suggestion.label))
            isAwaitingTrainer = true
        }
        return suggestion
    }

    /// Sends what the athlete typed. False when there's nothing to send or
    /// the trainer is still answering.
    @discardableResult
    mutating func send(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard canSend, !trimmed.isEmpty else { return false }
        markLastAnswered()
        messages.append(ChatMessage(author: .athlete, text: trimmed))
        isAwaitingTrainer = true
        return true
    }

    // MARK: Trainer

    /// The next piece of the trainer's reply, started on the first piece.
    mutating func appendTrainerText(_ delta: String) {
        guard isAwaitingTrainer else { return }
        if let last = messages.indices.last, messages[last].author == .trainer, !messages[last].isError {
            messages[last].text += delta
        } else {
            messages.append(ChatMessage(author: .trainer, text: delta))
        }
    }

    mutating func setTrainerSuggestions(_ suggestions: [ChatSuggestion]) {
        guard isAwaitingTrainer else { return }
        if messages.last?.author != .trainer { appendTrainerText("") }
        messages[messages.count - 1].suggestions = suggestions.filter(\.isSupported)
    }

    /// Ends the turn. `text` is the whole reply as the server saw it; when
    /// given it replaces what was streamed, so a delta lost or repeated on a
    /// reconnect doesn't stay on screen.
    mutating func finishTrainerReply(text: String? = nil) {
        guard isAwaitingTrainer else { return }
        if let text, !text.isEmpty {
            // While awaiting, a trainer message last is this turn's reply.
            if let last = messages.indices.last, messages[last].author == .trainer {
                messages[last].text = text
            } else {
                appendTrainerText(text)
            }
        }
        isAwaitingTrainer = false
    }

    /// Ends the turn with an error message from the trainer. A reply that was
    /// partly streamed stays.
    mutating func failTrainerReply(_ message: String) {
        guard isAwaitingTrainer else { return }
        var error = ChatMessage(author: .trainer, text: message)
        error.isError = true
        messages.append(error)
        isAwaitingTrainer = false
    }

    /// Asks again after an error: the error message goes, and the athlete's
    /// last message is sent again. False when the last message isn't an error.
    @discardableResult
    mutating func retry() -> Bool {
        guard !isAwaitingTrainer, messages.last?.isError == true else { return false }
        messages.removeLast()
        if messages.last?.author == .trainer { messages.removeLast() } // a partial reply
        isAwaitingTrainer = true
        return true
    }

    /// What goes to the server for a turn: every message except errors.
    var turnMessages: [ChatMessage] {
        messages.filter { !$0.isError && !$0.text.isEmpty }
    }

    // MARK: Days

    /// What a day picker sends: the days as people say them, then as the
    /// server reads them, e.g. "Plan these days: Mon 26 Oct, Wed 28 Oct
    /// (2026-10-26, 2026-10-28)".
    static func pickedDaysMessage(_ dates: [String]) -> String {
        let sorted = dates.sorted()
        return "Plan these days: \(sorted.map(dayLabel).joined(separator: ", ")) (\(sorted.joined(separator: ", ")))"
    }

    /// "Mon 26 Oct" in the athlete's locale; the date itself if it doesn't parse.
    static func dayLabel(_ date: String) -> String {
        guard let day = calendarDay(date) else { return date }
        return day.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated))
    }

    /// "Mon".
    static func weekdayLabel(_ date: String) -> String {
        calendarDay(date)?.formatted(.dateTime.weekday(.abbreviated)) ?? ""
    }

    /// "26".
    static func dayOfMonth(_ date: String) -> String {
        calendarDay(date)?.formatted(.dateTime.day()) ?? date
    }

    /// "YYYY-MM-DD" as midnight in the device's calendar.
    private static func calendarDay(_ date: String) -> Date? {
        let parts = date.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        return Calendar.current.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2]))
    }

    /// A note from the trainer that isn't a reply to a turn (the app
    /// explaining why an option can't run yet).
    mutating func appendTrainerNote(_ text: String) {
        guard !isAwaitingTrainer else { return }
        messages.append(ChatMessage(author: .trainer, text: text))
    }

    private mutating func markLastAnswered() {
        guard let last = messages.indices.last, messages[last].author == .trainer else { return }
        messages[last].answered = true
    }
}
