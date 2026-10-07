//
//  ExerciseVideoSourceTests.swift
//  wodAITests
//

import Testing
import Foundation
@testable import wodAI

struct ExerciseVideoSourceTests {

    private func source(_ string: String) -> ExerciseVideoSource? {
        URL(string: string).flatMap(ExerciseVideoSource.init(url:))
    }

    // MARK: - YouTube

    @Test(arguments: [
        "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
        "https://m.youtube.com/watch?v=dQw4w9WgXcQ&list=PL1",
        "https://youtu.be/dQw4w9WgXcQ?si=abc",
        "https://www.youtube.com/shorts/dQw4w9WgXcQ",
        "https://www.youtube-nocookie.com/embed/dQw4w9WgXcQ",
    ])
    func readsTheVideoID(_ url: String) {
        #expect(source(url) == .youtube(id: "dQw4w9WgXcQ", start: nil))
    }

    @Test func readsTheStartOffset() {
        #expect(source("https://www.youtube.com/watch?v=dQw4w9WgXcQ&t=30") == .youtube(id: "dQw4w9WgXcQ", start: 30))
        #expect(source("https://youtu.be/dQw4w9WgXcQ?t=1m30s") == .youtube(id: "dQw4w9WgXcQ", start: 90))
        #expect(source("https://youtu.be/dQw4w9WgXcQ?t=0") == .youtube(id: "dQw4w9WgXcQ", start: nil))
    }

    @Test func rejectsYouTubeLinksWithoutAVideo() {
        #expect(source("https://www.youtube.com/channel/UC123") == nil)
        #expect(source("https://www.youtube.com/watch?v=short") == nil)
        #expect(source("https://youtu.be/") == nil)
    }

    @Test func embedsInlineWithoutRelatedVideos() {
        let embed = ExerciseVideoSource.youtube(id: "dQw4w9WgXcQ", start: 30).embedURL?.absoluteString
        #expect(embed == "https://www.youtube-nocookie.com/embed/dQw4w9WgXcQ?playsinline=1&rel=0&modestbranding=1&start=30")
    }

    // MARK: - Files

    @Test func otherURLsAreFiles() {
        let url = URL(string: "https://cdn.wodai.run/videos/thruster.mp4")!
        #expect(ExerciseVideoSource(url: url) == .file(url))
        #expect(ExerciseVideoSource.file(url).embedURL == nil)
    }

    @Test func rejectsNonWebURLs() {
        #expect(source("ftp://example.com/video.mp4") == nil)
        #expect(source("file:///tmp/video.mp4") == nil)
    }

    // MARK: - Offsets

    @Test func parsesOffsets() {
        #expect(ExerciseVideoSource.seconds("45") == 45)
        #expect(ExerciseVideoSource.seconds("45s") == 45)
        #expect(ExerciseVideoSource.seconds("1h2m3s") == 3723)
        #expect(ExerciseVideoSource.seconds("abc") == nil)
        #expect(ExerciseVideoSource.seconds(nil) == nil)
    }
}
