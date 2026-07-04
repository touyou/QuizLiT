//
//  QuizApp.swift
//  Quiz
//
//  SwiftUI ライフサイクルのエントリポイント。
//

import SwiftUI
import GoogleMobileAds
import AppTrackingTransparency

@main
struct QuizApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @State private var hasRequestedTracking = false

    var body: some Scene {
        WindowGroup {
            HomeView()
        }
        .onChange(of: scenePhase) { _, phase in
            // ATT の許可ダイアログはアプリが前面(active)のときのみ表示できる。
            guard phase == .active else { return }
            requestTrackingThenStartAds()
        }
    }

    /// トラッキング許可をユーザーに求め、その結果を受けてから広告 SDK を初期化する。
    /// 許可の有無に関わらず広告は表示され、拒否時は IDFA を使わない非パーソナライズ広告になる。
    private func requestTrackingThenStartAds() {
        guard !hasRequestedTracking else { return }
        hasRequestedTracking = true

        ATTrackingManager.requestTrackingAuthorization { _ in
            MobileAds.shared.start(completionHandler: nil)
        }
    }
}
