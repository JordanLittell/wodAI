//
//  TrainingMemoryViewModel.swift
//  wodAI
//
//  Drives Your training (menu: Training): loads what the coach keeps to and
//  sends the athlete's corrections. Nothing is changed on screen until the
//  server has it, so the list never shows something the planners don't.
//

import Foundation

@MainActor
final class TrainingMemoryViewModel: ObservableObject {
    @Published private(set) var memory: TrainingMemory = .empty
    @Published private(set) var hasLoaded = false
    @Published private(set) var isLoading = false
    /// Set when loading fails with nothing to show; drives the retry card.
    @Published private(set) var loadError: String?
    /// The item being saved or removed.
    @Published private(set) var busyId: String?
    /// Why the last edit or removal didn't go through.
    @Published var actionError: String?

    private let api: TrainingMemoryAPI
    private let track: (AnalyticsEvent) -> Void

    init(api: TrainingMemoryAPI = .live, track: @escaping (AnalyticsEvent) -> Void = AnalyticsService.capture) {
        self.api = api
        self.track = track
    }

    var hasActionError: Bool {
        get { actionError != nil }
        set { if !newValue { actionError = nil } }
    }

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            memory = try await api.load()
            hasLoaded = true
            loadError = nil
        } catch {
            // Keep what's on screen; only an empty screen shows the error.
            if !hasLoaded { loadError = Self.message(for: error, fallback: "Couldn't load your training.") }
        }
    }

    /// Saves the athlete's wording and, for a focus, its block length. Only
    /// what changed is sent. True once saved (or when nothing changed), so
    /// the sheet can close.
    func save(_ item: TrainingMemoryItem, text: String, weeks: Int?) async -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            actionError = "Write something for the coach to keep to, or remove it."
            return false
        }
        guard trimmed.count <= TrainingMemoryItem.maxTextLength else {
            actionError = "Keep it under \(TrainingMemoryItem.maxTextLength) characters."
            return false
        }
        let newText = trimmed == item.text ? nil : trimmed
        let newWeeks = item.kind == .focus && weeks != item.totalWeeks ? weeks : nil
        guard newText != nil || newWeeks != nil else { return true }

        busyId = item.id
        defer { busyId = nil }
        do {
            let saved = try await api.update(item.id, newText, newWeeks)
            memory = memory.replacing(saved)
            track(.memoryEdited(kind: Self.kindName(item.kind), changedLength: newWeeks != nil))
            return true
        } catch {
            actionError = Self.message(for: error, fallback: "Couldn't save that change.")
            return false
        }
    }

    /// Takes an item off the list: a focus ends, a habit or avoid is removed.
    /// True once it's gone, including when it was gone already.
    func remove(_ item: TrainingMemoryItem) async -> Bool {
        busyId = item.id
        defer { busyId = nil }
        do {
            let removed = try await api.remove(item.id)
            memory = memory.removing(id: item.id)
            if removed { track(.memoryRemoved(kind: Self.kindName(item.kind))) }
            return true
        } catch {
            actionError = Self.message(for: error, fallback: item.kind == .focus ? "Couldn't end that focus." : "Couldn't remove that.")
            return false
        }
    }

    static func kindName(_ kind: TrainingMemoryItem.Kind) -> String {
        switch kind {
        case .focus: return "focus"
        case .habit: return "habit"
        case .avoid: return "avoid"
        }
    }

    /// The server's message when it sent one for the athlete; otherwise the
    /// fallback (network errors aren't worded for people).
    private static func message(for error: Error, fallback: String) -> String {
        if case let TrainingMemoryAPI.APIError.server(message) = error, message != "No data" { return message }
        return fallback
    }
}
