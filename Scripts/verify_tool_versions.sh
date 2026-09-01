#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# shellcheck source=/dev/null
source "$project_root/Config/tool-versions.env"

verify_version() {
  local tool="$1"
  local expected="$2"
  local actual="$3"

  if [[ "$actual" != "$expected" ]]; then
    echo "$tool $actual ist installiert; erforderlich ist $expected."
    echo "Aktualisieren Sie die Werkzeuge gemäß docs/development/GETTING_STARTED.md."
    exit 1
  fi
}

verify_version "XcodeGen" "$XCODEGEN_VERSION" "$(xcodegen --version | awk '{print $NF}')"
verify_version "SwiftFormat" "$SWIFTFORMAT_VERSION" "$(swiftformat --version)"
verify_version "SwiftLint" "$SWIFTLINT_VERSION" "$(swiftlint version)"

echo "Toolversionen entsprechen Config/tool-versions.env."
