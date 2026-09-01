# ADR-001: Reproduzierbares Xcode- und Package-Fundament

- Status: Accepted
- Datum: 2026-09-01
- Issue: #1

## Kontext

Vorherige AppForge-Implementierungen vermischten Produktprototyp, Generatorlogik und konkrete Business-Vorlagen. Entwicklungsschritte waren dadurch schwer nachvollziehbar.

## Entscheidung

- Greenfield-Neustart im Repository `Business-App-Forge-pro`
- XcodeGen-Datei `project.yml` ist die Projekt-SSOT
- das generierte `.xcodeproj` wird für direkten Xcode-Einstieg committed
- Host-App: native SwiftUI-macOS-Anwendung
- wiederverwendbare Module: lokales SwiftPM-Package `AppForgeKit`
- GitHub Flow statt dauerhaftem `develop`-Branch
- jeder technische Schritt wird über Issue und PR integriert

## Konsequenzen

- Projektdatei kann reproduzierbar neu erzeugt und in CI verglichen werden.
- Einsteiger können das eingecheckte Xcode-Projekt direkt öffnen.
- Package-APIs können unabhängig getestet werden.
- `main` bleibt integrierbar; Releases werden später getaggt.
- zusätzliche Renderer werden nicht vorgezogen, bevor Flutter Ende-zu-Ende funktioniert.
