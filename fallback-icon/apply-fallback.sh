#!/bin/sh

# Icon Composer (.icon) → アセットカタログ 1024 アイコンへの切り替えを補助する。
# 事前に Xcode で AppIcon.icon を削除（Move to Trash）しておくこと。

set -e

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT/fallback-icon/AppIcon.appiconset"
DEST="$ROOT/Quiz/Assets.xcassets/AppIcon.appiconset"

if [ ! -d "$SRC" ]; then
    echo "error: $SRC が見つかりません。"; exit 1
fi

rm -rf "$DEST"
cp -R "$SRC" "$DEST"
echo "コピー完了: $DEST"

if [ -e "$ROOT/AppIcon.icon" ]; then
    echo ""
    echo "注意: リポジトリ直下に AppIcon.icon がまだあります。"
    echo "Xcode で参照を削除（Move to Trash）してから、必要なら残ファイルも削除してください。"
    echo "その後 project.pbxproj から AppIcon.icon 参照が消えていることを確認してください。"
fi

echo ""
echo "次: ビルド確認 → コミット → push"
