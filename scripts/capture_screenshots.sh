#!/bin/bash
#
# App Store 提出用のスクリーンショットを、端末と言語の組み合わせごとに撮る。
#
#   ./scripts/capture_screenshots.sh                 # すべて
#   ./scripts/capture_screenshots.sh iphone ipad     # 指定した端末だけ
#   LOCALES="ja" ./scripts/capture_screenshots.sh    # 指定した言語だけ
#
# 出力先は Screenshots/<platform>/<locale>/NN-name.png（gitignore 済み）。
#
# QuizUITests/ScreenshotTests が `-uitest-screenshot-fixture` 付きでアプリを起動して各画面まで操作し、
# `XCUIScreen.main.screenshot()` を添付する。xcresult からその添付を取り出して並べる。
#
# 端末は名前と OS で指定しているが、環境変数で差し替えられる。ほかの作業と共有のシミュレータを
# 避けたいときは、複製した端末の id を渡す。
#
#   IPHONE_DEST="platform=iOS Simulator,id=<udid>" ./scripts/capture_screenshots.sh iphone
#
# iPhone Duo は iOS 27.1 のシミュレータにしかない。

set -euo pipefail

cd "$(dirname "$0")/.."
ROOT="$PWD"
OUT="$ROOT/Screenshots"
WORK="${SCREENSHOT_WORK_DIR:-$ROOT/.screenshot-runs}"
# アプリは日本語のみ（developmentRegion = ja、ほかのローカライズ無し）。
LOCALES="${LOCALES:-ja}"

SCHEME="Quiz"
TEST_ID="QuizUITests/ScreenshotTests"

IPHONE_DEST="${IPHONE_DEST:-platform=iOS Simulator,name=iPhone 17 Pro Max,OS=27.0}"
IPAD_DEST="${IPAD_DEST:-platform=iOS Simulator,name=iPad Pro 13-inch (M5),OS=27.0}"
DUO_DEST="${DUO_DEST:-platform=iOS Simulator,name=iPhone Duo,OS=27.1}"

# platform | destination
PLATFORMS=(
  "iphone|$IPHONE_DEST"
  "ipad|$IPAD_DEST"
  "duo|$DUO_DEST"
)

requested=("$@")
failed=()

wanted() {
  [ ${#requested[@]} -eq 0 ] && return 0
  for name in "${requested[@]}"; do
    [ "$name" = "$1" ] && return 0
  done
  return 1
}

region_for() {
  case "$1" in
    ja) echo JP ;;
    *)  echo US ;;
  esac
}

mkdir -p "$WORK"

# destination から端末の UDID を引く。id= ならそのまま、name=/OS= なら該当する OS のセクションから探す。
udid_for() {
  local destination=$1 name os
  if [[ "$destination" =~ id=([0-9A-Fa-f-]{36}) ]]; then
    echo "${BASH_REMATCH[1]}"
    return
  fi
  name=$(sed -nE 's/.*name=([^,]+).*/\1/p' <<< "$destination")
  os=$(sed -nE 's/.*OS=([^,]+).*/\1/p' <<< "$destination")
  xcrun simctl list devices available \
    | awk -v os="-- iOS $os --" -v name="    $name (" '$0 == os {f=1; next} /^-- /{f=0} f && index($0, name) == 1' \
    | head -1 | sed -E 's/.*\(([0-9A-F-]{36})\).*/\1/'
}

# ステータスバーを 9:41・電波と電池が満タンに固定する。XCTest も時刻を差し替えるが、
# iPhone Duo の縦のバーには効かず実際の時刻が写るため、simctl で端末ごと上書きする。
override_status_bar() {
  local udid
  udid=$(udid_for "$1")
  [ -n "$udid" ] || return 0
  xcrun simctl boot "$udid" 2>/dev/null || true
  xcrun simctl bootstatus "$udid" -b > /dev/null
  xcrun simctl status_bar "$udid" override \
    --time "9:41" --dataNetwork wifi --wifiMode active --wifiBars 3 \
    --cellularMode active --cellularBars 4 --batteryState charged --batteryLevel 100
}

capture() {
  local platform=$1 destination=$2 locale=$3
  local bundle="$WORK/$platform-$locale.xcresult"
  local log="$WORK/$platform-$locale.log"
  rm -rf "$bundle"

  override_status_bar "$destination"

  # 言語は -AppleLanguages の起動引数ではなく -testLanguage / -testRegion で切り替える。
  # こちらはテスト対象アプリの Locale.current まで動く。
  if ! xcodebuild test \
    -project Quiz.xcodeproj \
    -scheme "$SCHEME" \
    -destination "$destination" \
    -only-testing:"$TEST_ID" \
    -resultBundlePath "$bundle" \
    -testLanguage "$locale" \
    -testRegion "$(region_for "$locale")" \
    > "$log" 2>&1; then
    echo "    FAILED — see $log"
    failed+=("$platform/$locale")
    return
  fi

  local dest="$OUT/$platform/$locale"
  rm -rf "$dest" && mkdir -p "$dest"

  local staging="$WORK/$platform-$locale-attachments"
  rm -rf "$staging"
  xcrun xcresulttool export attachments --path "$bundle" --output-path "$staging" > /dev/null

  # 書き出されたファイル名は意味を持たないため、manifest.json でテストが付けた名前に戻す。
  if ! python3 - "$staging" "$dest" <<'PY'
import json, pathlib, re, shutil, sys

staging, dest = (pathlib.Path(p) for p in sys.argv[1:3])
manifest = json.loads((staging / "manifest.json").read_text())

# XCTest は添付名の後ろに "_<index>_<uuid>" を付ける。
SUFFIX = re.compile(r"_\d+_[0-9A-Fa-f-]{36}$")

count = 0
for test in manifest:
    for attachment in test.get("attachments", []):
        exported = attachment.get("exportedFileName")
        name = attachment.get("suggestedHumanReadableName") or exported
        if not exported:
            continue
        stem = SUFFIX.sub("", pathlib.Path(name).stem)
        shutil.copyfile(staging / exported, dest / f"{stem}.png")
        count += 1

if count == 0:
    sys.exit("no attachments in the result bundle")
print(f"    {count} screenshot(s) -> {dest}")
PY
  then
    echo "    FAILED — no screenshots extracted from $bundle"
    failed+=("$platform/$locale")
  fi
}

for entry in "${PLATFORMS[@]}"; do
  IFS='|' read -r platform destination <<< "$entry"
  wanted "$platform" || continue
  for locale in $LOCALES; do
    echo "==> $platform / $locale"
    capture "$platform" "$destination" "$locale"
  done
done

echo
echo "=== sizes ==="
if [ -d "$OUT" ]; then
  find "$OUT" -name "*.png" | sort | while read -r png; do
    size=$(sips -g pixelWidth -g pixelHeight "$png" | awk '/pixelWidth/ {w=$2} /pixelHeight/ {h=$2} END {print w"x"h}')
    printf '%-40s %s\n' "${png#"$OUT"/}" "$size"
  done
fi

echo
if [ ${#failed[@]} -gt 0 ]; then
  echo "FAILED: ${failed[*]}"
  echo "Logs are in $WORK"
  exit 1
fi
echo "All captures succeeded. Open with: open $OUT"
