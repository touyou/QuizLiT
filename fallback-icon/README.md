# アイコンのフォールバック（アセットカタログ 1024）

Icon Composer の `AppIcon.icon` は **Xcode 27 系の actool** でないとコンパイルできず、
Xcode Cloud が **リリース版 Xcode（26.x）** でビルドすると actool がクラッシュする。

一般公開（App Store 審査）はベータ Xcode では出せないため、**リリース版 26.x でビルドする間だけ**、
`.icon` の代わりにこのアセットカタログ版アイコンへ切り替える。Xcode 27 が正式版になったら
`.icon` に戻せばよい（Liquid Glass のフル表現が使える）。

なお iOS 26+ ではアセットカタログのアイコンにも Liquid Glass が自動適用されるため、見た目は十分モダン。

## 中身
- `AppIcon.appiconset/AppIcon-1024.png` … 1024x1024・**透過なし**（App Store 要件）。`icon.png` を背景色でフラット化して生成。
- `AppIcon.appiconset/Contents.json` … モダンな単一サイズ（iOS / universal）形式。

このディレクトリは `Quiz/`（同期グループ）の外・pbxproj 未参照なので、**置いてあるだけではビルドに影響しない**。

## 切り替え手順（リリース版 Xcode でビルドする時）
1. Xcode で `AppIcon.icon` を削除（右クリック → Delete → **Move to Trash**）。
   これで pbxproj の参照も綺麗に消える。
2. `fallback-icon/apply-fallback.sh` を実行（`AppIcon.appiconset` を `Quiz/Assets.xcassets/` へコピー）。
   ビルド設定 `ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon` は変更不要。
3. ビルド → コミット → push。

## 元に戻す（Xcode 27 が正式版になったら）
1. `Quiz/Assets.xcassets/AppIcon.appiconset` を削除。
2. `AppIcon.icon` をプロジェクトに追加し直す（General → App Icon = `AppIcon`）。
