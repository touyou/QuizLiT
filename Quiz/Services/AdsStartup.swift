//
//  AdsStartup.swift
//  Quiz
//
//  広告 SDK を同意（UMP）と ATT の結果が出てから起動するための共有状態。
//

import GoogleMobileAds
import Observation

/// 広告 SDK の起動状態。バナーは `isStarted` になってから置く。
/// 起動前に `BannerView.load` を呼ぶと SDK が暗黙に起動し、ATT の回答前に広告リクエストが飛ぶ。
@MainActor
@Observable
final class AdsStartup {
    static let shared = AdsStartup()
    private init() {}

    private(set) var isStarted = false

    /// 同意が取れていれば起動する。同意の変更後にも呼ぶので何度呼んでもよい。
    func start() {
        guard !isStarted, ConsentManager.shared.canRequestAds else { return }
        MobileAds.shared.start(completionHandler: nil)
        isStarted = true
    }
}
