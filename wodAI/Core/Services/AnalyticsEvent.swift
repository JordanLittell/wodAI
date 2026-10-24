//
//  AnalyticsEvent.swift
//  wodAI
//
//  The product events the app sends to PostHog, named and shaped in one
//  place so a typo can't start a new event. Properties are ids and counts
//  only: never what anyone typed, never anything from Apple Health.
//

import Foundation

enum AnalyticsEvent: Equatable {
    /// The coach chat opened from the Workout page.
    case assistantOpened
    /// An option that counted (the first tap of a turn), by its id
    /// ("whiteboard", "program_week", "reply-1", "pick_days").
    case assistantOptionTapped(option: String, flow: String?)
    /// A conversation turn sent to the coach; `number` counts from 1 per chat.
    case assistantTurn(flow: String?, number: Int, isRetry: Bool)
    /// The Workout page ran what the chat ended on: one of the coach's actions
    /// or a client option ("generate_session", "plan_week",
    /// "open_whiteboard_scanner", "open_create_sheet").
    case assistantFlowCompleted(flow: String?, action: String)
    /// A turn ended in an error ("server", "stalled", "network").
    case assistantFlowFailed(flow: String?, reason: String)
    /// The chat closed. `stage` is how far it got: "greeting" (nothing tapped
    /// or sent), "chatting", "error" (it ended on an error) or "handed_off".
    case assistantClosed(flow: String?, stage: String, turns: Int)

    var name: String {
        switch self {
        case .assistantOpened: return "assistant_opened"
        case .assistantOptionTapped: return "assistant_option_tapped"
        case .assistantTurn: return "assistant_turn"
        case .assistantFlowCompleted: return "assistant_flow_completed"
        case .assistantFlowFailed: return "assistant_flow_failed"
        case .assistantClosed: return "assistant_closed"
        }
    }

    /// Without the flow when there's none (the athlete typed before tapping).
    var properties: [String: AnyHashable] {
        var properties: [String: AnyHashable]
        let flow: String?
        switch self {
        case .assistantOpened:
            return [:]
        case let .assistantOptionTapped(option, f):
            properties = ["option": option]
            flow = f
        case let .assistantTurn(f, number, isRetry):
            properties = ["turn": number, "retry": isRetry]
            flow = f
        case let .assistantFlowCompleted(f, action):
            properties = ["action": action]
            flow = f
        case let .assistantFlowFailed(f, reason):
            properties = ["reason": reason]
            flow = f
        case let .assistantClosed(f, stage, turns):
            properties = ["stage": stage, "turns": turns]
            flow = f
        }
        if let flow { properties["flow"] = flow }
        return properties
    }
}
