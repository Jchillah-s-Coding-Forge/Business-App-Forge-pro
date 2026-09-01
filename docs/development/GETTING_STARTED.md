# Getting Started

## Voraussetzungen

- macOS
- Xcode 26 oder kompatible aktuelle Version
- Swift 6
- Homebrew
- XcodeGen, SwiftFormat und SwiftLint

```bash
brew install xcodegen swiftformat swiftlint
```

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
