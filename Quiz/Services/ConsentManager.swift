//
//  ConsentManager.swift
//  Quiz
//
//  Google User Messaging Platform (UMP) のラッパー。EEA・英国などで必要な広告の同意フォーム
//  （中身は AdMob の「プライバシーとメッセージ」で作る）を起動時に出し、
//  ホーム画面から同意を変えられるようにする。同意が取れるまで広告 SDK を起動しない。
//

import Observation
import UIKit
import UserMessagingPlatform
import os

@MainActor
@Observable
final class ConsentManager {
    static let shared = ConsentManager()
    private init() {}

    /// 広告をリクエストしてよい状態か（同意済み、または同意が不要な地域）。
    private(set) var canRequestAds = false

    /// 同意を変えるボタンを出す必要があるか。
    private(set) var isPrivacyOptionsRequired = false

    /// 同意情報を更新し、必要なら同意フォームを出す。失敗しても前回までの同意状況で判定する。
    func gatherConsent() async {
        let parameters = RequestParameters()
        #if DEBUG
        // 起動引数 `-umpDebugEEA` で EEA からのアクセスとして振る舞わせる（フォームの確認用）。
        if ProcessInfo.processInfo.arguments.contains("-umpDebugEEA") {
            let debugSettings = DebugSettings()
            debugSettings.geography = .EEA
            parameters.debugSettings = debugSettings
        }
        #endif

        do {
            try await ConsentInformation.shared.requestConsentInfoUpdate(with: parameters)
            try await ConsentForm.loadAndPresentIfRequired(from: Self.topViewController())
        } catch {
            Self.logger.error("consent: \(error.localizedDescription, privacy: .public)")
        }
        refresh()
    }

    /// 同意の変更・撤回のフォームを出す。
    func presentPrivacyOptionsForm() async {
        do {
            try await ConsentForm.presentPrivacyOptionsForm(from: Self.topViewController())
        } catch {
            Self.logger.error("privacy options: \(error.localizedDescription, privacy: .public)")
        }
        refresh()
    }

    private func refresh() {
        canRequestAds = ConsentInformation.shared.canRequestAds
        isPrivacyOptionsRequired = ConsentInformation.shared.privacyOptionsRequirementStatus == .required
    }

    private static let logger = Logger(subsystem: "Quiz", category: "Ads")

    private static func topViewController() -> UIViewController? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let scene = scenes.first { $0.activationState == .foregroundActive } ?? scenes.first
        var top = scene?.keyWindow?.rootViewController
        while let presented = top?.presentedViewController {
            top = presented
        }
        return top
    }
}
