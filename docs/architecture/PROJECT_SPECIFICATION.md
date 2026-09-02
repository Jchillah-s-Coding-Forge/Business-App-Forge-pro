# ProjectSpecification — Generator Contract

## Zweck

`ProjectSpecificationDraft` ist das mutierbare Arbeitsmodell der AppForge-Projektkonfiguration. `ProjectSpecification` ist der daraus erzeugte, unveränderliche und versionierte Vertrag für Validierung, Resolver und Generator.

```text
Business-Vorlage / leeres Projekt
      ↓
ProjectSpecificationDraft
      ↓ bearbeiten / Diff / Reset
snapshot()
      ↓
ProjectSpecification
      ↓
ProjectSpecificationValidator
      ↓
Registry / Resolver
      ↓
Resolved Product Graph + forge.lock
      ↓
Renderer
      ↓
standalone Flutter Source Code
```

Die SwiftUI-Oberfläche, Templates und Renderer dürfen keine parallelen fachlichen Wahrheiten pflegen. Vorlagen liefern Defaults. Nach dem Anwenden arbeitet der Editor ausschließlich auf `ProjectSpecificationDraft`. Resolver und Renderer erhalten ausschließlich einen unveränderlichen `ProjectSpecification`-Snapshot.

## Lebenszyklus

1. Eine Vorlage oder ein leeres Projekt erzeugt einen `ProjectSpecificationDraft`.
2. Der Nutzer verändert im Draft Datenmodell, Beziehungen, Rollen, Workflows, Screens, Controls, Design und Infrastruktur.
3. Template-Diff und granulare Reset-Operationen arbeiten auf dem Draft und stabilen IDs.
4. Vor dem technischen Handoff erzeugt `draft.snapshot()` einen unveränderlichen `ProjectSpecification`-Snapshot.
5. `ProjectSpecificationValidator` validiert diesen Snapshot als Ganzes.
6. Nur ein valider Snapshot darf an Registry, Resolver und Generator übergeben werden.
7. Für persistierte Manifest-Snapshots wird `ProjectSpecificationJSONCodec` verwendet.
8. Der Resolver erzeugt daraus einen aufgelösten Product Graph und später `forge.lock`.
9. Renderer konsumieren ausschließlich `ProjectSpecification` beziehungsweise den Resolved Product Graph — niemals UI-Zustand oder Template-Sonderpfade.

Diese Trennung verhindert, dass ein laufender Editorvorgang einen bereits gestarteten Resolver-/Generatorlauf nachträglich verändert.

## Schema-Version

`ProjectSpecification.currentSchemaVersion` kennzeichnet das aktuelle persistierbare Snapshot-Schema. Ein unbekannter Wert wird durch den Validator als `unsupportedSchemaVersion` abgelehnt.

Schemaänderungen müssen zukünftig über explizite Migrationen erfolgen. Ein stilles Interpretieren unbekannter Versionen ist nicht zulässig.

## Stabile Identität und Benennung

Jede fachliche Definition verwendet `DefinitionIdentity`:

- `id`: dauerhaft stabile interne Referenz
- `code`: technischer Code-Identifier
- `label`: fachlicher Anzeigename
- `singularLabel`: sichtbare Einzahl
- `pluralLabel`: sichtbare Mehrzahl

Beispiel:

```text
id              entity.customer
code            customer
label           Kunde
singularLabel   Kunde
pluralLabel     Kunden
```

Damit kann `Customer` in der Oberfläche zu `Kunde` werden, ohne Relationen, Screens oder Workflows zu beschädigen. Referenzen verwenden IDs, nicht Labels.

Ein technischer Rename ändert `code`, während die stabile `id` erhalten bleibt. Deshalb sind keine Regex- oder Post-Generation-String-Rewrites erforderlich.

## Entitäten und Felder

`EntityDefinition` enthält `FieldDefinition[]`.

Ein Feld beschreibt mindestens:

- stabile Identität
- Datentyp
- required/optional
- unique/indexed
- typisierten Defaultwert
- Validierungsregeln
- Auswahloptionen
- Sensitivitätsklasse
- Sync-Verhalten
- search/filter/sort-Metadaten

### Unterstützte Feldtypen

- string
- integer
- decimal
- boolean
- date
- dateTime
- time
- email
- phone
- url
- currency
- percentage
- enumeration
- file
- image
- color
- location

`enumeration` benötigt mindestens eine `FieldOptionDefinition`.

### Sensitivität

`DataSensitivity` trennt technische Speicherung und fachliche Klassifizierung:

- `standard`
- `personal`
- `confidential`
- `restricted`

Renderer und Backend-Adapter können daraus später Logging-, Export-, Verschlüsselungs- oder Zugriffspolitiken ableiten. Die Klassifizierung selbst ersetzt keine Autorisierung.

### Sync-Verhalten

`FieldSyncBehavior`:

- `synchronized`
- `localOnly`
- `remoteOnly`

Das Feld beschreibt fachliche Persistenzabsicht. Konkrete SQLite-/Supabase-/Firebase-Implementierung bleibt Aufgabe der Renderer und Adapter.

## Beziehungen

`RelationDefinition` unterstützt:

- `oneToOne`
- `oneToMany`
- `manyToOne`
- `manyToMany`

Zusätzlich werden Ownership, Required-Status, Delete-Regel, optionales Display-Feld und Join-Entity modelliert.

Eine n:m-Beziehung benötigt im aktuellen Schema eine explizite `joinEntityID`. Dadurch ist die relationale Struktur für SQLite und Supabase deterministisch und kann später um Metadaten auf der Zuordnung erweitert werden.

## Feld → UI-Control

`FieldPresentationDefinition` verändert niemals den Domain-Datentyp. Es beschreibt ausschließlich die Darstellung.

| Domain | kompatible Controls |
| --- | --- |
| boolean | checkbox, switchToggle, radioGroup, segmented |
| integer/decimal/currency/percentage | numericField, stepper, slider |
| enumeration | radioGroup, segmented, select, comboBox, autocomplete |
| date | datePicker |
| dateTime | dateTimePicker |
| time | timePicker |
| file | filePicker |
| image | imagePicker |
| color | colorPicker |
| location | textField, autocomplete, locationPicker |
| to-one relation | select, comboBox, autocomplete |
| to-many relation | multiSelect, checkboxList, chips |

Slider benötigen eine gültige `NumericRange` mit `minimum < maximum`.

Auswahlcontrols auf normalen Feldern benötigen Optionen. Boolean Controls besitzen implizite Ja/Nein-Werte und benötigen keine Optionsliste.

`ControlCompatibilityValidator` ist die einzige Quelle für diese Kompatibilitätsregeln.

## Rollen und Berechtigungen

`RoleDefinition` besitzt typisierte `BusinessPermissionDefinition`-Einträge.

Unterstützte Aktionen:

- create
- read
- update
- delete
- approve
- export
- manage

Eine Permission kann global oder auf eine konkrete `entityID` begrenzt werden. Referenzen auf nicht vorhandene Entitäten werden vor der Generierung abgelehnt.

## Fachliche State Machines

`BusinessStateMachineDefinition` ist strikt von Flutter-State-Management getrennt.

```text
draft
  ↓ approve
approved
```

Eine State Machine enthält:

- betroffene Entity
- Statusfeld
- Zustände
- genau einen Initialzustand
- Transitionen
- Trigger
- erlaubte Rollen
- typisierte Guards
- typisierte Side Effects
- Audit-Anforderung

### Guards

`BusinessPredicate` enthält ausschließlich deklarative Operationen:

- fieldEquals
- fieldIsSet
- all
- any
- not

Es werden keine frei ausführbaren Swift-, Dart-, SQL- oder Shell-Code-Strings gespeichert.

### Side Effects

Aktuell unterstützt:

- Feldwert setzen
- Audit-Eintrag anfordern
- Notification anhand einer Template-ID einreihen

Renderer entscheiden später, wie diese Operationen sicher in die Zielplattform übersetzt werden.

## Screens und Navigation

`ScreenDefinition` modelliert:

- dashboard
- list
- detail
- form
- settings
- custom

Screens können einer Entity zugeordnet werden, sichtbare Felder festlegen und Rollen einschränken.

`NavigationDefinition` referenziert Screens ausschließlich über stabile Screen-IDs.

## Offline-Konfiguration

`OfflineConfiguration.businessDefault` setzt für Business-Apps:

- Offline aktiviert
- lokale Single Source of Truth
- Sync-Outbox
- Sync bei wiederhergestellter Verbindung
- Konfliktstrategie `manualReview`

Wenn Offline aktiviert ist, darf die lokale SSOT nicht deaktiviert werden. Bei Cloud-Backends darf bei aktivem Offline-Modus die Outbox nicht deaktiviert werden.

Diese Regeln verhindern, dass UI-Optionen eine Architektur erzeugen, die dem festgelegten Offline-First-Vertrag widerspricht.

## Design-Konfiguration

`DesignConfiguration` enthält MVP-Metadaten für:

- App-Anzeigename
- Primary Color
- Logo-Asset
- Icon-Asset

Farben werden als 6- oder 8-stellige Hexwerte validiert. Design-Tokens und vollständige Themes werden später auf diesem Vertrag aufgebaut.

## Templates, Diff und Reset

`TemplateBaselineDefinition` speichert die ursprüngliche fachliche Baseline zusammen mit `TemplateReference(templateID, version)`.

Die Baseline bleibt unverändert; Anpassungen passieren im `ProjectSpecificationDraft`. `TemplateCustomizationService` kann:

- Added/Removed/Modified-Änderungen ermitteln
- komplettes Business-Modell zurücksetzen
- einzelne Entitäten zurücksetzen
- einzelne Felder zurücksetzen
- Relationen zurücksetzen
- Präsentationen zurücksetzen
- Rollen zurücksetzen
- State Machines zurücksetzen
- Screens zurücksetzen
- Navigation zurücksetzen

Eigene, nicht zur Vorlage gehörende Definitionen bleiben bei granularen Resets erhalten.

`TemplateCustomizationService.diff(...)` kann sowohl einen Draft als auch einen unveränderlichen Snapshot gegen die gespeicherte Baseline vergleichen. Reset-Operationen verändern ausschließlich den Draft.

## Ganzheitliche Validierung

`ProjectSpecificationValidator` validiert den unveränderlichen Snapshot vor Resolver/Generator unter anderem auf:

- Schema-Version
- stabile IDs, portable Codes und nichtleere Labels
- doppelte Entity-/Field-/Relation-/Role-/Workflow-/Screen-IDs und Codes
- Enum-Optionen und Defaultwerte
- Typverträglichkeit und Kohärenz von Validierungsregeln
- Relation-Referenzen und n:m-Join-Entities
- Display-Felder
- Field-/Relation-Presentation-Referenzen
- Control-Kompatibilität
- Rollen und Permission-Entities
- State-Machine-Entity/Statusfeld
- genau einen Initialzustand
- State-/Transition-Referenzen und Statusoptionen
- Guard-/Side-Effect-Felder und deren Entity-Grenzen
- Screen-Entity/Feld/Rollen
- Navigation-Screens/Rollen
- Offline-SSOT/Outbox-Invarianten
- Primary-Color-Format

Ein Renderer darf diese Fehler nicht still korrigieren.

`ProjectSpecificationValidationReport` stellt zusätzlich zu den Issues ein `isValid`-Signal bereit, sodass Application Use Cases und UI einen Generatorlauf eindeutig sperren können.

## Deterministische Serialisierung

`ProjectSpecificationJSONCodec` serialisiert ausschließlich `ProjectSpecification`-Snapshots und verwendet sortierte JSON-Keys sowie eine feste Ausgabeformatierung. Gleiche Snapshots erzeugen dadurch byte-identische Manifestdaten.

Die Reihenfolge fachlich relevanter Arrays bleibt Teil der Specification und wird nicht automatisch umsortiert.

## Sicherheitsgrenzen

- keine Secrets oder Service-Role-Keys in Draft oder `ProjectSpecification`
- keine frei ausführbaren Codefragmente in Guards oder Side Effects
- keine Template-Regex-Manipulation nach der Generierung
- keine UI-Direktzugriffe auf Backend-Adapter
- kein Resolver-/Renderer-Zugriff auf mutablen Editorzustand
- keine Renderer-Heuristik, die ungültige Specification still verändert

Backend-Secrets gehören in die spätere Environment-/Deployment-Konfiguration, nicht in den fachlichen Generatorvertrag.

## Renderer-Regel

Der Flutter Renderer muss ausschließlich aus `ProjectSpecification` beziehungsweise dem daraus aufgelösten Product Graph generieren.

Nicht zulässig:

```text
if template == "inventory" { ... }
regexReplace(generatedCode, ...)
UI-Auswahl direkt im Renderer lesen
ProjectSpecificationDraft direkt rendern
```

Zulässig:

```text
ProjectSpecificationDraft
  → snapshot()
ProjectSpecification
  → validate
  → resolve packages/capabilities
  → Resolved Product Graph
  → render
  → quality gates
```

Diese Grenze ist Voraussetzung dafür, dass später SwiftUI- und Compose-Renderer denselben fachlichen Vertrag verwenden können.
