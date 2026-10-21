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
#
# iPhone Duo は閉じた状態（外側の画面、縦 1398x2034）と開いた状態（内側の画面、横 2853x2007）を
# 撮り分ける。開閉はシミュレータのコマンドからは切り替えられず、DeviceHub でデバイスの下にある
# ボタンを押すしかない。なので撮る前に今の状態を確かめ、合っていなければ止める:
#
#   duo-closed  閉じた Duo で撮る（起動し直した直後は閉じている）
#   duo-open    DeviceHub で開いてから撮る
#
# 開いた状態ではテストが内側の画面を撮る（`SCREENSHOT_DUO_OPEN`）。内側のフレームバッファは
# 縦長のままなので、ここで時計回りに 90° 回して 2853x2007 に揃える。

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
DUO_OPEN_SIZE="2853x2007"
# 閉じているときの内側の画面（まっ黒）の PNG はこれより小さい。
DUO_INNER_BLANK_MAX_BYTES=1000000

# platform | destination
PLATFORMS=(
  "iphone|$IPHONE_DEST"
  "ipad|$IPAD_DEST"
  "duo-closed|$DUO_DEST"
  "duo-open|$DUO_DEST"
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

pixel_size() {
  sips -g pixelWidth -g pixelHeight "$1" | awk '/pixelWidth/ {w=$2} /pixelHeight/ {h=$2} END {print w"x"h}'
}

# Duo が期待した開閉状態か。内側の画面に何か映っているかで見分ける。
check_duo_state() {
  local platform=$1 destination=$2 udid shot bytes state
  udid=$(udid_for "$destination")
  if [ -z "$udid" ]; then
    echo "    FAILED — iPhone Duo のシミュレータが見つからない（$destination）"
    return 1
  fi
  xcrun simctl boot "$udid" 2>/dev/null || true
  xcrun simctl bootstatus "$udid" -b > /dev/null 2>&1 || true
  # 内側の画面は閉じている間まっ黒なので、PNG にすると 100KB ほどに縮む（中身があると数 MB になる）。
  # 既定の画面のサイズでは見分けられない（開いていても外側を横向きで返すことがある）。
  shot="$WORK/duo-inner.png"
  xcrun simctl io "$udid" screenshot --display=primary-1 "$shot" > /dev/null 2>&1
  bytes=$(stat -f%z "$shot" 2>/dev/null || echo 0)
  state=closed
  [ "$bytes" -gt "$DUO_INNER_BLANK_MAX_BYTES" ] && state=open
  case "$platform" in
    duo-open)
      if [ "$state" != open ]; then
        echo "    FAILED — Duo が閉じている。DeviceHub でデバイスの下のボタンを押して開いてから撮り直す"
        return 1
      fi ;;
    duo-closed)
      if [ "$state" != closed ]; then
        echo "    FAILED — Duo が開いている。DeviceHub で閉じるか、シミュレータを起動し直してから撮り直す"
        return 1
      fi ;;
  esac
  return 0
}

# 開いた Duo の内側の画面は縦長のフレームバッファで返るので、横向きに回して 2853x2007 に揃える。
# XCUIScreen の画像は 1px 小さい（2006x2852）ので、最後に指定のサイズへ合わせる。
normalize_duo_open() {
  local dest=$1 png size w h
  for png in "$dest"/*.png; do
    size=$(pixel_size "$png")
    w=${size%x*}; h=${size#*x}
    if [ "$w" -lt "$h" ]; then
      sips -r 90 "$png" > /dev/null
    fi
    if [ "$(pixel_size "$png")" != "$DUO_OPEN_SIZE" ]; then
      sips -z "${DUO_OPEN_SIZE#*x}" "${DUO_OPEN_SIZE%x*}" "$png" > /dev/null
    fi
  done
  echo "    normalized to $DUO_OPEN_SIZE"
}

capture() {
  local platform=$1 destination=$2 locale=$3
  local bundle="$WORK/$platform-$locale.xcresult"
  local log="$WORK/$platform-$locale.log"
  rm -rf "$bundle"

  override_status_bar "$destination"

  # 言語は -AppleLanguages の起動引数ではなく -testLanguage / -testRegion で切り替える。
  # こちらはテスト対象アプリの Locale.current まで動く。
  case "$platform" in
    duo-*)
      if ! check_duo_state "$platform" "$destination"; then
        failed+=("$platform/$locale")
        return
      fi ;;
  esac

  # 開いた Duo のときだけ、テストに内側の画面を撮らせる（TEST_RUNNER_ を外した名前でテストに届く）。
  local duo_open=0
  if [ "$platform" = "duo-open" ]; then
    duo_open=1
  fi

  if ! TEST_RUNNER_SCREENSHOT_DUO_OPEN=$duo_open xcodebuild test \
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
    return
  fi

  if [ "$platform" = "duo-open" ]; then
    normalize_duo_open "$dest"
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
