//
//  AdBannerView.swift
//  Quiz
//
//  Google Mobile Ads のバナーを SwiftUI に埋め込むためのラッパー。
//

import SwiftUI
import GoogleMobileAds

/// バナー広告のユニットID（旧版から流用）。
enum AdUnit {
    static let homeBanner = "ca-app-pub-2853999389157478/2042602869"
}

/// 標準バナー（320×50）を表示する SwiftUI ビュー。
/// 読み込みの成否を `onLoaded` で通知するので、呼び出し側で領域の表示/非表示を制御できる。
struct AdBannerView: UIViewControllerRepresentable {
    let adUnitID: String
    var onLoaded: (Bool) -> Void = { _ in }

    func makeCoordinator() -> Coordinator {
        Coordinator(onLoaded: onLoaded)
    }

    func makeUIViewController(context: Context) -> BannerViewController {
        BannerViewController(adUnitID: adUnitID, delegate: context.coordinator)
    }

    func updateUIViewController(_ uiViewController: BannerViewController, context: Context) {
        context.coordinator.onLoaded = onLoaded
    }

    /// バナーの読み込み結果を SwiftUI 側へ橋渡しするデリゲート。
    final class Coordinator: NSObject, BannerViewDelegate {
        var onLoaded: (Bool) -> Void

        init(onLoaded: @escaping (Bool) -> Void) {
            self.onLoaded = onLoaded
        }

        func bannerViewDidReceiveAd(_ bannerView: BannerView) {
            onLoaded(true)
        }

        func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: any Error) {
            onLoaded(false)
        }
    }
}

/// バナーを保持し、自身を rootViewController として広告を読み込む。
final class BannerViewController: UIViewController {
    private let adUnitID: String
    private let bannerView = BannerView(adSize: AdSizeBanner)

    init(adUnitID: String, delegate: BannerViewDelegate?) {
        self.adUnitID = adUnitID
        super.init(nibName: nil, bundle: nil)
        bannerView.delegate = delegate
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        bannerView.adUnitID = adUnitID
        bannerView.rootViewController = self
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bannerView)
        NSLayoutConstraint.activate([
            bannerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            bannerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])

        bannerView.load(Request())
    }
}
