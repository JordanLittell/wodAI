//
//  ExerciseVideo.swift
//  wodAI
//
//  An exercise's how-to video, played inline. The backend stores YouTube links
//  in one canonical form (https://www.youtube.com/watch?v=<id>[&t=<seconds>]),
//  which play in a YouTube embed; any other URL is a video file (self-hosted
//  later) and plays in AVKit.
//

import AVKit
import SwiftUI
import WebKit

/// What kind of video a URL points at. Apollo-free so it's unit-testable.
enum ExerciseVideoSource: Equatable {
    case youtube(id: String, start: Int?)
    case file(URL)

    /// Nil for a URL that isn't http(s), or a YouTube link with no video id.
    init?(url: URL) {
        guard let scheme = url.scheme?.lowercased(), scheme == "https" || scheme == "http",
              let host = url.host?.lowercased() else { return nil }

        let isYouTube = host == "youtu.be" || host == "youtube.com" || host.hasSuffix(".youtube.com")
            || host == "youtube-nocookie.com" || host.hasSuffix(".youtube-nocookie.com")
        guard isYouTube else {
            self = .file(url)
            return
        }

        let query = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        let value = { (name: String) in query.first { $0.name == name }?.value }
        let segments = url.pathComponents.filter { $0 != "/" }

        let id: String?
        if host == "youtu.be" {
            id = segments.first
        } else if segments.first == "watch" {
            id = value("v")
        } else if let first = segments.first, ["shorts", "embed", "live", "v"].contains(first), segments.count > 1 {
            id = segments[1]
        } else {
            id = nil
        }
        guard let id, Self.isYouTubeID(id) else { return nil }
        self = .youtube(id: id, start: Self.seconds(value("t") ?? value("start")))
    }

    /// The privacy-enhanced embed, inline rather than taking over the screen.
    var embedURL: URL? {
        guard case let .youtube(id, start) = self else { return nil }
        var components = URLComponents(string: "https://www.youtube-nocookie.com/embed/\(id)")!
        components.queryItems = [
            URLQueryItem(name: "playsinline", value: "1"),
            URLQueryItem(name: "rel", value: "0"),
            URLQueryItem(name: "modestbranding", value: "1"),
        ] + (start.map { [URLQueryItem(name: "start", value: String($0))] } ?? [])
        return components.url
    }

    private static func isYouTubeID(_ id: String) -> Bool {
        id.count == 11 && id.allSatisfy { $0.isASCII && ($0.isLetter || $0.isNumber || $0 == "-" || $0 == "_") }
    }

    /// "90", "90s", "1m30s", "1h2m3s" → seconds. Nil when absent, zero or unreadable.
    static func seconds(_ value: String?) -> Int? {
        guard let value, !value.isEmpty else { return nil }
        if let plain = Int(value.hasSuffix("s") ? String(value.dropLast()) : value) {
            return plain > 0 ? plain : nil
        }
        var total = 0
        var digits = ""
        for character in value {
            if character.isNumber {
                digits.append(character)
            } else {
                guard let number = Int(digits) else { return nil }
                switch character {
                case "h": total += number * 3600
                case "m": total += number * 60
                case "s": total += number
                default: return nil
                }
                digits = ""
            }
        }
        guard digits.isEmpty else { return nil }
        return total > 0 ? total : nil
    }
}

/// Plays `url` inline, filling its frame. Renders nothing for a URL it can't
/// play, so callers check `ExerciseVideoSource(url:)` first.
struct ExerciseVideoPlayer: View {
    let source: ExerciseVideoSource

    var body: some View {
        switch source {
        case .youtube:
            if let embedURL = source.embedURL {
                YouTubeEmbedView(url: embedURL)
            }
        case let .file(url):
            FileVideoView(url: url)
        }
    }
}

/// A self-hosted video. The player is made on appear and paused on disappear,
/// so scrolling the header away doesn't keep playing audio.
private struct FileVideoView: View {
    let url: URL
    @State private var player: AVPlayer?

    var body: some View {
        VideoPlayer(player: player)
            .onAppear { if player == nil { player = AVPlayer(url: url) } }
            .onDisappear { player?.pause() }
    }
}

/// A YouTube embed in a web view. YouTube refuses embeds with no referrer
/// ("Error 153"), so the page is loaded with one rather than from an HTML string.
private struct YouTubeEmbedView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = .all
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.isOpaque = false
        webView.backgroundColor = .black
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        load(in: webView, context: context)
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        if context.coordinator.loadedURL != url {
            load(in: webView, context: context)
        }
    }

    static func dismantleUIView(_ webView: WKWebView, coordinator: Coordinator) {
        // Stops playback when the header goes away (e.g. switching exercise).
        webView.loadHTMLString("", baseURL: nil)
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator {
        var loadedURL: URL?
    }

    private func load(in webView: WKWebView, context: Context) {
        var request = URLRequest(url: url)
        request.setValue("https://wodai.run", forHTTPHeaderField: "Referer")
        webView.load(request)
        context.coordinator.loadedURL = url
    }
}
