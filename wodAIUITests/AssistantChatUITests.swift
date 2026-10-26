//
//  AssistantChatUITests.swift
//  wodAIUITests
//
//  The assistant button on the Workout page opens the trainer chat and the
//  chat closes back to the same day, on fixtures (`-uiTesting`).
//

import XCTest

final class AssistantChatUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-uiTesting"]
        app.launch()
    }

    @MainActor
    func testOpeningAndClosingTheChat() throws {
        let button = app.buttons["assistantButton"]
        XCTAssertTrue(button.waitForExistence(timeout: 10))
        // The + menu is gone.
        XCTAssertFalse(app.buttons["Add"].exists)
        let navigationBar = app.navigationBars.firstMatch
        XCTAssertTrue(navigationBar.exists)
        attachScreenshot("A5-workout-page")

        button.tap()
        // The bundled greeting shows at once, whatever the network does.
        // The button is labeled "Coach" too, so the chat is found by its ✕.
        let close = app.buttons["Close assistant"]
        XCTAssertTrue(close.waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Import Workout From Whiteboard"].waitForExistence(timeout: 5))
        XCTAssertFalse(button.exists)
        // Full screen: the page's navigation bar (menu, week title) is hidden.
        XCTAssertTrue(waitForDisappearance(of: navigationBar))
        attachScreenshot("A5-chat-open")

        close.tap()
        XCTAssertTrue(button.waitForExistence(timeout: 5))
        XCTAssertFalse(close.exists)
        XCTAssertTrue(navigationBar.waitForExistence(timeout: 5))
    }

    private func waitForDisappearance(of element: XCUIElement) -> Bool {
        let gone = expectation(for: NSPredicate(format: "exists == false"), evaluatedWith: element)
        return XCTWaiter().wait(for: [gone], timeout: 5) == .completed
    }

    private func attachScreenshot(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
