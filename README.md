# AppForge Pro

AppForge Pro ist eine native macOS-Produktwerkstatt, mit der Unternehmer ohne Programmierkenntnisse wartbare Business-Anwendungen konfigurieren, vorab mit Rollen testen, generieren und bis zum Release begleiten können.

> Das Repository enthält **den Generator**, nicht eine einzelne Inventar-, CRM- oder Demo-App.

## Status

- Phase: Greenfield-Rebuild
- Meilenstein: M1 — Project Foundation
- Host: Swift 6, SwiftUI, macOS
- Erster Output: Flutter für iOS und Android
- Architektur: Feature-First, MVVM, Repository Pattern, Use Cases, DI, SSOT

MVVM ist ein verbindlicher Architekturstandard und kein Schalter im Wizard. Riverpod oder BLoC/Cubit sind auswählbare Flutter-State-Management-Strategien innerhalb dieses Standards.

## Lokal starten

```bash
./Scripts/bootstrap.sh
open AppForgePro.xcodeproj
```

Alle Quality Gates:

```bash
./Scripts/quality.sh
```

## Dokumentation

- [Produktvision](docs/product/PRODUCT_VISION.md)
- [Product Requirements Document](docs/product/PRD.md)
- [Roadmap](docs/product/ROADMAP.md)
- [Monetarisierung](docs/product/MONETIZATION.md)
- [Architekturübersicht](docs/architecture/OVERVIEW.md)
- [GitHub-Workflow](docs/development/GIT_WORKFLOW.md)
- [Lokales Setup](docs/development/GETTING_STARTED.md)
- [Definition of Done](docs/development/DEFINITION_OF_DONE.md)

## Verbindlicher Entwicklungsablauf

```text
Issue → Branch → Implementierung → Tests → signierter Commit → Pull Request → Review/CI → Merge
```

Aktuelles Repository: [Business-App-Forge-pro](https://github.com/Jchillah-s-Coding-Forge/Business-App-Forge-pro)

## Lizenz

Copyright © Jchillah's Coding Forge. Eine Produktlizenz wird vor der öffentlichen Distribution festgelegt.
