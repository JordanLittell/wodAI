//
//  TelemetryService.swift
//  wodAI
//

import Sentry

enum TelemetryService {

    static func initialize() {
        guard !AppConfig.sentryDSN.isEmpty else { return }
        SentrySDK.start { options in
            options.dsn = AppConfig.sentryDSN
            options.environment = AppConfig.isProduction ? "production" : "development"
            options.tracesSampleRate = 1.0
            options.enableMetricKit = true
            options.sendDefaultPii = false

            options.sessionReplay.onErrorSampleRate = 1.0
            options.sessionReplay.sessionSampleRate = 0.1
        }
    }

    static func identify(userId: String) {
        let user = Sentry.User()
        user.userId = userId
        SentrySDK.setUser(user)
    }

    static func clearIdentity() {
        SentrySDK.setUser(nil)
    }

    static func captureError(_ error: Error, tags: [String: String] = [:]) {
        SentrySDK.capture(error: error) { scope in
            tags.forEach { scope.setTag(value: $1, key: $0) }
        }
    }

    static func captureMessage(_ message: String, level: SentryLevel = .info, tags: [String: String] = [:]) {
        SentrySDK.capture(message: message) { scope in
            scope.setLevel(level)
            tags.forEach { scope.setTag(value: $1, key: $0) }
        }
    }

    static func addBreadcrumb(category: String, message: String, data: [String: Any] = [:]) {
        let crumb = Breadcrumb(level: .info, category: category)
        crumb.message = message
        crumb.data = data
        SentrySDK.addBreadcrumb(crumb)
    }

    static func captureGraphQLErrors(messages: String, operation: String) {
        captureMessage(
            "graphql_error: \(operation)",
            level: .error,
            tags: ["operation": operation, "errors": messages]
        )
    }
}
