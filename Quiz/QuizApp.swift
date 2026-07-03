//
//  QuizApp.swift
//  Quiz
//
//  SwiftUI ライフサイクルのエントリポイント。
//

import SwiftUI
import GoogleMobileAds

@main
struct QuizApp: App {
    init() {
        // Google Mobile Ads SDK を初期化する。
        MobileAds.shared.start(completionHandler: nil)
    }

    var body: some Scene {
        WindowGroup {
            HomeView()
        }
    }
}
