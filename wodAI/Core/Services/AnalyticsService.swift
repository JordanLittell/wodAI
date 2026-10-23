//
//  AnalyticsService.swift
//  wodAI
//
//  Product analytics in PostHog, alongside TelemetryService (Sentry), which
//  keeps errors and crashes. Never send anything read from Apple Health here:
//  Apple doesn't allow HealthKit data to go to third-party analytics.
//

import PostHog

enum AnalyticsService {

    static func initialize() {
        guard !AppConfig.posthogAPIKey.isEmpty else { return }
        let config = PostHogConfig(projectToken: AppConfig.posthogAPIKey, host: AppConfig.posthogHost)
        // SwiftUI screens autocapture as hosting-controller class names, so
        // screens are logged by hand.
        config.captureScreenViews = false
        config.captureApplicationLifecycleEvents = true
        config.personProfiles = .identifiedOnly
        // Replay would record the Health and heart-rate screens.
        config.sessionReplay = false
        config.debug = AppConfig.enableLogging
        PostHogSDK.shared.setup(config)
        registerBuildProperties()
    }

    static func identify(userId: String) {
        PostHogSDK.shared.identify(userId)
    }

    /// On sign-out, so the next athlete on this phone isn't merged into the last.
    static func reset() {
        PostHogSDK.shared.reset()
        // reset() clears super properties too.
        registerBuildProperties()
    }

    /// Sent with every event, so Debug builds can be filtered out of the metrics.
    private static func registerBuildProperties() {
        PostHogSDK.shared.register(["is_debug_build": !AppConfig.isProduction])
    }
}
