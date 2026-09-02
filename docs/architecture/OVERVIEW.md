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

Die UI baut den Generator nicht direkt zusammen. Während der Konfiguration arbeitet sie auf einem mutablen `ProjectSpecificationDraft`. Der technische Handoff erzeugt mit `snapshot()` eine unveränderliche `ProjectSpecification`, die anschließend ganzheitlich validiert wird. Resolver und Renderer erhalten ausschließlich diesen Snapshot und verändern ihn nicht stillschweigend.

Der normative Vertrag ist in [`PROJECT_SPECIFICATION.md`](PROJECT_SPECIFICATION.md) beschrieben.

## Module im Foundation-Meilenstein

```text
AppForgePro
├── App                  Composition Root
├── Features             Feature-First SwiftUI/MVVM
└── Packages/AppForgeKit
    ├── AppForgeCore             Fehler und gemeinsame Verträge
    ├── AppForgeDomain           Draft, ProjectSpecification und Invarianten
    ├── AppForgeApplication      Use Cases
    └── AppForgeDesignSystem     Host-App-Tokens und Komponenten
```

Weitere Generator-, Registry-, Resolver- und Renderer-Module werden in ihren jeweiligen Issues ergänzt.

## Abhängigkeitsregeln

- Domain importiert keine UI-, Datei- oder Backend-Frameworks.
- Application hängt von Domain und Core ab.
- Infrastructure implementiert Domain-Verträge und wird am Composition Root injiziert.
- Presentation spricht nur mit ViewModels und Application Use Cases.
- Generierte Anwendungen enthalten keine AppForge-Pro-Laufzeitabhängigkeit.
- Templates liefern Defaults, aber keine versteckten Generator-Sonderpfade.
- Mutationen finden ausschließlich am `ProjectSpecificationDraft` statt.
- Resolver und Renderer konsumieren ausschließlich validierte `ProjectSpecification`-Snapshots beziehungsweise den Resolved Product Graph.

## Fester Architekturvertrag erzeugter Apps

- MVVM
- Feature-First
- Repository Pattern
- Use Cases
- Dependency Injection
- lokale SSOT bei Offline-Modus
- Sync-Outbox bei Cloud + Offline
- typisierte Fehler
- keine Backend-Aufrufe aus Screens

State Management implementiert MVVM; es ersetzt MVVM nicht. Deshalb gibt es keinen separaten MVVM-Schalter.

Fachliche Zustände wie `draft → approved → completed` werden als `BusinessStateMachineDefinition` modelliert und sind strikt von Riverpod/BLoC-Zuständen getrennt.

## Generatorgrenze

```text
Template / leeres Projekt
        ↓
ProjectSpecificationDraft
        ↓ snapshot()
ProjectSpecification
        ↓
ProjectSpecificationValidator
        ↓
Registry + Resolver
        ↓
Resolved Product Graph
        ↓
forge.lock
        ↓
Renderer
        ↓
Quality Gates
        ↓
Standalone Source Code
```

Der Renderer darf ungültige fachliche Konfiguration nicht durch Heuristiken, Regex-Rewrites oder hardcodierte Template-Zweige korrigieren. Ebenso darf er keinen mutablen Draft konsumieren.

## Packagestrategie

Wiederverwendbare APIs starten im Monorepo. Ein Modul wird erst in ein eigenes Repository ausgelagert, wenn:

1. mindestens zwei echte Consumer existieren,
2. die öffentliche API durch Tests stabilisiert ist,
3. Versionierung und Kompatibilitätsregeln feststehen,
4. die Extraktion mehr Nutzen als Release-Aufwand bringt.

Das verhindert ein frühzeitig unbeherrschbares Netz kleiner Repositories.
