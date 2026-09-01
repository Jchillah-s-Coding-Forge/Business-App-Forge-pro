# ADR-002: MVVM ist Standard, State Management bleibt variabel

- Status: Accepted
- Datum: 2026-09-01

## Entscheidung

MVVM, Feature-First, Repository Pattern, Use Cases, DI und SSOT sind nicht einzeln auswählbar. Sie bilden den verbindlichen Qualitätsvertrag.

Für Flutter kann der Nutzer innerhalb dieses Vertrags Riverpod oder BLoC/Cubit wählen:

```text
View
  → Riverpod Notifier oder Cubit
  → Use Case
  → Repository Contract
  → lokale/remote DataSource
```

## Begründung

MVVM beschreibt Verantwortlichkeiten. Riverpod und BLoC/Cubit beschreiben technische Zustandsverwaltung. Ein gemeinsames Auswahlfeld würde unterschiedliche Ebenen vermischen und unerfahrene Nutzer zu ungültigen Kombinationen verleiten.
