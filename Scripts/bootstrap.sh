#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_root"

if ! command -v mint >/dev/null 2>&1; then
  echo "Mint fehlt. Installation: brew install mint"
  exit 1
fi

mint bootstrap
mint run xcodegen generate
swift package --package-path Packages/AppForgeKit resolve

echo "AppForge Pro ist vorbereitet. Öffne AppForgePro.xcodeproj in Xcode."
