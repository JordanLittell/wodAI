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
        attachScreenshot("A5-workout-page")

        button.tap()
        // The bundled greeting shows at once, whatever the network does.
        XCTAssertTrue(app.staticTexts["Coach"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Import Workout From Whiteboard"].waitForExistence(timeout: 5))
        XCTAssertFalse(button.exists)
        attachScreenshot("A5-chat-open")

        app.buttons["Close assistant"].tap()
        XCTAssertTrue(button.waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["Coach"].exists)
    }

    private func attachScreenshot(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
