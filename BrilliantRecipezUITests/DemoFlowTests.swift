import XCTest

@MainActor
final class DemoFlowTests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testDemoRecipeBookmarkPersistsAcrossLaunches() throws {
        let app = launchFreshApp()

        let demo = app.buttons["demoRecipe"]
        XCTAssertTrue(demo.waitForExistence(timeout: 10), "The offline demo must be available without an API key.")
        for _ in 0..<4 where !demo.isHittable {
            app.scrollViews.firstMatch.swipeUp()
        }
        demo.tap()

        let title = app.staticTexts["recipeDetailTitle"]
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        XCTAssertFalse(title.label.isEmpty)
        let expectedTitle = title.label
        let save = app.buttons["saveRecipe"]
        XCTAssertTrue(save.waitForExistence(timeout: 5))
        XCTAssertEqual(save.value as? String, "Not saved")
        save.tap()
        XCTAssertEqual(save.value as? String, "Saved")

        let recipeScreenshot = XCTAttachment(screenshot: app.screenshot())
        recipeScreenshot.name = "Offline demo recipe"
        recipeScreenshot.lifetime = .keepAlways
        add(recipeScreenshot)

        app.terminate()
        app.launchArguments = ["-ui-testing"]
        app.launch()
        let library = app.tabBars.buttons["Recipe box"]
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

    func testManualIngredientsNormalizeDeduplicateAndRequireKey() throws {
        let app = launchFreshApp()
        let manual = app.buttons["manualIngredients"]
        reveal(manual, in: app)
        manual.tap()
        let input = app.textFields["ingredientInput"]
        XCTAssertTrue(input.waitForExistence(timeout: 5))
        input.tap()
        input.typeText("  TOMATOES  , tomatoes, baby   spinach, Chickpeas  ")
        app.buttons["Add ingredients"].tap()
        if app.keyboards.buttons["Done"].exists { app.keyboards.buttons["Done"].tap() }

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
        XCTAssertTrue(error.waitForExistence(timeout: 5), "Generation without a key should explain how to configure the app.")
        XCTAssertTrue(error.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "Add your own Grok API key")).firstMatch.exists)
        error.buttons["OK"].tap()
        XCTAssertTrue(app.navigationBars["A fresh start"].exists, "A missing key should preserve the draft for retry.")
    }

    func testModelConfigurationPersistsAcrossLaunches() throws {
        let app = launchFreshApp()
        app.tabBars.buttons["Settings"].tap()

        let recipeModel = app.textFields["recipeModelInput"]
        reveal(recipeModel, in: app)
        recipeModel.tap()
        recipeModel.typeText("-prototype")
        let expectedRecipeModel = try XCTUnwrap(recipeModel.value as? String)
        let visionModel = app.textFields["visionModelInput"]
        visionModel.tap()
        visionModel.typeText("-vision")
        let expectedVisionModel = try XCTUnwrap(visionModel.value as? String)
        if app.keyboards.buttons["Return"].exists { app.keyboards.buttons["Return"].tap() }
        let save = app.buttons["saveConfiguration"]
        reveal(save, in: app)
        save.tap()
        XCTAssertTrue(app.staticTexts["Configuration saved. Your key has not been tested with a live request."].waitForExistence(timeout: 5))

        app.terminate()
        app.launchArguments = ["-ui-testing"]
        app.launch()
        app.tabBars.buttons["Settings"].tap()
        reveal(recipeModel, in: app)
        XCTAssertEqual(recipeModel.value as? String, expectedRecipeModel)
        XCTAssertEqual(visionModel.value as? String, expectedVisionModel)
        XCTAssertTrue(app.staticTexts["Your own Grok key is required"].exists, "Saving model configuration must not imply a key is configured.")
    }

    func testInvalidPendingIngredientBlocksGeneration() throws {
        let app = launchFreshApp()
        let manual = app.buttons["manualIngredients"]
        reveal(manual, in: app)
        manual.tap()
        let input = app.textFields["ingredientInput"]
        XCTAssertTrue(input.waitForExistence(timeout: 5))
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
                      "Invalid pending ingredients must stop generation before checking the API key or making a request.")
    }

    func testKeychainCredentialPersistsAndCanBeRemovedWithoutNetwork() throws {
        let app = launchFreshApp()
        app.tabBars.buttons["Settings"].tap()
        let input = app.secureTextFields["apiKeyInput"]
        reveal(input, in: app)
        input.tap()
        input.typeText("ui-test-placeholder")
        if app.keyboards.buttons["Return"].exists { app.keyboards.buttons["Return"].tap() }
        let save = app.buttons["saveConfiguration"]
        reveal(save, in: app)
        save.tap()
        XCTAssertTrue(app.staticTexts["Configuration saved. Your key has not been tested with a live request."].waitForExistence(timeout: 5))

        app.terminate()
        app.launchArguments = ["-ui-testing"]
        app.launch()
        assertCleanLaunch(app)
        app.tabBars.buttons["Settings"].tap()
        XCTAssertTrue(app.staticTexts["Key saved securely on this device"].waitForExistence(timeout: 5))
        let remove = app.buttons["Remove API key"]
        reveal(remove, in: app)
        remove.tap()
        let confirm = app.buttons["Remove key"]
        XCTAssertTrue(confirm.waitForExistence(timeout: 5))
        confirm.tap()

        app.terminate()
        app.launch()
        assertCleanLaunch(app)
        app.tabBars.buttons["Settings"].tap()
        XCTAssertTrue(app.staticTexts["Your own Grok key is required"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["Key saved securely on this device"].exists)
    }

    private func launchFreshApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-reset-demo-state"]
        app.launch()
        assertCleanLaunch(app)
        return app
    }

    private func assertCleanLaunch(_ app: XCUIApplication) {
        XCTAssertTrue(app.buttons["manualIngredients"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.alerts.firstMatch.exists, "App startup must not show a storage or Keychain error.")
    }

    private func reveal(_ element: XCUIElement, in app: XCUIApplication) {
        for _ in 0..<6 {
            if element.exists && element.isHittable { return }
            let container = app.collectionViews.firstMatch.exists ? app.collectionViews.firstMatch : app.scrollViews.firstMatch
            let frame = container.exists ? container.frame : app.frame
            // Keep the gesture above both the keyboard's prediction bar and the
            // home indicator / tab bar. Their frames overlap the form's frame.
            var startY = min(frame.maxY - 130, app.frame.maxY - 130)
            if app.keyboards.firstMatch.exists { startY = min(startY, app.keyboards.firstMatch.frame.minY - 100) }
            let start = app.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: frame.midX, dy: startY))
            let end = app.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: frame.midX, dy: max(frame.minY + 90, app.frame.minY + 160)))
            start.press(forDuration: 0.05, thenDragTo: end)
        }
        XCTAssertTrue(element.exists && element.isHittable, "Expected control must be reachable by scrolling.\n\(app.debugDescription)")
    }
}
