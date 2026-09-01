# AppForge Pro

> **Business applications without boilerplate.**
> AppForge Pro ist eine native macOS-Anwendung zur reproduzierbaren Generierung vollständiger Business-Anwendungen aus wenigen fachlichen Entscheidungen.

---

## Status

**Projektstatus:** Neustart / Greenfield-Rebuild
**Produktphase:** Foundation / Project Setup
**Host-Anwendung:** macOS · Swift · SwiftUI
**Erster Generator-Output:** Flutter
**Geplante weitere Outputs:** SwiftUI · Jetpack Compose
**Primäre Zielgruppe:** Unternehmer und Fachanwender ohne Programmierkenntnisse
**Sekundäre Zielgruppe:** Entwickler, Agenturen und interne IT-Teams

---

# 1. Was ist AppForge Pro?

AppForge Pro ist **keine Business-App** und keine Sammlung von Demo-Templates.

AppForge Pro ist eine **Business-App-Fabrik**.

Ein Unternehmer beschreibt über eine intuitive macOS-Oberfläche, welche Anwendung benötigt wird. AppForge Pro übersetzt diese fachlichen Entscheidungen in eine technische Projektspezifikation, löst benötigte Packages und deren Abhängigkeiten auf und generiert anschließend vollständigen, normalen und editierbaren Source Code.

Die langfristige Produktpipeline lautet:

```text
Business-Anforderung
        ↓
AppForge Pro
        ↓
Project Specification
        ↓
Registry
        ↓
Package Resolver
        ↓
forge.lock
        ↓
Version Resolver
        ↓
Package Downloader
        ↓
Generator
        ↓
Quality Gates
        ↓
┌──────────────┬──────────────┬──────────────┐
│              │              │              │
▼              ▼              ▼
Flutter      SwiftUI        Compose
```

AppForge Pro soll damit den Bereich zwischen klassischen No-Code-Systemen und manueller Softwareentwicklung besetzen:

```text
No-Code
   │
   │ einfacher Einstieg
   ▼
AppForge Pro
   │
   │ echter Source Code
   ▼
professionelle Softwareentwicklung
```

Der Nutzer erhält **keine proprietäre Runtime-Anwendung**, sondern ein vollständiges Softwareprojekt.

---

# 2. Produktvision

Das Ziel lautet:

> Ein Unternehmer soll eine professionelle Business-Anwendung konfigurieren, testen, generieren, mit einem Backend verbinden und veröffentlichen können, ohne die Architektur selbst programmieren zu müssen.

AppForge Pro soll dabei technische Entscheidungen verständlich machen, statt sie einfach zu verstecken.

Beispiel:

```text
Welche Datenbank möchtest du verwenden?

○ Nur lokal
  Geeignet für Apps, die auf einem Gerät arbeiten.

○ Supabase
  Empfohlen für Teams, Rollen und gemeinsame Daten.

○ Firebase
  Geeignet für Echtzeitdaten und Google-Infrastruktur.

○ Noch nicht entscheiden
  Die App wird zunächst mit lokalen Testdaten erzeugt.
```

Dasselbe Prinzip gilt für:

* State Management
* Zielplattformen
* Authentifizierung
* Rollen
* Offline-Modus
* Synchronisierung
* Design
* Navigation
* Business-Module
* Backend
* Benachrichtigungen
* Zahlungen
* Store-Releases

Der Unternehmer soll fachliche Entscheidungen treffen können, ohne Begriffe wie Repository, DataSource, Cubit oder Dependency Injection verstehen zu müssen.

---

# 3. Kernversprechen

AppForge Pro basiert auf sieben Produktversprechen.

### 3.1 Einfach konfigurieren

Der Nutzer beantwortet verständliche Fragen und wählt Business-Funktionen aus.

### 3.2 Professionellen Code erzeugen

Generierter Code folgt verbindlichen Architektur- und Qualitätsregeln.

### 3.3 Vor Backend-Einrichtung testen

Jede unterstützte Rolle erhält auf Wunsch einen lokalen Demo-Zugang.

### 3.4 Offline arbeiten

Business-Daten bleiben auch ohne Internet verwendbar.

### 3.5 Später Backend aktivieren

Supabase, Firebase und zukünftige Anbieter werden über austauschbare Adapter eingebunden.

### 3.6 Source Code besitzen

Die erzeugte Anwendung gehört dem Nutzer und kann vollständig weiterentwickelt werden.

### 3.7 Veröffentlichung unterstützen

AppForge Pro soll den Nutzer bis zum Android-/iOS-/Desktop-/Web-Release begleiten.

---

# 4. Zentrale User Stories

## Unternehmer

**Als Unternehmer möchte ich Business-Anwendungen ohne Programmierkenntnisse generieren können**, damit ich interne oder kommerzielle Software erstellen kann, ohne zuerst ein Entwicklerteam aufbauen zu müssen.

**Als Unternehmer möchte ich nach der Generierung eine Schritt-für-Schritt-Anleitung erhalten**, damit ich die ausgewählte Datenbank und Infrastruktur korrekt implementieren kann.

**Als Unternehmer möchte ich Datenbanktechnologien anhand kurzer verständlicher Erklärungen vergleichen**, damit ich eine passende Entscheidung treffen kann.

**Als Unternehmer möchte ich State Management anhand verständlicher Empfehlungen auswählen können**, ohne die Implementierungsdetails kennen zu müssen.

**Als Unternehmer möchte ich meine Anwendung vor Einrichtung eines echten Cloud-Backends testen können**, damit ich Prozesse und Rollen zuerst fachlich prüfen kann.

**Als Unternehmer möchte ich für jede Rolle automatisch Testzugänge erhalten**, damit ich beispielsweise Administrator-, Manager- und Mitarbeiteransichten prüfen kann.

**Als Unternehmer möchte ich Zielplattformen auswählen können**, damit AppForge nur benötigte Plattformen vorbereitet.

**Als Unternehmer möchte ich Farben, Logo und App-Symbole konfigurieren**, damit die Anwendung zu meinem Unternehmen passt.

**Als Unternehmer möchte ich einfache Symbole bearbeiten oder Varianten auswählen können**, ohne Grafiksoftware verwenden zu müssen.

**Als Unternehmer möchte ich bei Boolean-Feldern auswählen können, ob beispielsweise Checkbox, Switch oder andere geeignete Komponenten verwendet werden**, damit die Benutzeroberfläche meinem Anwendungsfall entspricht.

**Als Unternehmer möchte ich variable Designentscheidungen selbst treffen können**, während nicht sinnvolle oder unsichere Kombinationen durch AppForge verhindert werden.

**Als Unternehmer möchte ich nach erfolgreicher Abnahme Store-Releases durchführen können**, damit die erzeugte Anwendung produktiv verteilt werden kann.

---

## Endnutzer der erzeugten Anwendung

**Als Nutzer möchte ich sofort verstehen, welchen Zweck ein Screen erfüllt**, damit ich keine umfangreiche Schulung benötige.

**Als Nutzer möchte ich Daten offline lesen und bearbeiten können**, damit ich auch ohne Internet produktiv arbeiten kann.

**Als Nutzer möchte ich, dass lokale Änderungen nach Wiederherstellung der Internetverbindung automatisch synchronisiert werden**, damit Kollegen mit dem aktuellen Datenstand weiterarbeiten.

**Als Nutzer möchte ich verständliche Fehlermeldungen erhalten**, statt technische Exceptions zu sehen.

---

## Entwickler

**Als Entwickler möchte ich, dass AppForge Pro und alle erzeugten Anwendungen verbindlichen Architekturregeln folgen.**

Dazu gehören:

* Clean Code
* KISS
* DRY
* SOLID
* Single Source of Truth
* Repository Pattern
* Feature-First
* MVVM
* Dependency Injection
* klare Layer-Grenzen
* testbare Business-Logik
* typisierte Fehlerbehandlung

**Als Entwickler möchte ich Fehler kontrolliert abfangen**, statt unkontrollierte Exceptions durch UI oder Datenebenen laufen zu lassen.

**Als Entwickler möchte ich jede Änderung über Issues, Branches, Commits, Pull Requests, Reviews und Merges nachvollziehen können.**

**Als Entwickler möchte ich identische Projektkonfigurationen reproduzierbar generieren können.**

---

# 5. Für wen wird AppForge Pro gebaut?

AppForge Pro soll mehrere Nutzungsstufen bedienen.

## Fachanwender / Unternehmer

Sie sehen hauptsächlich:

```text
Branche
Business-Typ
Funktionen
Mitarbeiterrollen
Daten
Design
Backend
Plattformen
```

## Technische Nutzer

Sie können zusätzlich konfigurieren:

```text
State Management
Package-Versionen
Backend-Provider
Sync-Strategie
Konfliktstrategie
Architekturdetails
Build-Konfiguration
```

## Entwickler

Sie können den vollständigen technischen Zustand einsehen:

```text
Manifest
Dependency Graph
Package Registry
forge.lock
Generator Output
Quality Gates
```

Dieses Konzept heißt:

> **Progressive Disclosure**

Der Anfänger sieht keine unnötigen technischen Details.

Der Entwickler kann trotzdem vollständig kontrollieren, was AppForge erzeugt.

---

# 6. AppForge Pro selbst

AppForge Pro wird als native macOS-Anwendung entwickelt.

Technologien:

```text
Swift
SwiftUI
Swift Package Manager
XCTest / Swift Testing
Xcode
```

Die Anwendung selbst folgt denselben Standards, die sie später erzeugten Anwendungen vorgibt.

---

# 7. Architektur von AppForge Pro

Die Anwendung wird Feature-First und modular aufgebaut.

Geplanter Swift-Modulgraph:

```text
AppForgePro
│
├── AppForgeDomain
│
├── AppForgeApplication
│
├── AppForgeRegistry
│
├── AppForgeResolver
│
├── AppForgeGenerator
│
├── AppForgeDesignSystem
│
├── AppForgePersistence
│
├── AppForgePlatform
│
│
├── AppForgeRendererFlutter
├── AppForgeRendererSwiftUI
└── AppForgeRendererCompose
```

Das macOS Target ist lediglich der Composition Root.

Die UI darf den Generator nicht direkt zusammenbauen.

Stattdessen erzeugt die Oberfläche einen unveränderlichen:

```swift
ProjectSpecification
```

Dieser beschreibt vollständig, **was erzeugt werden soll**.

Beispielhaft:

```text
ProjectSpecification
├── ProjectIdentity
├── TargetPlatforms
├── ArchitectureConfiguration
├── BackendConfiguration
├── StateManagementConfiguration
├── AuthenticationConfiguration
├── RoleConfiguration
├── OfflineConfiguration
├── BusinessModules
├── DataModel
├── DesignConfiguration
├── NavigationConfiguration
└── ReleaseConfiguration
```

Der Generator arbeitet ausschließlich mit diesem Snapshot.

Dadurch können später dieselben Generatoren aus mehreren Oberflächen genutzt werden:

```text
SwiftUI Studio
CLI
AI Assistant
CI Pipeline
API
```

---

# 8. Geplante Projektstruktur

```text
AppForgePro/
│
├── AppForgePro.xcodeproj
│
├── README.md
├── LICENSE
├── CHANGELOG.md
│
├── App/
│   ├── AppForgeProApp.swift
│   ├── AppEnvironment.swift
│   └── DependencyContainer.swift
│
├── Core/
│   ├── Domain/
│   ├── Application/
│   ├── Errors/
│   ├── Logging/
│   ├── Validation/
│   └── Utilities/
│
├── Features/
│   ├── ProjectSetup/
│   │   ├── Domain/
│   │   ├── Data/
│   │   └── Presentation/
│   │
│   ├── BusinessDiscovery/
│   ├── PlatformSelection/
│   ├── BackendSelection/
│   ├── StateManagementSelection/
│   ├── RoleDesigner/
│   ├── DataModelDesigner/
│   ├── DesignEditor/
│   ├── PackageSelection/
│   ├── Preview/
│   ├── Generation/
│   ├── QualityCenter/
│   └── ReleaseCenter/
│
├── Packages/
│   ├── Domain/
│   ├── Registry/
│   ├── Resolver/
│   ├── Lockfile/
│   ├── Downloader/
│   └── Generator/
│
├── Renderers/
│   ├── Flutter/
│   ├── SwiftUI/
│   └── Compose/
│
├── Resources/
│   ├── Assets.xcassets/
│   ├── Templates/
│   └── Presets/
│
├── Tests/
│   ├── Unit/
│   ├── Integration/
│   ├── Generator/
│   └── Golden/
│
├── docs/
│   ├── architecture/
│   ├── product/
│   ├── development/
│   ├── packages/
│   ├── testing/
│   └── releases/
│
└── .github/
    ├── workflows/
    ├── ISSUE_TEMPLATE/
    └── pull_request_template.md
```

Feature-interne Abhängigkeiten sollen gerichtet bleiben:

```text
Presentation
     ↓
Application
     ↓
Domain
     ↑
Data / Infrastructure
```

---

# 9. Package-Ökosystem

Wiederverwendbare Funktionen werden nicht dauerhaft direkt in AppForge Pro eingebaut.

Sie werden eigenständige Forge Packages.

Geplante Repository-Landschaft:

```text
jchillah/
│
├── appforge
├── appforge-registry
├── forge-core
├── forge-design-system
├── forge-auth
├── forge-firebase
├── forge-supabase
├── forge-profile
├── forge-inventory
├── forge-offline-sync
├── forge-chat
├── forge-notifications
├── forge-stripe
└── forge-business
```

---

# 10. Verantwortlichkeiten der Packages

## `appforge`

Generatorplattform und AppForge-Pro-Kern.

Enthält unter anderem:

```text
Manifest
Registry Client
Dependency Resolver
forge.lock
Version Resolver
Package Downloader
Generator Contracts
Renderer Contracts
```

---

## `appforge-registry`

Zentrale Registry verfügbarer Forge Packages.

Sie kennt:

```text
Package ID
Versionen
Dependencies
Capabilities
Plattformen
Kompatibilität
Checksums
Source
Deprecated/Yanked Releases
```

---

## `forge-core`

Grundlage jeder erzeugten Anwendung.

Beispiele:

```text
Error Handling
Result Types
Logging
Configuration
Environment
Base Repositories
Common Utilities
Routing Contracts
Localization Contracts
Validation
```

---

## `forge-design-system`

Wiederverwendbares Designsystem.

Beispiele:

```text
Colors
Typography
Spacing
Radius
Buttons
TextFields
Cards
Dialogs
Checkboxes
Switches
Navigation
Responsive Rules
Accessibility
```

---

## `forge-auth`

Provider-neutrale Authentifizierung.

Beispiele:

```text
Login
Logout
Registration
Session
Current User
Password Reset
Role Context
Demo Authentication
```

---

## `forge-firebase`

Firebase-spezifische Adapter.

Beispiele:

```text
Firebase Auth
Firestore
Firebase Storage
Push Notifications
Remote Config
```

---

## `forge-supabase`

Supabase-spezifische Adapter.

Beispiele:

```text
Supabase Auth
PostgreSQL
Storage
Realtime
RLS
RPC
Generated Migrations
```

---

## `forge-profile`

Profil- und Account-Funktionen.

```text
Profile
Avatar
Account
Preferences
Personal Data
```

---

## `forge-inventory`

Business-Modul für Inventar und Assets.

```text
Asset
InventoryItem
Location
Movement
Allocation
Stock
Search
Filters
```

---

## `forge-offline-sync`

Offline-first Infrastruktur.

```text
SQLite
Outbox
Sync Queue
Conflict Handling
Tombstones
Retry
Connectivity
Sync Status
```

---

## `forge-chat`

Messaging und Kommunikation.

```text
Conversation
Message
Attachments
Read Status
Realtime Updates
```

---

## `forge-notifications`

Benachrichtigungen.

```text
Push
Local Notifications
Notification Preferences
Notification Inbox
```

---

## `forge-stripe`

Payment-Infrastruktur.

```text
Checkout
Subscriptions
Entitlements
Customer Portal
Server-side Verification
```

---

## `forge-business`

Übergreifende Business-Grundlagen.

Beispiele:

```text
Organizations
Memberships
Roles
Permissions
Customers
Contacts
Workflows
Approvals
Audit
Tenancy
```

---

# 11. Registry und Dependency Resolution

Packages dürfen Abhängigkeiten besitzen.

Beispiel:

```text
forge-inventory
      │
      ├── forge-core
      ├── forge-business
      └── forge-offline-sync
```

AppForge Pro löst diese automatisch auf.

Pipeline:

```text
User Selection
      ↓
Registry
      ↓
Dependency Resolver
      ↓
Resolved Package Graph
      ↓
forge.lock
      ↓
Version Resolver
      ↓
Package Downloader
      ↓
Generator
```

Der Nutzer muss transitive Dependencies nicht manuell kennen.

---

# 12. `forge.lock`

Jedes Projekt erhält einen Lockfile.

Beispiel:

```yaml
schema_version: 1

generator:
  version: 1.0.0

packages:

  forge-core:
    version: 1.2.0

  forge-auth:
    version: 1.4.1

  forge-inventory:
    version: 2.0.0

  forge-offline-sync:
    version: 1.1.3
```

Später zusätzlich:

```text
Registry
Source
Integrity Hash
Dependencies
Generator Version
Renderer Version
```

Ziel:

> Gleiche Spezifikation + gleicher Lockfile + gleiche Generatorversion = gleiche Projektstruktur.

---

# 13. Erster Generator: Flutter

Flutter ist der erste produktive Renderer.

Ein generiertes Projekt folgt verbindlich:

```text
lib/
├── main.dart
├── app.dart
│
├── core/
│
└── features/
    └── feature_name/
        ├── data/
        ├── domain/
        └── presentation/
```

---

# 14. Architekturvertrag erzeugter Anwendungen

Generierte Apps müssen folgende Regeln einhalten:

* Clean Code
* SOLID
* KISS
* DRY
* SSOT
* Feature-First
* MVVM
* Repository Pattern
* Use Cases
* Dependency Injection
* klare Domain/Data/Presentation-Trennung
* keine Business-Logik im UI
* keine direkten Backend-Aufrufe aus Screens
* typisierte Fehler
* testbare Business-Logik
* keine Secrets im Client
* reproduzierbarer Build

Flutter:

```text
Presentation
    ↓
ViewModel / Cubit / Notifier
    ↓
UseCase
    ↓
Repository Contract
    ↓
Repository Implementation
    ↓
Local / Remote DataSource
```

---

# 15. State Management

Der Unternehmer soll State Management nicht anhand von Marketingbegriffen auswählen müssen.

AppForge zeigt verständliche Beschreibungen.

Beispiel:

### BLoC / Cubit

Empfohlen für:

```text
größere Business-Anwendungen
klar nachvollziehbare Zustände
komplexere Workflows
Teams
```

### Riverpod

Empfohlen für:

```text
moderne Flutter-Projekte
gute Testbarkeit
flexible Dependency Injection
weniger Boilerplate
```

### Provider

Nur für einfache Projekte.

AppForge darf außerdem einen empfohlenen Standard vorauswählen.

Die tatsächliche Implementierung wird hinter Generatorstrategien gekapselt.

---

# 16. Backend-Auswahl

Unterstützte Zielarchitektur:

```text
Local only
SQLite + Supabase
SQLite + Firebase
weitere Adapter später
```

AppForge erklärt nicht nur die Technologie, sondern den Einsatzzweck.

Beispiel:

```text
Supabase

Gut geeignet für:
✓ klassische Geschäftsdaten
✓ Beziehungen
✓ Organisationen
✓ Rollen
✓ SQL
✓ Reporting

Empfohlen für:
Business- und Verwaltungsanwendungen
```

---

# 17. Datenbank-Setup nach der Generierung

Nach jeder Generierung entsteht eine Anleitung.

Beispiel:

```text
docs/
├── START_HERE.md
├── DATABASE_SETUP.md
├── DATA_ARCHITECTURE.md
├── AUTH_SETUP.md
├── OFFLINE_SYNC.md
└── PRODUCTION_READINESS.md
```

`DATABASE_SETUP.md` erklärt beispielsweise:

```text
1. Supabase-Projekt erstellen
2. Projekt-URL übernehmen
3. Public Anon Key übernehmen
4. Migrationen ausführen
5. RLS aktivieren
6. Rollen testen
7. Environment-Datei erzeugen
8. App neu starten
```

Langfristig soll AppForge viele dieser Schritte automatisieren können.

---

# 18. Evaluationsmodus vor Cloud-Setup

Ein wesentlicher Produktbestandteil ist der **Demo Mode**.

Eine erzeugte Anwendung soll ohne Backend sofort testbar sein.

Beispiel:

```text
Administrator
admin@demo.local
demo1234

Manager
manager@demo.local
demo1234

Mitarbeiter
employee@demo.local
demo1234
```

Die Accounts werden aus den im Wizard definierten Rollen erzeugt.

Beispiel:

```text
Rollen
├── Owner
├── Administrator
├── Manager
├── Mitarbeiter
└── Viewer
```

AppForge erzeugt daraus Testkonten.

Damit kann der Unternehmer kontrollieren:

```text
Was sieht ein Administrator?
Was darf ein Mitarbeiter bearbeiten?
Welche Navigation sieht ein Viewer?
Welche Freigaben benötigt ein Manager?
```

Erst danach muss das echte Backend aktiviert werden.

Demo-Accounts dürfen in Production Builds nicht aktiv bleiben.

---

# 19. Offline-first

Business-Anwendungen müssen auch bei schlechter Verbindung funktionieren können.

Standardmodell:

```text
UI
 ↓
Repository
 ↓
SQLite
 ↓
Sync Outbox
 ↓
Internet verfügbar?
 ↓
Remote Backend
 ↓
andere Geräte
```

SQLite ist während des Betriebs die lokale Single Source of Truth.

Reads erfolgen primär lokal.

Writes erfolgen ebenfalls lokal.

Beispiel:

```text
User bearbeitet Asset
        ↓
SQLite Update
        +
Sync Queue Entry
        ↓
UI sofort aktualisiert
        ↓
Internet wieder verfügbar
        ↓
Sync Worker
        ↓
Backend
        ↓
Team erhält Update
```

---

# 20. Sync-Outbox

Mutation und Sync-Eintrag müssen atomar gespeichert werden.

```text
BEGIN TRANSACTION

UPDATE asset

INSERT sync_outbox

COMMIT
```

Es darf kein Zustand entstehen:

```text
lokale Änderung gespeichert
aber
Sync vergessen
```

---

# 21. Konfliktbehandlung

Offline-Bearbeitung kann Konflikte erzeugen.

AppForge muss deshalb Sync-Strategien vorsehen.

Mögliche Strategien:

```text
Last Write Wins
Server Wins
Client Wins
Field-level Merge
Manual Review
Append-only
```

Nicht jede Strategie passt zu jeder Entity.

Beispiel:

```text
Movement
```

sollte eher append-only sein.

```text
Asset description
```

kann eine andere Konfliktstrategie erhalten.

---

# 22. Rollen und Berechtigungen

Rollen gehören zur Projektspezifikation.

Beispiel:

```text
Owner
Administrator
Manager
Employee
Viewer
```

Für jede Rolle werden festgelegt:

```text
sichtbare Screens
Create
Read
Update
Delete
Approve
Export
Manage Users
Manage Settings
```

Die UI-Berechtigung allein reicht nicht.

Produktive Backends müssen Berechtigungen zusätzlich serverseitig erzwingen.

---

# 23. Design-Konfiguration

Der Nutzer soll das Design beeinflussen können, ohne ein komplettes UI-System manuell bauen zu müssen.

Konfigurierbar:

```text
Primary Color
Secondary Color
Surface Color
Dark Mode
Logo
App Icon
Typography
Corner Radius
Spacing Density
Navigation Style
Component Variants
```

---

# 24. Boolean UI Mapping

Boolean-Felder sollen nicht automatisch immer gleich dargestellt werden.

Beispiel:

```text
isActive
```

kann sein:

```text
Switch
```

während:

```text
termsAccepted
```

besser ist als:

```text
Checkbox
```

AppForge kann eine Empfehlung geben.

Der Nutzer darf sie innerhalb sinnvoller Grenzen ändern.

Konzeptionell:

```yaml
field:
  name: active

ui:
  control: switch
```

oder:

```yaml
field:
  name: termsAccepted

ui:
  control: checkbox
```

---

# 25. Logo- und Icon-System

Der Nutzer soll:

```text
Logo hochladen
Logo zuschneiden
Hintergrund wählen
einfache Farben ändern
App Icon erzeugen
Symbol auswählen
Symbolgröße ändern
Symbolposition ändern
```

können.

Generierte Assets werden automatisch für Zielplattformen vorbereitet.

Später:

```text
iOS AppIcon
Android Adaptive Icon
macOS Icon
Web favicon
Windows Icon
```

---

# 26. Zielplattformen

Der Nutzer kann bestimmen, welche Plattformen generiert werden.

Geplant:

```text
iOS
Android
Web
macOS
Windows
Linux
```

Frameworkabhängig:

```text
Flutter
  ├── iOS
  ├── Android
  ├── Web
  ├── macOS
  ├── Windows
  └── Linux

SwiftUI
  ├── iOS
  └── macOS

Compose
  └── Android
```

---

# 27. Preview

Vor der Generierung soll ein Projekt überprüfbar sein.

Mindestens:

```text
Projektübersicht
Screens
Navigation
Rollen
Entities
Backend
Packages
Design Tokens
Zielplattformen
```

Später soll daraus ein interaktiver Preview-Modus entstehen.

---

# 28. Fehlerbehandlung

AppForge Pro selbst und generierte Apps sollen keine unkontrollierten Fehlerzustände verwenden.

Beispielhafte Fehlerstruktur:

```text
AppError
├── validation
├── configuration
├── authentication
├── network
├── persistence
├── synchronization
├── permission
├── generation
└── unknown
```

UI erhält nutzerfreundliche Fehler.

Logs erhalten technische Details.

Keine sensitiven Daten werden geloggt.

---

# 29. Generator-Ausgabe

Eine generierte Flutter-Business-App soll mindestens erhalten:

```text
README.md

docs/
├── START_HERE.md
├── NEXT_STEPS.md
├── DATABASE_SETUP.md
├── DATA_ARCHITECTURE.md
├── OFFLINE_SYNC.md
├── ROLES_AND_PERMISSIONS.md
├── PRODUCTION_READINESS.md
└── RELEASE_GUIDE.md

analysis_options.yaml

.github/
└── workflows/
    └── ci.yml

scripts/
├── appforge_doctor.sh
├── run_ios.sh
├── run_android.sh
├── test.sh
└── build_release.sh

config/
├── development.json.example
├── staging.json.example
└── production.json.example

appforge.yaml
forge.lock
```

---

# 30. Quality Gates

Eine Generierung gilt nicht automatisch als erfolgreich, nur weil Dateien geschrieben wurden.

Geplante Flutter Gates:

```text
dart format
flutter analyze
flutter test
generator tests
architecture tests
optional integration tests
flutter build
```

Swift:

```text
swift build
swift test
xcodebuild
```

Compose:

```text
gradle test
lint
build
```

---

# 31. Release Center

Nach erfolgreicher Abnahme soll AppForge Pro den Release vorbereiten.

Ziel:

```text
Development
     ↓
Staging
     ↓
Production Readiness
     ↓
Release Build
     ↓
Store
```

Geplante Unterstützung:

```text
Version
Build Number
Bundle Identifier
Package Name
Signing Hinweise
Store Assets
Privacy Hinweise
Release Notes
Android Build
iOS Archive
```

AppForge darf dabei niemals private Signing-Schlüssel unsicher verwalten.

---

# 32. Business Templates

Packages sind technische Fähigkeiten.

Templates beschreiben konkrete Produkte.

Beispiel:

```text
Inventory & Asset Management
```

kann zusammengesetzt sein aus:

```text
forge-core
forge-design-system
forge-auth
forge-business
forge-profile
forge-inventory
forge-offline-sync
forge-notifications
forge-supabase
```

---

# 33. Erste Golden Reference

Die erste professionelle Referenz bleibt:

> **Inventar & Assets**

Sie dient jedoch nur als **Testprodukt für die Generatorplattform**, nicht als Definition von AppForge Pro.

Mögliche Entities:

```text
Asset
Location
InventoryItem
Movement
Customer
CustomerContact
WorkOrder
WorkOrderLine
ApprovalRequest
ChangeRequest
Allocation
User
Profile
Organization
Membership
```

Mit:

```text
Rollen
Mandanten
Offline
Sync
Audit
Freigaben
Suche
Filter
Reporting
Export
Planung
```

Wenn AppForge Pro dieses Produkt reproduzierbar erzeugen kann, beweist es viele Kernfähigkeiten der Plattform.

---

# 34. Weitere geplante Business Templates

Später unter anderem:

```text
Inventory Management
Asset Management
Field Service
CRM
Order Management
Employee Operations
Event Operations
Facility Management
Maintenance
Booking
Project Management
Service Desk
Customer Portal
Approval Workflow
Document Management
```

---

# 35. Entwicklungsstrategie

Wir beginnen bewusst erneut und bauen diesmal vom Produktvertrag nach innen.

Reihenfolge:

```text
01 Product Definition
02 Xcode Project Setup
03 Domain Model
04 ProjectSpecification
05 App Shell
06 Business Wizard
07 Registry Contract
08 Package Contract
09 Dependency Resolver
10 forge.lock
11 Package Downloader
12 Generator Contract
13 Flutter Renderer
14 Demo Authentication
15 Offline-first Foundation
16 Supabase Adapter
17 Firebase Adapter
18 Design Editor
19 Preview
20 Quality Center
21 Release Center
22 Golden Reference
23 SwiftUI Renderer
24 Compose Renderer
```

Kein Modul wird gebaut, nur weil es technisch interessant ist.

Jeder Schritt muss einen klaren Teil der Produktpipeline ermöglichen.

---

# 36. GitHub Workflow

Alle Änderungen folgen:

```text
Issue
 ↓
Feature Branch
 ↓
Implementation
 ↓
Tests
 ↓
Commit
 ↓
Push
 ↓
Pull Request
 ↓
Review
 ↓
CI
 ↓
Merge
```

Branch-Namen:

```text
feature/<issue>-<description>
fix/<issue>-<description>
docs/<issue>-<description>
refactor/<issue>-<description>
```

Beispiel:

```text
feature/1-project-setup
```

---

# 37. Branch-Strategie

Geplant:

```text
main
  ↑
develop
  ↑
feature/*
```

`main`

enthält Releases.

`develop`

enthält den nächsten integrierten Produktstand.

Features entstehen niemals direkt auf `main`.

---

# 38. Commit-Konvention

Conventional Commits:

```text
feat:
fix:
docs:
test:
refactor:
build:
ci:
chore:
```

Beispiel:

```text
feat(project-setup): add initial macOS SwiftUI architecture
```

---

# 39. Pull Requests

Jeder PR beschreibt:

```text
Problem
Ziel
Implementierung
Architekturentscheidung
Tests
Risiken
Screenshots falls UI
Definition of Done
```

Kein Merge nur aufgrund von „funktioniert bei mir“.

---

# 40. GitHub Board

Das Projektboard soll mindestens enthalten:

```text
Backlog
Ready
In Progress
Review
Testing
Blocked
Done
```

Sinnvolle Felder:

```text
Status
Priority
Epic
Area
Platform
Milestone
Risk
Estimate
```

---

# 41. Dokumentation

Die Dokumentation ist Teil des Produkts.

Geplant:

```text
docs/
├── PRODUCT_VISION.md
├── PRD.md
├── ROADMAP.md
│
├── architecture/
│   ├── OVERVIEW.md
│   ├── ADR-001-project-architecture.md
│   ├── ADR-002-package-system.md
│   └── ADR-003-generator-contract.md
│
├── development/
│   ├── GETTING_STARTED.md
│   ├── GIT_WORKFLOW.md
│   └── CONTRIBUTING.md
│
├── generator/
│   ├── PROJECT_SPECIFICATION.md
│   ├── PACKAGE_CONTRACT.md
│   └── LOCKFILE.md
│
└── testing/
    └── TEST_STRATEGY.md
```

---

# 42. Testing-Strategie

AppForge Pro benötigt mehrere Testebenen.

## Unit Tests

Für:

```text
Domain
Validation
Resolver
Version Selection
Mappings
Policies
```

## Integration Tests

Für:

```text
Registry → Resolver
Resolver → Generator
Generator → File System
```

## Golden Tests

Für Generator-Ausgaben.

Eine Generatoränderung darf nicht unbemerkt hunderte Projektdateien verändern.

## End-to-End Tests

Beispiel:

```text
ProjectSpecification
      ↓
Resolve
      ↓
Generate Flutter Project
      ↓
flutter pub get
      ↓
flutter analyze
      ↓
flutter test
      ↓
PASS
```

---

# 43. Security

Security ist kein späteres Zusatzfeature.

Grundregeln:

* keine Service Role Keys im Client
* keine Admin Keys im Client
* keine Secrets in generierten Repositories
* Environment-spezifische Konfiguration
* serverseitige Autorisierung
* Rollenprüfung nicht nur im UI
* Least Privilege
* sichere Logs
* Input Validation
* sichere lokale Speicherung
* HTTPS für Remote-Kommunikation
* Dependency-Integrität prüfen
* Package-Versionen locken

---

# 44. Daten- und Mandantentrennung

Business Apps sollen mehrere Unternehmen unterstützen können.

Grundmodell:

```text
User
  ↓
Membership
  ↓
Organization
  ↓
Business Data
```

Nicht:

```text
User
  ↓
alle Daten
```

Für Supabase werden RLS Policies generiert.

Für andere Backends werden äquivalente serverseitige Regeln benötigt.

---

# 45. Keine proprietäre Runtime

Ein wichtiges Nicht-Ziel:

Die generierte App benötigt AppForge Pro nicht zur Laufzeit.

Nach der Generierung:

```text
AppForge Pro
    X
Runtime Dependency
```

Stattdessen:

```text
AppForge Pro
    ↓
Source Code
    ↓
normales Softwareprojekt
```

---

# 46. Keine String-Rewrite-Architektur

Generatoren dürfen keine fertigen Projekte über unkontrollierte Regex-Ersetzungen umbauen.

Nicht:

```text
generate default project
        ↓
replace "Riverpod" with "Bloc"
        ↓
hope it works
```

Sondern:

```text
ProjectSpecification
        ↓
StateManagementStrategy
        ↓
richtige Templates / Generator Components
```

Dasselbe gilt für:

```text
Backend
Navigation
Authentication
State Management
Design
Offline Mode
```

---

# 47. Definition of Done für generierte Anwendungen

Eine Anwendung gilt nur dann als gültig, wenn:

* Projekt vollständig generiert wurde
* benötigte Packages aufgelöst wurden
* Lockfile vorhanden ist
* Formatierung erfolgreich ist
* Analyzer/Linter erfolgreich ist
* Tests erfolgreich sind
* keine Secrets enthalten sind
* Rollenmodell konsistent ist
* Offline-Konfiguration konsistent ist
* Datenbank-Anleitung vorhanden ist
* README vorhanden ist
* Release-Anleitung vorhanden ist

---

# 48. Definition of Done für AppForge-Pro-Features

Ein Feature ist fertig, wenn:

* Issue vorhanden
* Akzeptanzkriterien erfüllt
* Architekturregeln eingehalten
* Tests vorhanden
* relevante Dokumentation aktualisiert
* keine bekannten Analyzer-Warnungen
* PR Review abgeschlossen
* CI erfolgreich
* Merge erfolgt

---

# 49. MVP

Der erste produktive MVP soll Folgendes ermöglichen:

```text
AppForge Pro öffnen
        ↓
Neues Projekt
        ↓
Name eingeben
        ↓
Business Template wählen
        ↓
Zielplattform Android + iOS
        ↓
State Management wählen
        ↓
SQLite + Supabase wählen
        ↓
Rollen konfigurieren
        ↓
Branding konfigurieren
        ↓
Preview
        ↓
Generate
        ↓
Flutter Project
        ↓
Demo-Login
        ↓
Offline CRUD
        ↓
Database Setup Guide
```

---

# 50. MVP-Abnahme

Der MVP gilt als erfolgreich, wenn AppForge Pro eine neue Anwendung erzeugen kann, die ohne manuelle Architekturarbeit:

```text
startet
Demo-Login unterstützt
mehrere Rollen besitzt
CRUD unterstützt
offline funktioniert
später synchronisiert werden kann
flutter analyze besteht
Tests besteht
eine Datenbank-Anleitung enthält
eine Release-Anleitung enthält
```

---

# 51. Langfristiges Ziel

Langfristig soll AppForge Pro aus derselben fachlichen Spezifikation mehrere Implementierungen erzeugen können.

```text
                 ProjectSpecification
                          │
                          ▼
                     Forge Packages
                          │
                          ▼
                    Resolved Graph
                          │
             ┌────────────┼────────────┐
             │            │            │
             ▼            ▼            ▼
         Flutter       SwiftUI      Compose
```

Business-Logik soll dabei möglichst aus gemeinsamen deklarativen Verträgen stammen.

Renderer setzen diese Verträge frameworkspezifisch um.

---

# 52. Zukünftige AI-Unterstützung

KI kann später helfen:

```text
Anforderungen verstehen
Business Template empfehlen
Datenmodelle vorschlagen
Rollen vorschlagen
Packages auswählen
Konflikte erklären
Dokumentation erzeugen
```

KI darf jedoch nicht zur Voraussetzung für reproduzierbare Generierung werden.

Der deterministische Generator bleibt die Source of Truth.

---

# 53. Nicht-Ziele der ersten Version

AppForge Pro wird zunächst ausdrücklich nicht:

* vollständiger FlutterFlow-Klon
* allgemeiner Drag-and-Drop-App-Builder
* eigener Cloud-Provider
* eigenes Auth-System
* eigene Datenbankplattform
* unkontrollierter KI-Codegenerator
* Marketplace
* vollständiger visueller Programmiersprachen-Editor

Wir bauen zuerst:

> **Business-Konfiguration → getestete Packages → deterministischer professioneller Source Code.**

---

# 54. Projektgrundsatz

Bei Architekturentscheidungen gilt:

> AppForge Pro soll keine schnellen Tricks erzeugen, sondern dieselben Strukturen verwenden, die wir bei einem professionellen langfristigen Softwareprojekt selbst einsetzen würden.

Und für die Nutzeroberfläche:

> Der Unternehmer entscheidet über sein Geschäft und sein Produkt. AppForge Pro übersetzt diese Entscheidungen in Softwarearchitektur.

---

# 55. Neustart-Regel

Vorherige AppForge-, CF- und Business-Forge-Implementierungen gelten ab diesem Neustart als:

```text
Research
Reference
Lessons Learned
```

und nicht automatisch als neue Produktionsbasis.

Code wird nur übernommen, wenn er:

```text
zum neuen Produktmodell passt
architektonisch sauber ist
getestet ist
dokumentiert ist
keine historische Sonderlösung enthält
```

Damit verhindern wir, dass alte Architekturfehler direkt in den Neustart übernommen werden.

---

# 56. Nächster Meilenstein

## Milestone 1 — Project Foundation

Ziel:

> Eine saubere, startbare native macOS-SwiftUI-App als Fundament von AppForge Pro.

Enthalten:

* Xcode-Projekt
* macOS SwiftUI Target
* Feature-First-Grundstruktur
* Domain/Application/Data/Presentation-Grenzen
* Dependency Composition Root
* Error Foundation
* Logging Foundation
* Design-System-Grundlage
* Unit-Test-Target
* GitHub Workflow
* Issue
* Feature Branch
* Commit
* Pull Request
* Review
* Merge
* initiale Architektur-Dokumentation

Noch nicht enthalten:

```text
Generator
Registry
Resolver
Flutter Output
Backend
Inventory
```

Diese Funktionen folgen kontrolliert auf dem neuen Fundament.

---

# 57. Kurzfassung

```text
AppForge Pro
ist eine native macOS-App,

mit der Unternehmer
Business-Anwendungen konfigurieren,

vor dem Backend-Setup
mit verschiedenen Rollen testen,

Design, Datenbank, Plattformen,
Offline-Verhalten und Funktionen wählen

und anschließend

professionellen,
getesteten,
wartbaren,
editierbaren Source Code

für

Flutter,
später SwiftUI
und Jetpack Compose

generieren können.
```

---

**AppForge Pro — configure the business, generate the software.**
