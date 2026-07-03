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
struct AdBannerView: UIViewControllerRepresentable {
    let adUnitID: String

    func makeUIViewController(context: Context) -> BannerViewController {
        BannerViewController(adUnitID: adUnitID)
    }

    func updateUIViewController(_ uiViewController: BannerViewController, context: Context) {}
}

/// バナーを保持し、自身を rootViewController として広告を読み込む。
final class BannerViewController: UIViewController {
    private let adUnitID: String
    private let bannerView = BannerView(adSize: AdSizeBanner)

    init(adUnitID: String) {
        self.adUnitID = adUnitID
        super.init(nibName: nil, bundle: nil)
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
