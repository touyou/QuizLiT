#!/bin/sh

#  ci_pre_xcodebuild.sh
#  Xcode Cloud が xcodebuild を実行する直前に走らせるスクリプト。
#  TestFlight 用にビルド番号（CFBundleVersion = CURRENT_PROJECT_VERSION）を
#  Xcode Cloud が採番する CI_BUILD_NUMBER で上書きし、毎ビルド一意にする。

set -e

if [ -z "$CI_BUILD_NUMBER" ]; then
    echo "CI_BUILD_NUMBER is not set; skipping build number injection."
    exit 0
fi

PBXPROJ="$CI_PRIMARY_REPOSITORY_PATH/Quiz.xcodeproj/project.pbxproj"

if [ ! -f "$PBXPROJ" ]; then
    echo "warning: project.pbxproj not found at $PBXPROJ; skipping."
    exit 0
fi

# 全ビルド構成の CURRENT_PROJECT_VERSION を CI_BUILD_NUMBER に置換する。
sed -i '' "s/CURRENT_PROJECT_VERSION = [^;]*;/CURRENT_PROJECT_VERSION = $CI_BUILD_NUMBER;/g" "$PBXPROJ"

echo "Set CURRENT_PROJECT_VERSION to $CI_BUILD_NUMBER"
