#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_root"

if ! command -v mint >/dev/null 2>&1; then
  echo "Mint fehlt. Installation: brew install mint"
  exit 1
fi

mint bootstrap
mint run swiftformat App Features Packages Tests --lint
mint run swiftlint lint --strict
swift test --package-path Packages/AppForgeKit -Xswiftc -warnings-as-errors
mint run xcodegen generate
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
