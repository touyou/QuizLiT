//
//  QuizApp.swift
//  Quiz
//
//  SwiftUI ライフサイクルのエントリポイント。
//

import SwiftUI
import AppIntents
import AppTrackingTransparency

@main
struct QuizApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @State private var hasRequestedTracking = false

    init() {
        // カテゴリ名入りのフレーズ（「〜で知識編のクイズを始める」）を Siri に覚えてもらう。
        QuizShortcuts.updateAppShortcutParameters()
        WhatsNew.prepareOnLaunch()
        ReviewPrompt.recordLaunch()
    }

    var body: some Scene {
        WindowGroup {
            HomeView()
                .whatsNewOnUpdate()
        }
        .onChange(of: scenePhase, initial: true) { _, phase in
            // ATT の許可ダイアログはアプリが前面(active)のときのみ表示できる。
            guard phase == .active else { return }
            requestTrackingThenStartAds()
        }
    }

    /// 広告の同意（EEA・英国など）→ トラッキング許可の順に聞き、その結果を受けてから広告 SDK を初期化する。
    /// ATT の許可の有無に関わらず広告は表示され、拒否時は IDFA を使わない非パーソナライズ広告になる。
    private func requestTrackingThenStartAds() {
        guard !hasRequestedTracking else { return }
        // スクリーンショット撮影中は同意・許可のダイアログも広告も出さない。
        guard !ScreenshotFixture.isActive else { return }
        hasRequestedTracking = true

        Task { @MainActor in
            // scenePhase == .active は UIKit のアクティブ状態やウィンドウの前面化より
            // わずかに早く発火することがあり、その瞬間にダイアログを出すと無音で抑制される。
            // ウィンドウが確実に前面化してから出すため、少し待つ。
            try? await Task.sleep(nanoseconds: 500_000_000)
            // Google の推奨どおり、同意フォーム（必要な地域だけ）を ATT より先に出す。
            await ConsentManager.shared.gatherConsent()

            if ATTrackingManager.trackingAuthorizationStatus == .notDetermined {
                let status = await ATTrackingManager.requestTrackingAuthorization()
                // ダイアログが出ずに閉じると未選択のまま返る。広告は起動せず、次に前面へ来たとき聞き直す。
                guard status != .notDetermined else {
                    hasRequestedTracking = false
                    return
                }
            }
            AdsStartup.shared.start()
            // 同意情報を取れなかった（通信できない等）ときは、次に前面へ来たとき聞き直す。
            if !ConsentManager.shared.canRequestAds {
                hasRequestedTracking = false
            }
        }
    }
}
