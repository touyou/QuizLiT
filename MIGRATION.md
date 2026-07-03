# iOS 26 / SwiftUI / Liquid Glass 移行メモ

旧 UIKit + Storyboard + CocoaPods 版から、SwiftUI + SPM + Liquid Glass の iOS 26 アプリへ全面刷新しました。

## 完了済み（コード側）

- **UIKit 一式を削除**: `AppDelegate.swift` / `ViewController.swift` / `QuizViewController.swift` / `ResultViewController.swift` / `Main.storyboard` / `LaunchScreen.storyboard`
- **CocoaPods を撤去**: `Podfile` / `Podfile.lock` / `Pods/` を削除
- **SwiftUI へ再実装**（`Quiz/` 配下）
  - `QuizApp.swift` … `@main App`。起動時に `MobileAds.shared.start()`
  - `Models/Question.swift` … `QuizCategory` / `Question`
  - `Models/QuizData.swift` … 全27問（旧版の設問をそのまま移植）
  - `Models/QuizSession.swift` … `@Observable` の進行状態
  - `Views/BackgroundView.swift` … `MeshGradient` 背景
  - `Views/HomeView.swift` … カテゴリ選択（Liquid Glass カード）
  - `Views/GameView.swift` / `QuizView.swift` / `ResultView.swift`
  - `Views/AdBannerView.swift` … AdMob バナーを `UIViewControllerRepresentable` で埋め込み
- **Liquid Glass**: `.glassEffect(_:in:)` / `.buttonStyle(.glass)` / `.glassProminent` / `GlassEffectContainer`
- **Info.plist**: Storyboard 参照・armv7 を削除、`UILaunchScreen` を追加、`GADApplicationIdentifier` と `SKAdNetworkItems` は維持

## 要対応（プロジェクトファイル＝手動）

`project.pbxproj` は Xcode 起動中の直接編集がクラッシュの原因になるため、こちらでは差し替えていません。以下を **Xcode を完全に終了した状態で** 実行してください。

新しい project.pbxproj は次を含みます:
- `objectVersion = 77`、`Quiz/` を `PBXFileSystemSynchronizedRootGroup` として同期（＝フォルダ内の Swift/アセットが自動でターゲットに入る）
- SPM 依存: `swift-package-manager-google-mobile-ads`（`GoogleMobileAds`、`from: 12.0.0`）
- Deployment Target `26.0`、CocoaPods のビルドフェーズ/xcconfig を全廃
- Bundle ID `com.dev.touyou.Quiz` / Team `B4S4333JDW` / Version `1.0.14` は維持

### 差し替え手順

```sh
cd /Users/touyou/Developer/Private/QuizLiT
# 1) Xcode を完全に終了する（⌘Q）
# 2) 新しいプロジェクトファイルを配置
mv NEW_project_pbxproj.txt Quiz.xcodeproj/project.pbxproj
# 3) CocoaPods 用ワークスペースは不要（今後は .xcodeproj を直接開く）
rm -rf Quiz.xcworkspace
# 4) プロジェクトを開く
open Quiz.xcodeproj
```

Xcode が開いたら **File > Packages > Resolve Package Versions** で Google Mobile Ads SDK を取得し、ビルドしてください。

差し替えが済んだら教えてください。ビルド → エラー修正まで続けて対応します（AdMob SDK v12 の Swift API 名など、実ビルドで微調整が要る場合があります）。
