#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tools_root="$project_root/.build/ci-tools"
mkdir -p "$tools_root"

install_release_tool() {
  local tool_name="$1"
  local binary_name="$2"
  local url="$3"
  local expected_sha256="$4"

  local archive="$tools_root/${tool_name}.zip"
  local destination="$tools_root/${tool_name}"

  rm -rf "$destination"
  mkdir -p "$destination"

  echo "Installiere ${tool_name} aus versioniertem Release-Artefakt …"
  curl --fail --location --silent --show-error "$url" --output "$archive"

  local actual_sha256
  actual_sha256="$(shasum -a 256 "$archive" | awk '{print $1}')"
  if [[ "$actual_sha256" != "$expected_sha256" ]]; then
    echo "SHA-256-Prüfung für ${tool_name} fehlgeschlagen." >&2
    echo "Erwartet: $expected_sha256" >&2
    echo "Erhalten: $actual_sha256" >&2
    exit 1
  fi

  unzip -q "$archive" -d "$destination"

  local binary
  binary="$(find "$destination" -type f -iname "$binary_name" -print | head -n 1)"
  if [[ -z "$binary" ]]; then
    echo "Binary ${binary_name} wurde im ${tool_name}-Artefakt nicht gefunden." >&2
    exit 1
  fi

  chmod +x "$binary"
  echo "$(dirname "$binary")" >> "$GITHUB_PATH"
  echo "${tool_name} erfolgreich verifiziert."
}

install_release_tool \
  "xcodegen-2.46.0" \
  "xcodegen" \
  "https://github.com/yonaskolb/XcodeGen/releases/download/2.46.0/xcodegen.zip" \
  "4d9e34b62172d645eed6457cac13fc222569974098ef4ee9c3368bedf0196806"

install_release_tool \
  "swiftformat-0.62.1" \
  "swiftformat" \
  "https://github.com/nicklockwood/SwiftFormat/releases/download/0.62.1/swiftformat.zip" \
  "7cb1cb1fae04932047c7015441c543848e8e60e1572d808d080e0a1f1661114a"

install_release_tool \
  "swiftlint-0.65.0" \
  "swiftlint" \
  "https://github.com/realm/SwiftLint/releases/download/0.65.0/portable_swiftlint.zip" \
  "d6cb0aa7a2f5f1ef306fc9e37bcb54dc9a26facc8f7784ac0c3dd3eccf5c6ba6"
