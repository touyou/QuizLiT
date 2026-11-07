//
//  QuizIntentTests.swift
//  QuizUITests
//
//  Siri / ショートカットが呼ぶのと同じ App Intent を AppIntentsTesting で実行し、出題画面まで進むかを確かめる。
//  AppIntentsTesting は動いているアプリのプロセスで Intent を実行するため、UI テストのバンドルに置く。
//  署名なし（CODE_SIGNING_ALLOWED=NO）で `test` すると全件が Code=803 で失敗する。Xcode か署名ありで実行する。
//

import AppIntentsTesting
import XCTest

@available(iOS 27.0, *)
final class QuizIntentTests: XCTestCase {
    private var app: XCUIApplication!
    private var definitions: IntentDefinitions!

    @MainActor override func setUp() async throws {
        continueAfterFailure = false
        app = XCUIApplication()
        // 広告・ATT ダイアログを止め、正解の選択肢に印が付く撮影モードで起動する（Quiz/Debug/ScreenshotFixture.swift）。
        // 各テストをホーム画面から始めるため、毎回起動し直す。
        app.launchArguments = ["-uitest-screenshot-fixture"]
        app.launch()
        definitions = IntentDefinitions(bundleIdentifier: "com.dev.touyou.Quiz")
    }

    /// 「〜で知識編のクイズを始める」と同じ Intent。
    @MainActor func testStartCategoryQuizShowsFirstQuestion() async throws {
        let category = definitions.enums["QuizCategory"].makeCase("basic")
        _ = try await runWhenMetadataIsReady(
            definitions.intents["StartCategoryQuizIntent"].makeIntent(category: category)
        )
        XCTAssertTrue(app.buttons["choice-correct"].waitForExistence(timeout: 10),
                      "StartCategoryQuizIntent を実行しても出題画面が開かない")
    }

    /// ホームのスタートボタン・「全カテゴリで出題」のショートカットと同じ Intent。
    @MainActor func testStartMixedQuizShowsFirstQuestion() async throws {
        let categoryEnum = definitions.enums["QuizCategory"]
        let categories = [categoryEnum.makeCase("basic"), categoryEnum.makeCase("algorithm")]
        _ = try await runWhenMetadataIsReady(
            definitions.intents["StartMixedQuizIntent"].makeIntent(categories: categories)
        )
        XCTAssertTrue(app.buttons["choice-correct"].waitForExistence(timeout: 10),
                      "StartMixedQuizIntent を実行しても出題画面が開かない")
    }

    // MARK: - Helpers

    /// クリーンビルド直後はメタデータの登録が間に合わず `Code=400 "… is not present"` で失敗するので、
    /// 登録されるまで待ってから 1 回だけ実行する。署名の設定ミス（SecurityErrorDomain）は待っても直らないので即失敗にする。
    private func runWhenMetadataIsReady(
        _ intent: AnyAppIntent,
        timeout: TimeInterval = 20
    ) async throws -> ResolvedIntentResult {
        let deadline = Date().addingTimeInterval(timeout)
        while true {
            do {
                return try await intent.run()
            } catch let error as NSError where error.domain.hasSuffix("MetadataErrorDomain") && Date() < deadline {
                try await Task.sleep(for: .milliseconds(500))
            }
        }
    }
}
