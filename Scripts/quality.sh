#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_root"

required_tools=(xcodegen swiftformat swiftlint)
for tool in "${required_tools[@]}"; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "$tool fehlt. Installation: brew install $tool"
    exit 1
  fi
done

"$project_root/Scripts/verify_tool_versions.sh"

swiftformat App Features Packages Tests --lint
swiftlint lint --strict
swift test --package-path Packages/AppForgeKit -Xswiftc -warnings-as-errors
xcodegen generate
git diff --exit-code -- AppForgePro.xcodeproj
xcodebuild \
  -project AppForgePro.xcodeproj \
  -scheme AppForgePro \
  -destination 'platform=macOS' \
  -derivedDataPath .build/xcode-derived \
  CODE_SIGNING_ALLOWED=NO \
  SWIFT_TREAT_WARNINGS_AS_ERRORS=YES \
  test

echo "AppForge Pro quality gate erfolgreich."
