#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_root"

if ! command -v xcodegen >/dev/null 2>&1; then
  echo "XcodeGen fehlt. Installation: brew install xcodegen"
  exit 1
fi

"$project_root/Scripts/verify_tool_versions.sh"
xcodegen generate
swift package --package-path Packages/AppForgeKit resolve

echo "AppForge Pro ist vorbereitet. Öffne AppForgePro.xcodeproj in Xcode."
