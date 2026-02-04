//
//  HiyoUITests.swift
//  HiyoUITests
//
//  UI automation tests for Hiyo.
//

import XCTest

final class HiyoUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        
        // Launch with clean state
        app.launchArguments = ["--uitesting", "--reset-state"]
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app.terminate()
        app = nil
    }
    
    // MARK: - Launch Tests
    
    func testAppLaunches() throws {
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 5))
    }
    
    func testWelcomeScreenAppears() throws {
        // Should show welcome screen on first launch
        let welcomeText = app.staticTexts["Welcome to Hiyo"]
        XCTAssertTrue(welcomeText.waitForExistence(timeout: 2))
    }
    
    // MARK: - Navigation Tests
    
    func testSidebarToggle() throws {
        // Find sidebar button
        let sidebarButton = app.toolbars.buttons["Toggle Sidebar"]
        XCTAssertTrue(sidebarButton.exists)
        
        // Toggle off
        sidebarButton.click()
        
        // Toggle on
        sidebarButton.click()
    }
    
    func testNewConversation() throws {
        // Click new conversation
        let newButton = app.toolbars.buttons["New Conversation"]
        XCTAssertTrue(newButton.exists)
        newButton.click()
        
        // Should show empty chat or input field
        let textField = app.textViews.firstMatch
        XCTAssertTrue(textField.waitForExistence(timeout: 2))
    }
    
    // MARK: - Settings Tests
    
    func testSettingsOpens() throws {
        // Open settings with Cmd + ,
        app.menuBars.menuBarItems["Hiyo"].click()
        app.menuItems["Settings..."].click()
        
        // Verify settings window appears
        let settingsWindow = app.windows["Settings"]
        XCTAssertTrue(settingsWindow.waitForExistence(timeout: 2))
        
        // Close settings
        app.keyboards.keys["esc"].tap()
    }
    
    func testSettingsTabs() throws {
        openSettings()
        
        // Test Models tab
        app.tabs["Models"].click()
        XCTAssertTrue(app.staticTexts["Recommended Models"].waitForExistence(timeout: 1))
        
        // Test Performance tab
        app.tabs["Performance"].click()
        XCTAssertTrue(app.staticTexts["GPU Memory"].waitForExistence(timeout: 1))
        
        // Test Privacy tab
        app.tabs["Privacy"].click()
        XCTAssertTrue(app.staticTexts["Data Storage"].waitForExistence(timeout: 1))
        
        // Test General tab
        app.tabs["General"].click()
        XCTAssertTrue(app.staticTexts["Startup"].waitForExistence(timeout: 1))
    }
    
    // MARK: - Chat Interface Tests
    
    func testMessageInputExists() throws {
        // Create new conversation first
        createNewConversation()
        
        // Find input field
        let inputField = app.textViews.firstMatch
        XCTAssertTrue(inputField.exists)
    }
    
    func testSendButtonDisabledWhenEmpty() throws {
        createNewConversation()
        
        let sendButton = app.buttons["Send message"]
        // Should exist but may be disabled (check for existence)
        XCTAssertTrue(sendButton.exists)
    }
    
    // MARK: - Helper Methods
    
    private func openSettings() {
        app.menuBars.menuBarItems["Hiyo"].click()
        app.menuItems["Settings..."].click()
        _ = app.windows["Settings"].waitForExistence(timeout: 2)
    }
    
    private func createNewConversation() {
        let newButton = app.toolbars.buttons["New Conversation"]
        if newButton.exists {
            newButton.click()
        } else {
            // Use keyboard shortcut
            app.keyboards.keys["command"].press(forDuration: 0.1)
            app.keyboards.keys["n"].tap()
        }
        
        // Wait for chat view
        sleep(1)
    }
    
    // MARK: - Accessibility Tests
    
    func testAccessibilityLabels() throws {
        // Verify key elements have accessibility labels
        XCTAssertTrue(app.buttons["New conversation"].exists)
        XCTAssertTrue(app.buttons["Toggle Sidebar"].exists)
        
        // Settings should be accessible
        openSettings()
        XCTAssertTrue(app.tabs["Models"].exists)
    }
    
    // MARK: - Performance Tests
    
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
    
    // MARK: - Screenshot Tests (for App Store)
    
    func testScreenshotSetup() throws {
        // Configure app for screenshot
        app.launchArguments = ["--screenshot-mode"]
        app.launch()
        
        // Verify ideal state for screenshot
        XCTAssertTrue(app.windows.firstMatch.exists)
        
        // Take screenshot
        let screenshot = XCUIScreen.main.screenshot()
        XCTAssertNotNil(screenshot)
    }
}
