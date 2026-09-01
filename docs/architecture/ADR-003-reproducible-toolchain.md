# ADR-003 — Reproduzierbare Projektwerkzeuge

## Status

Angenommen.

## Kontext

SwiftFormat, SwiftLint und XcodeGen können bei neuen Versionen ihren Output oder ihre Regeln ändern. Eine unversionierte Installation würde denselben Commit zu unterschiedlichen Zeitpunkten unterschiedlich bewerten.

## Entscheidung

- `Config/tool-versions.env` ist die Single Source of Truth für Projektwerkzeuge.
- Lokale Skripte und CI prüfen die exakten Versionen vor der Ausführung.
- GitHub Actions werden auf unveränderliche Commit-SHAs gepinnt.
- XcodeGen-Output wird lokal und in CI gegen das eingecheckte Projekt geprüft.
- Toolchain-Updates erfolgen in eigenen PRs mit dokumentierter Migration.

## Konsequenzen

Neue Homebrew-Versionen werden nicht stillschweigend übernommen. Ein Versionskonflikt liefert eine konkrete Aktualisierungsanweisung und verhindert uneinheitliche Artefakte.
