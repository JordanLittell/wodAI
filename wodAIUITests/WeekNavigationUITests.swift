//
//  WeekNavigationUITests.swift
//  wodAIUITests
//
//  The Workout page moving between weeks, end to end, on fixtures
//  (`-uiTesting`, see UITestMode.swift): each session is named by its week's
//  offset from this one and its day's place in the week, "W-1 D3".
//

import XCTest

final class WeekNavigationUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-uiTesting"]
        app.launch()
    }

    @MainActor
    func testSwipingBetweenWeeks() throws {
        let today = try todayIndex()
        XCTAssertFalse(todayButton.exists)

        // Back a week, to the same day of the week.
        swipeStrip(.right)
        assertShowing("W-1 D\(today)")
        XCTAssertTrue(todayButton.waitForExistence(timeout: 5))

        swipeStrip(.right)
        assertShowing("W-2 D\(today)")
        swipeStrip(.left)
        assertShowing("W-1 D\(today)")

        todayButton.tap()
        assertShowing("W0 D\(today)")
        XCTAssertTrue(todayButton.waitForNonExistence(timeout: 5))
    }

    @MainActor
    func testSwipingDaysCarriesOnIntoTheNextWeek() throws {
        _ = try todayIndex()

        app.descendants(matching: .any)["day-6"].tap()
        assertShowing("W0 D6")

        swipeContent(.left)
        assertShowing("W1 D0")
        swipeContent(.right)
        assertShowing("W0 D6")
    }

    @MainActor
    func testAWeekWithNothingScheduledSaysSo() throws {
        let today = try todayIndex()

        swipeStrip(.left)
        assertShowing("W1 D\(today)")
        swipeStrip(.left)
        assertShowing("W2 D\(today)")
        // The fixtures stop two weeks out.
        swipeStrip(.left)
        XCTAssertTrue(app.staticTexts["No workout scheduled"].waitForExistence(timeout: 5))
    }

    // MARK: - Helpers

    private enum Direction { case left, right }

    private var todayButton: XCUIElement { app.buttons["todayButton"] }

    /// The day of the week today falls on, read from the session shown at launch.
    private func todayIndex() throws -> Int {
        let header = sessionHeaders(startingWith: "W0 D").firstMatch
        XCTAssertTrue(header.waitForExistence(timeout: 10), "The Workout page didn't open on this week")
        let name = header.label.components(separatedBy: ",")[0]
        return try XCTUnwrap(Int(name.dropFirst("W0 D".count)))
    }

    /// Session headers read as "<name>, <source>, …".
    private func sessionHeaders(startingWith prefix: String) -> XCUIElementQuery {
        app.descendants(matching: .any).matching(NSPredicate(format: "label BEGINSWITH %@", prefix))
    }

    private func assertShowing(_ name: String, file: StaticString = #filePath, line: UInt = #line) {
        let header = sessionHeaders(startingWith: "\(name),").firstMatch
        XCTAssertTrue(header.waitForExistence(timeout: 5), "Expected session \(name)", file: file, line: line)
    }

    private func swipeStrip(_ direction: Direction) {
        let strip = app.descendants(matching: .any)["weekStrip"]
        XCTAssertTrue(strip.waitForExistence(timeout: 5))
        drag(strip, direction, atHeight: 0.5)
    }

    /// Swipes the day below its session header, which has its own swipe
    /// (to reveal Delete).
    private func swipeContent(_ direction: Direction) {
        drag(app.scrollViews.firstMatch, direction, atHeight: 0.7)
    }

    private func drag(_ element: XCUIElement, _ direction: Direction, atHeight dy: CGFloat) {
        let (from, to): (CGFloat, CGFloat) = direction == .left ? (0.85, 0.15) : (0.15, 0.85)
        element.coordinate(withNormalizedOffset: CGVector(dx: from, dy: dy))
            .press(forDuration: 0.05, thenDragTo: element.coordinate(withNormalizedOffset: CGVector(dx: to, dy: dy)))
    }
}
