import XCTest

/// These tests cover local UI, persistence and unavailable-model behavior.
/// They deliberately do not claim to exercise Apple Intelligence inference.
@MainActor
final class DemoFlowTests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testSampleRecipeBookmarkPersistsAcrossLaunches() throws {
        let app = launchFreshApp()
        let sample = app.buttons["demoRecipe"]
        XCTAssertTrue(sample.waitForExistence(timeout: 10), "The sample must be available when Apple Intelligence is unavailable.")
        reveal(sample, in: app)
        sample.tap()

        let title = app.staticTexts["recipeDetailTitle"]
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        XCTAssertFalse(title.label.isEmpty)
        let expectedTitle = title.label
        let save = app.buttons["saveRecipe"]
        XCTAssertTrue(save.waitForExistence(timeout: 5))
        XCTAssertEqual(save.value as? String, "Not saved")
        save.tap()
        XCTAssertEqual(save.value as? String, "Saved")

        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Sample recipe — fixture, not generated"
        screenshot.lifetime = .keepAlways
        add(screenshot)

        app.terminate()
        app.launchArguments = ["-ui-testing"]
        app.launch()
        let library = app.tabBars.buttons["Saved"]
        XCTAssertTrue(library.waitForExistence(timeout: 10))
        library.tap()
        let savedRow = app.buttons["savedRecipeRow"].firstMatch
        XCTAssertTrue(savedRow.waitForExistence(timeout: 5), "Saved recipes must survive an app restart.")
        savedRow.tap()
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        XCTAssertEqual(title.label, expectedTitle)
        XCTAssertEqual(save.value as? String, "Saved")
        save.tap()
        XCTAssertEqual(save.value as? String, "Not saved")

        app.terminate()
        app.launch()
        XCTAssertTrue(library.waitForExistence(timeout: 10))
        library.tap()
        XCTAssertFalse(app.buttons["savedRecipeRow"].firstMatch.exists, "Removing a bookmark must also persist.")
    }

    func testUnavailableModelPreservesNormalizedEditableIngredients() throws {
        let app = launchFreshApp()
        openComposer(in: app)
        let input = app.textFields["ingredientInput"]
        input.tap()
        input.typeText("  TOMATOES  , tomatoes, baby   spinach, Chickpeas  ")
        app.buttons["Add ingredients"].tap()
        dismissKeyboard(in: app)

        for ingredient in ["Tomatoes", "Baby spinach", "Chickpeas"] {
            XCTAssertTrue(app.buttons["Remove \(ingredient)"].exists, "Normalized ingredient \(ingredient) should be editable.")
        }
        XCTAssertEqual(app.buttons.matching(identifier: "Remove Tomatoes").count, 1, "Case-insensitive duplicates should collapse into a single ingredient.")
        app.buttons["Remove Baby spinach"].tap()
        XCTAssertFalse(app.buttons["Remove Baby spinach"].exists)

        let generate = app.buttons["generateRecipe"]
        reveal(generate, in: app)
        XCTAssertTrue(generate.isEnabled)
        generate.tap()
        let error = app.alerts.firstMatch
        XCTAssertTrue(error.waitForExistence(timeout: 5), "An unavailable local model must explain why generation cannot run.")
        XCTAssertTrue(error.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "Apple Intelligence")).firstMatch.exists)
        error.buttons["OK"].tap()
        XCTAssertFalse(app.staticTexts["recipeDetailTitle"].exists, "Model unavailability must never be presented as a generated sample.")
        revealTowardTop(input, in: app)
        XCTAssertTrue(app.textFields["ingredientInput"].exists, "The ingredient draft must remain open for retry.")
        XCTAssertTrue(app.buttons["Remove Tomatoes"].exists)
        XCTAssertTrue(app.buttons["Remove Chickpeas"].exists)
    }

    func testSettingsShowsLocalModelStatusWithoutAccountConfiguration() throws {
        let app = launchFreshApp()
        app.tabBars.buttons["Settings"].tap()
        let status = app.staticTexts["modelAvailabilityTitle"]
        XCTAssertTrue(status.waitForExistence(timeout: 5), "Settings must expose the device model availability.")
        XCTAssertFalse(status.label.isEmpty)
        XCTAssertTrue(app.staticTexts["modelAvailabilityMessage"].exists)
        XCTAssertTrue(app.buttons["refreshAvailability"].exists)
        XCTAssertEqual(app.secureTextFields.count, 0, "No credential input should remain.")
        XCTAssertEqual(app.textFields.count, 0, "Model/provider configuration should not be required.")
        XCTAssertFalse(app.buttons["saveConfiguration"].exists)
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Settings — controlled unavailable-model state"
        screenshot.lifetime = .keepAlways
        add(screenshot)

        app.terminate()
        app.launchArguments = ["-ui-testing"]
        app.launch()
        assertCleanLaunch(app)
        app.tabBars.buttons["Settings"].tap()
        XCTAssertTrue(status.waitForExistence(timeout: 5))
        XCTAssertEqual(app.secureTextFields.count, 0)
    }

    func testInvalidPendingIngredientBlocksGeneration() throws {
        let app = launchFreshApp()
        openComposer(in: app)
        let input = app.textFields["ingredientInput"]
        input.tap()
        input.typeText("Tomato")
        app.buttons["Add ingredients"].tap()
        input.tap()
        input.typeText(String(repeating: "x", count: 81))
        let generate = app.buttons["generateRecipe"]
        reveal(generate, in: app)
        generate.tap()
        let error = app.alerts.firstMatch
        XCTAssertTrue(error.waitForExistence(timeout: 5))
        XCTAssertTrue(error.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "up to 80 characters")).firstMatch.exists,
                      "Invalid pending ingredients must stop generation before checking model availability.")
        error.buttons["OK"].tap()
        revealTowardTop(input, in: app)
        XCTAssertEqual(input.value as? String, String(repeating: "x", count: 81), "Keep invalid input editable so the user can correct it.")
        XCTAssertTrue(app.buttons["Remove Tomato"].exists)
    }

    func testEmptyIngredientDraftCannotGenerate() throws {
        let app = launchFreshApp()
        openComposer(in: app)
        let generate = app.buttons["generateRecipe"]
        reveal(generate, in: app)
        XCTAssertFalse(generate.isEnabled, "An empty draft must not start inference.")
        let input = app.textFields["ingredientInput"]
        revealTowardTop(input, in: app)
        input.tap()
        input.typeText("   ")
        dismissKeyboard(in: app)
        reveal(generate, in: app)
        XCTAssertFalse(generate.isEnabled, "Whitespace is not an ingredient.")
    }

    private func launchFreshApp() -> XCUIApplication {
        let app = XCUIApplication()
        // AppModel treats -ui-testing as unavailable regardless of host hardware.
        app.launchArguments = ["-ui-testing", "-reset-demo-state"]
        app.launch()
        assertCleanLaunch(app)
        return app
    }

    private func assertCleanLaunch(_ app: XCUIApplication) {
        XCTAssertTrue(app.buttons["manualIngredients"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.alerts.firstMatch.exists, "Startup should not show a storage error.")
    }

    private func openComposer(in app: XCUIApplication) {
        let manual = app.buttons["manualIngredients"]
        reveal(manual, in: app)
        manual.tap()
        XCTAssertTrue(app.textFields["ingredientInput"].waitForExistence(timeout: 5))
    }

    private func dismissKeyboard(in app: XCUIApplication) {
        if app.keyboards.buttons["Done"].exists { app.keyboards.buttons["Done"].tap() }
    }

    private func revealTowardTop(_ element: XCUIElement, in app: XCUIApplication) {
        for _ in 0..<6 {
            if safelyHittable(element, in: app) { return }
            let container = app.collectionViews.firstMatch.exists ? app.collectionViews.firstMatch : app.scrollViews.firstMatch
            container.swipeDown()
        }
        XCTAssertTrue(element.exists && element.isHittable, "The ingredient draft must remain reachable.")
    }

    private func safelyHittable(_ element: XCUIElement, in app: XCUIApplication) -> Bool {
        guard element.exists && element.isHittable else { return false }
        // iOS 26 can report a button as hittable even while the keyboard covers it.
        let keyboard = app.keyboards.firstMatch
        guard keyboard.exists else { return true }
        return element.frame.maxY <= keyboard.frame.minY - 48
    }

    private func reveal(_ element: XCUIElement, in app: XCUIApplication) {
        for _ in 0..<6 {
            if safelyHittable(element, in: app) { return }
            let container = app.collectionViews.firstMatch.exists ? app.collectionViews.firstMatch : app.scrollViews.firstMatch
            let frame = container.exists ? container.frame : app.frame
            // Keep the gesture above the keyboard, home indicator and tab bar.
            var startY = min(frame.maxY - 130, app.frame.maxY - 130)
            if app.keyboards.firstMatch.exists { startY = min(startY, app.keyboards.firstMatch.frame.minY - 100) }
            let start = app.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: frame.midX, dy: startY))
            let end = app.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: frame.midX, dy: max(frame.minY + 90, app.frame.minY + 160)))
            start.press(forDuration: 0.05, thenDragTo: end)
        }
        XCTAssertTrue(safelyHittable(element, in: app), "Expected control must be reachable above the keyboard and system bars.\n\(app.debugDescription)")
    }
}
