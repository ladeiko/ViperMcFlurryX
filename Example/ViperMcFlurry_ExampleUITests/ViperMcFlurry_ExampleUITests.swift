//
//  ViperMcFlurry_ExampleUITests.swift
//  ViperMcFlurry_ExampleUITests
//
//  End-to-end UI tests for the example app. These drive the real app through
//  XCUIApplication and exercise the module-routing code paths that the unit
//  tests can only cover in isolation — in particular the single (shared)
//  `prepareForSegue:` swizzle that delivers a module input to the open-module
//  promise, and the Swift `openModuleUsingFactory` present/close flow.
//
//  The app launches into a tab bar: the "Swift Only" tab hosts the Swift
//  flows; the "ObjC+Swift" tab hosts the Objective-C Alpha/Beta modules.
//

import XCTest

final class ViperMcFlurry_ExampleUITests: XCTestCase {

    private let timeout: TimeInterval = 15

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    @MainActor
    private func launchOnObjCTab() -> XCUIApplication {
        let app = XCUIApplication()
        app.launch()
        let objcTab = app.buttons["ObjC+Swift"]
        XCTAssertTrue(objcTab.waitForExistence(timeout: timeout), "tab bar should be visible on launch")
        objcTab.tap()
        return app
    }

    /// #3 (segue swizzle) end-to-end: the Alpha module opens Beta via
    /// `openModuleUsingSegue(...).thenChainUsingBlock { ... }`, passing the text
    /// field's contents ("Some Example Text") into the Beta module input. Beta
    /// renders that string in a label ONLY if the module input was actually
    /// delivered through the swizzled `prepareForSegue:`. Asserting the label
    /// therefore validates the refactored single-swizzle path for the
    /// Objective-C open-module promise.
    @MainActor
    func testSegueDeliversModuleInputToBetaModule() {
        let app = launchOnObjCTab()

        let segueButton = app.buttons["Send Data To Beta Module Via Segue"]
        XCTAssertTrue(segueButton.waitForExistence(timeout: timeout))
        segueButton.tap()

        // The label is a static text; Alpha's value lives in a text field, so
        // querying staticTexts uniquely targets the Beta module's label.
        let deliveredLabel = app.staticTexts["Some Example Text"]
        XCTAssertTrue(deliveredLabel.waitForExistence(timeout: timeout),
                      "Beta must display the string delivered via the segue module input")

        // Closing Beta exercises closeCurrentModule (and the animation-wait path).
        let back = app.buttons["Back with animation"]
        XCTAssertTrue(back.waitForExistence(timeout: timeout))
        back.tap()

        XCTAssertTrue(segueButton.waitForExistence(timeout: timeout),
                      "should return to the Alpha module after closing Beta")
    }

    /// Factory + storyboard path: `openModuleUsingFactory(...).thenChainUsingBlock`
    /// instantiates the Beta module, configures it with the example string, and
    /// pushes it. Asserting the delivered label validates module-input delivery
    /// through the factory promise; the nav back button returns to Alpha.
    @MainActor
    func testInstantiateBetaModuleWithFactory() {
        let app = launchOnObjCTab()

        let factoryButton = app.buttons["Instantiate Beta With Factory And Storyboard"]
        XCTAssertTrue(factoryButton.waitForExistence(timeout: timeout))
        factoryButton.tap()

        XCTAssertTrue(app.staticTexts["Some Example Text"].waitForExistence(timeout: timeout),
                      "Beta module should appear (configured) when instantiated via factory")

        let back = app.buttons["BackButton"]
        XCTAssertTrue(back.waitForExistence(timeout: timeout))
        back.tap()

        XCTAssertTrue(factoryButton.waitForExistence(timeout: timeout),
                      "should return to the Alpha module after going back")
    }

    /// Swift flow: the "Show" button opens a Swift module via
    /// `openModuleUsingFactory(...).thenChainUsingBlock { ... }` and presents it.
    /// "Close" dismisses it via the Swift close path. Exercises the Swift
    /// ViperOpenModulePromise linking and present/close end to end.
    @MainActor
    func testSwiftShowModulePresentsAndCloses() {
        let app = XCUIApplication()
        app.launch()

        let swiftTab = app.buttons["Swift Only"]
        XCTAssertTrue(swiftTab.waitForExistence(timeout: timeout))
        swiftTab.tap()

        let showButton = app.buttons["Show"]
        XCTAssertTrue(showButton.waitForExistence(timeout: timeout))
        showButton.tap()

        XCTAssertTrue(app.staticTexts["Sample Label 0"].waitForExistence(timeout: timeout),
                      "Swift module should be presented after tapping Show")

        let close = app.buttons["Close"]
        XCTAssertTrue(close.waitForExistence(timeout: timeout))
        close.tap()

        XCTAssertTrue(showButton.waitForExistence(timeout: timeout),
                      "should return to the Swift root after closing the presented module")
    }
}
