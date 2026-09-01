# Getting Started

## Voraussetzungen

- macOS
- Xcode 26 oder kompatible aktuelle Version
- Swift 6
- Homebrew
- Mint

Die lokalen Projektwerkzeuge sind im `Mintfile` auf feste Versionen gepinnt. Dadurch verwenden lokale Quality Gates dieselben XcodeGen-, SwiftFormat- und SwiftLint-Versionen wie CI.

GitHub Actions kompiliert diese Werkzeuge nicht bei jedem Lauf neu. CI lädt die offiziellen Release-Artefakte derselben Versionen und verifiziert vor der Nutzung deren fest hinterlegte SHA-256-Digests.

```bash
brew install mint
mint bootstrap
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
