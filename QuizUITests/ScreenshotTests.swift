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

    /// iPhone Duo を開いた状態で撮るとき、スクリプトが `TEST_RUNNER_SCREENSHOT_DUO_OPEN=1` で立てる。
    private let isDuoOpen = ProcessInfo.processInfo.environment["SCREENSHOT_DUO_OPEN"] == "1"

    override func setUpWithError() throws {
        continueAfterFailure = false
        // 開いた Duo は横向きで撮る。向きはスクリプト側の回転（時計回り 90°）と対になっている。
        if isDuoOpen {
            XCUIDevice.shared.orientation = .landscapeLeft
        }
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

    /// 撮る画面。ふだんは `XCUIScreen.main`。
    ///
    /// iPhone Duo は外側と内側の 2 枚の画面を持ち、`XCUIScreen.main` は開いていても外側を返す。
    /// 開いた状態では画素数がいちばん大きい画面（内側）を撮る。内側のフレームバッファは縦長のままなので、
    /// 横向きへの回転とサイズ合わせはスクリプトが行う。
    private func screenToCapture() -> XCUIScreen {
        guard isDuoOpen else { return XCUIScreen.main }
        func pixels(_ screen: XCUIScreen) -> CGFloat {
            let size = screen.screenshot().image.size
            return size.width * size.height
        }
        return XCUIScreen.screens.max { pixels($0) < pixels($1) } ?? XCUIScreen.main
    }

    /// スクリプトが並べ替えられる名前で画面全体を添付する。
    private func capture(_ name: String) {
        // 端末のフレームバッファそのもの。App Store Connect が求めるピクセルサイズになる。
        let attachment = XCTAttachment(screenshot: screenToCapture().screenshot())
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
