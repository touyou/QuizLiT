//
//  ScreenshotTests.swift
//  QuizUITests
//
//  App Store 提出用のスクリーンショットを撮る。挙動のテストではなく、各画面まで操作して画像を添付するだけ。
//  `scripts/capture_screenshots.sh` が端末・言語ごとに実行し、添付を取り出す。
//

import XCTest

final class ScreenshotTests: XCTestCase {
    // setUpWithError() で作る XCTest のフィクスチャ。
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        // 広告・ATT ダイアログ・出題順のシャッフルを止める撮影モード（Quiz/Debug/ScreenshotFixture.swift）。
        // 言語は -AppleLanguages ではなく xcodebuild の -testLanguage で切り替える。
        app.launchArguments = ["-uitest-screenshot-fixture"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Capture

    /// スクリプトが並べ替えられる名前で画面全体を添付する。
    private func capture(_ name: String) {
        // 端末のフレームバッファそのもの。App Store Connect が求めるピクセルサイズになる。
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        // 成功したテストの添付は既定で捨てられるため、残すよう指定する。
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    /// アニメーション（選択の枠線、結果のアイコンの bounce など）が落ち着くのを待つ。
    private func settle() {
        Thread.sleep(forTimeInterval: 1.5)
    }

    // MARK: - Screens

    @MainActor
    func testCaptureScreenshots() throws {
        // 1. ホーム。ジャンルを 2 つ選んだ状態。
        let basic = app.buttons["category-basic"]
        XCTAssertTrue(basic.waitForExistence(timeout: 30), "ホームにジャンルのカードが出ていない")
        basic.tap()
        app.buttons["category-algorithm"].tap()
        settle()
        capture("01-home")

        // 2. 出題画面。回答前。
        let startButton = app.buttons["startButton"]
        if !startButton.isHittable {
            app.swipeUp()
        }
        startButton.tap()
        let correctChoice = app.buttons["choice-correct"]
        XCTAssertTrue(correctChoice.waitForExistence(timeout: 10), "出題画面が開いていない")
        settle()
        capture("02-question")

        // 3. 正解を選んだあと。正解の選択肢が緑になり「次の問題へ」が出る。
        correctChoice.tap()
        let nextButton = app.buttons["nextButton"]
        XCTAssertTrue(nextButton.waitForExistence(timeout: 10), "回答後に次へのボタンが出ていない")
        settle()
        capture("03-answered")

        // 4. 結果画面。残りもすべて正解して満点にする。
        nextButton.tap()
        let resultTitle = app.staticTexts["resultTitle"]
        for _ in 0..<50 where !resultTitle.exists {
            XCTAssertTrue(correctChoice.waitForExistence(timeout: 10), "次の問題が出ていない")
            correctChoice.tap()
            XCTAssertTrue(nextButton.waitForExistence(timeout: 10), "回答後に次へのボタンが出ていない")
            nextButton.tap()
        }
        XCTAssertTrue(resultTitle.waitForExistence(timeout: 10), "結果画面が開いていない")
        settle()
        capture("04-result")
    }
}
