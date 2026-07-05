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

        // まだ選択されていない場合のみダイアログを出す。
        // 既に選択済み(許可/拒否/制限)なら、そのまま広告 SDK を起動する。
        guard ATTrackingManager.trackingAuthorizationStatus == .notDetermined else {
            hasRequestedTracking = true
            MobileAds.shared.start(completionHandler: nil)
            return
        }

        hasRequestedTracking = true

        // scenePhase == .active は UIKit のアクティブ状態やウィンドウの前面化より
        // わずかに早く発火することがあり、その瞬間に requestTrackingAuthorization を
        // 呼ぶとダイアログが無音で抑制される。ウィンドウが確実に前面化してから呼ぶため、
        // 次のランループ以降まで待ってからリクエストする。
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 500_000_000)
            let status = await ATTrackingManager.requestTrackingAuthorization()
            _ = status
            MobileAds.shared.start(completionHandler: nil)
        }
    }
}
