//
//  EditHiitCompletionView.swift
//  wodAI
//
//  Opened by tapping a HIIT card on Stats: the completion screen in edit
//  mode, seeded with the logged result. Save sends `updateHiitCompletion`
//  and hands the edited entry back so the card updates in place.
//

import SwiftUI
import Apollo
import WodAiAPI

struct EditHiitCompletionView: View {
    let entry: CompletedHiitEntry
    let onSaved: (CompletedHiitEntry) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    var body: some View {
        HIITWorkoutCompletionView(
            draft: entry.completionDraft,
            heartRate: heartRate,
            errorMessage: errorMessage,
            isSubmitting: isSubmitting,
            isEditing: true,
            onDone: { save($0) }
        )
        .navigationBarTitleDisplayMode(.inline)
    }

    private var heartRate: CompletionHeartRate {
        guard let summary = entry.heartRateSummary else { return CompletionHeartRate.none }
        return .ready(summary, entry.heartRate, zoneThresholds: entry.zoneThresholds)
    }

    private func save(_ draft: WorkoutCompletionDraft) {
        guard !isSubmitting else { return }
        let edit = entry.edit(from: draft)
        Task {
            isSubmitting = true
            errorMessage = nil
            defer { isSubmitting = false }
            do {
                let saved = try await Self.send(edit, completionId: entry.id)
                var updated = entry
                updated.durationSeconds = saved.durationSeconds
                updated.roundsCompleted = saved.roundsCompleted
                updated.repsCompleted = saved.repsCompleted
                updated.perceivedEffort = saved.perceivedEffort
                updated.trainingLoad = saved.trainingLoad
                onSaved(updated)
                dismiss()
            } catch EditError.graphQL {
                errorMessage = "We couldn't save your changes. Please try again."
            } catch {
                errorMessage = "We couldn't save your changes. Check your connection and try again."
            }
        }
    }

    private enum EditError: Error {
        case graphQL
    }

    /// Same shape as HIITWorkoutViewModel.performCompletion: GraphQL errors
    /// count as failures, and both kinds are reported to telemetry.
    private static func send(
        _ edit: HiitCompletionEdit,
        completionId: Int
    ) async throws -> UpdateHiitCompletionMutation.Data.UpdateHiitCompletion {
        let operation = "UpdateHiitCompletion"
        let mutation = UpdateHiitCompletionMutation(
            id: completionId,
            durationSeconds: edit.durationSeconds.map { .some($0) } ?? .none,
            roundsCompleted: edit.roundsCompleted.map { .some($0) } ?? .none,
            repsCompleted: edit.repsCompleted.map { .some($0) } ?? .none,
            perceivedEffort: edit.perceivedEffort.map { .some($0) } ?? .none
        )
        let result: GraphQLResult<UpdateHiitCompletionMutation.Data>
        do {
            result = try await withCheckedThrowingContinuation { continuation in
                Network.shared.client.perform(mutation: mutation) { result in
                    continuation.resume(with: result)
                }
            }
        } catch {
            TelemetryService.captureError(error, tags: ["operation": operation])
            throw error
        }
        if let errors = result.errors, !errors.isEmpty {
            let messages = errors.compactMap { $0.message }.joined(separator: "; ")
            TelemetryService.captureGraphQLErrors(messages: messages, operation: operation)
            throw EditError.graphQL
        }
        guard let saved = result.data?.updateHiitCompletion else { throw EditError.graphQL }
        TelemetryService.captureMessage("workout.hiit_completion_edited")
        return saved
    }
}
