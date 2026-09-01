# Architecture Overview

## Produktarchitektur

AppForge Pro besteht aus einer dünnen macOS-Composition-Root und wiederverwendbaren Swift Packages.

```text
SwiftUI Feature
  → ViewModel
  → Application Use Case
  → Domain Contract
  ← Infrastructure Adapter
```

Die UI baut den Generator nicht direkt zusammen. Sie erzeugt eine vollständige `ProjectSpecification`, die anschließend unveränderlich an Resolver und Generator übergeben wird.

## Module im Foundation-Meilenstein

```text
AppForgePro
├── App                  Composition Root
├── Features             Feature-First SwiftUI/MVVM
└── Packages/AppForgeKit
    ├── AppForgeCore             Fehler und gemeinsame Verträge
    ├── AppForgeDomain           ProjectSpecification und Invarianten
    ├── AppForgeApplication      Use Cases
    └── AppForgeDesignSystem     Host-App-Tokens und Komponenten
```

Weitere Generator-, Registry-, Resolver- und Renderer-Module werden erst in ihren Issues ergänzt.

## Abhängigkeitsregeln

- Domain importiert keine UI-, Datei- oder Backend-Frameworks.
- Application hängt von Domain und Core ab.
- Infrastructure implementiert Domain-Verträge und wird am Composition Root injiziert.
- Presentation spricht nur mit ViewModels und Application Use Cases.
- Generierte Anwendungen enthalten keine AppForge-Pro-Laufzeitabhängigkeit.

## Fester Architekturvertrag erzeugter Apps

- MVVM
- Feature-First
- Repository Pattern
- Use Cases
- Dependency Injection
- lokale SSOT bei Offline-Modus
- typisierte Fehler
- keine Backend-Aufrufe aus Screens

State Management implementiert MVVM; es ersetzt MVVM nicht. Deshalb gibt es keinen separaten MVVM-Schalter.

## Packagestrategie

Wiederverwendbare APIs starten im Monorepo. Ein Modul wird erst in ein eigenes Repository ausgelagert, wenn:

1. mindestens zwei echte Consumer existieren,
2. die öffentliche API durch Tests stabilisiert ist,
3. Versionierung und Kompatibilitätsregeln feststehen,
4. die Extraktion mehr Nutzen als Release-Aufwand bringt.

Das verhindert ein frühzeitig unbeherrschbares Netz kleiner Repositories.
