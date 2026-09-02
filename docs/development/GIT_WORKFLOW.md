# Git Workflow

## Source of Truth

- Notion: Produktkontext, PRD, Entscheidungen und Statuszusammenfassungen
- GitHub Issues/Board: ausführbare Arbeit und Priorisierung
- Repository: Code, Tests und versionierte technische Dokumentation

## Ablauf

1. Issue mit Nutzerwert und testbaren Akzeptanzkriterien anlegen.
2. Branch von aktuellem `main` erstellen.
3. Kleine, zusammenhängende Änderung implementieren.
4. lokale Quality Gates ausführen.
5. signierten Conventional Commit erstellen.
6. Branch pushen und PR mit `Closes #<issue>` öffnen.
7. CI und Review abwarten; Fehler im selben Branch beheben.
8. nur grüne PRs mergen.
9. Board, Issue und Notion-Status aktualisieren.

## Branch-Namen

```text
feature/<issue>-<beschreibung>
fix/<issue>-<beschreibung>
docs/<issue>-<beschreibung>
refactor/<issue>-<beschreibung>
```

## Commit-Stil

```text
feat(scope): kurze Beschreibung (#issue)
fix(scope): kurze Beschreibung (#issue)
docs(scope): kurze Beschreibung (#issue)
```

`main` ist immer der integrierte Produktstand. Ein dauerhafter `develop`-Branch wird nicht verwendet, weil er für das aktuelle Team zusätzliche Merge- und Synchronisationsarbeit ohne entsprechenden Nutzen erzeugt.
