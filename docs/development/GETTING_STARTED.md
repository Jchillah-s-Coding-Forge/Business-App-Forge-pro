# Getting Started

## Voraussetzungen

- macOS
- Xcode 26 oder kompatible aktuelle Version
- Swift 6
- Homebrew
- XcodeGen, SwiftFormat und SwiftLint

Die verbindlichen Versionen stehen in `Config/tool-versions.env`. Lokale Prüfung und CI brechen bei abweichenden Versionen bewusst ab, damit derselbe Commit nicht mit wechselnden Formatter-, Linter- oder Projektgeneratorregeln bewertet wird.

```bash
brew install xcodegen swiftformat swiftlint
./Scripts/verify_tool_versions.sh
```

Nach einer angekündigten Toolchain-Aktualisierung:

```bash
brew update
brew upgrade xcodegen swiftformat swiftlint
./Scripts/verify_tool_versions.sh
```

Eine Versionsänderung erfolgt ausschließlich in einem eigenen PR, zusammen mit neu erzeugtem Xcode-Projekt und grünen Quality Gates.

## Projekt vorbereiten

```bash
git clone https://github.com/Jchillah-s-Coding-Forge/Business-App-Forge-pro.git
cd Business-App-Forge-pro
./Scripts/bootstrap.sh
open AppForgePro.xcodeproj
```

## Vor jedem Commit

```bash
./Scripts/quality.sh
git diff --check
git status --short
```

`xcuserdata`, DerivedData, Secrets und lokale Signing-Dateien dürfen niemals committed werden.
