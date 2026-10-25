//
//  ScreenshotFixture.swift
//  Quiz
//
//  App Store 用スクリーンショットの撮影モード。
//  QuizUITests の ScreenshotTests が `-uitest-screenshot-fixture` を付けて起動したときだけ有効になり、
//  撮るたびに同じ画面になるよう、広告・ATT ダイアログ・出題順のシャッフルなどを止める。
//  Release ビルドでは常に無効で、通常の起動には影響しない。
//

import Foundation

enum ScreenshotFixture {
    /// 撮影モードで起動しているか。
    static let isActive: Bool = {
        #if DEBUG
        ProcessInfo.processInfo.arguments.contains("-uitest-screenshot-fixture")
        #else
        false
        #endif
    }()
}
