# Roadmap

Die Roadmap ist fähigkeitsorientiert. Ein Meilenstein endet erst nach Nutzerabnahme und grünen Quality Gates, nicht nach einer beliebigen Kalenderwoche.

## M1 — Project Foundation

- native macOS-SwiftUI-App
- lokale Swift Packages
- Feature-First und MVVM
- typisierte Fehler, Design-Tokens, Tests und CI
- GitHub-/Dokumentationsworkflow

## M2 — Product Specification & Wizard

- versionierte `ProjectSpecification`
- Business Discovery und Progressive Disclosure
- Framework-, Plattform-, Backend- und State-Management-Hilfen
- Rollen-, Entity-, Beziehungs- und Designmodell
- Validierung und Preview-Zusammenfassung
- Environment Doctor mit optionalem Nix-Reproducible-Modus
- deterministische `flake.nix`-/`flake.lock`-Provisionierung und Toolchain-Provenienz
- verifizierter, digest-gebundener und sichtbar bestätigter Nix-Bootstrap auf macOS

## M3 — Package System & Flutter Renderer

- Package Contract und Registry
- validierte gebündelte Produktions-Registry mit minimalem `foundation.core`
- End-to-End-Orchestrierung aus Resolve → Render → Materialize
- Dependency Resolver und Kompatibilitätsprüfung
- `forge.lock` mit Integritätsinformationen
- deterministischer Flutter-Renderer
- toolchain-gepinnte Flutter-Materialisierung mit nativen iOS-/Android-Shells
- direkte SDK- oder verifizierte Nix-backed Flutter-Materialisierung
- `flutter pub get`, `flutter analyze` und `flutter test` als Materialisierungs-Gates
- Toolchain-/Dependency-Provenienz über `appforge.toolchain.json`
- Architektur- und Golden Tests

## M4 — Demo, Offline & Backends

- rollenbasierter Evaluationsmodus
- SQLite-SSOT mit schema-versionierten Migrationen
- lokale Repository-/Data-Source-Schicht als Single Source of Truth
- atomare Entity-Mutation + Sync-Outbox in derselben SQLite-Transaktion
- persistente Idempotency Keys, Sync-Status und Tombstone-Deletes
- typisierte Konfliktstrategien aus der ProjectSpecification
- Supabase-Adapter, Migrationen, RLS-Tests und geführtes Setup
- Firebase-Adapter und äquivalente Security Rules

## M5 — Design, Quality & Release

- Branding, Logo, App-Icon und Design-Tokens
- semantisches Boolean-Control-Mapping
- Preview und Accessibility-Prüfung
- Quality Center mit Format, Analyze, Test und Build
- Release Center für iOS und Android

## M6 — Commercial Beta

- Inventar & Assets als Golden Reference
- fachliche Abnahme pro Rolle
- Lizenz- und Entitlement-System
- Billing, Customer Portal und steuerliche Freigabe
- signierte/notarisierte macOS-Beta und Supportprozess

## Danach

- SwiftUI-Renderer
- Jetpack-Compose-Renderer
- private Package Registry
- Agentur-/Team-Arbeitsbereiche
- optionale SAP-, DATEV- und weitere Unternehmensadapter
