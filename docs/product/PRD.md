# Product Requirements Document

## Produktziel

Ein Unternehmer kann eine SAP-ähnliche, prozessorientierte Business-Anwendung ohne Programmierkenntnisse fachlich konfigurieren, mit Demo-Rollen prüfen, als professionelles Flutter-Projekt generieren und anschließend geführt mit Backend und Store verbinden.

„SAP-ähnlich“ beschreibt Business-Prozesse, Rollen, Stammdaten und Freigaben. Eine direkte SAP-Integration ist ein späteres, separates Integrationspaket.

## Personas

### Unternehmer

Kennt den Geschäftsprozess, aber nicht notwendigerweise Softwarearchitektur, Datenbankregeln oder Store-Signing.

### Endnutzer

Arbeitet später in der erzeugten Anwendung als Owner, Administrator, Manager, Mitarbeiter, Prüfer oder Betrachter.

### Entwickler oder Agentur

Benötigt reproduzierbaren, erweiterbaren Code und eine vollständig nachvollziehbare Entwicklungshistorie.

## Funktionale Anforderungen

### AF-ENT-001 — Geführte App-Erstellung

Als Unternehmer möchte ich Business-Anwendungen anhand weniger Eckdaten generieren, damit ich ohne Programmierkenntnisse ein passendes Ausgangsprodukt erhalte.

Akzeptanz:

- Fachfragen verwenden reale Beispiele und erklären den Nutzen.
- Unsinnige oder unsichere Kombinationen werden verhindert.
- Eine Business-Vorlage setzt alle empfohlenen Optionen vollständig voraus.
- Vor der Generierung ist eine verständliche Zusammenfassung sichtbar.

### AF-ENT-002 — Framework und Zielplattformen

Als Unternehmer möchte ich Framework und Zielplattformen wählen, damit nur benötigte Projekte und Plattformdateien entstehen.

MVP: Flutter mit iOS und Android. Weitere Plattformen sind sichtbar als Roadmap, aber nicht fälschlich als produktiv markiert.

### AF-ENT-003 — Datenbankentscheidung mit Hilfestellung

Als Unternehmer möchte ich Datenbanken anhand kurzer Einsatzszenarien vergleichen, damit ich eine passende und bezahlbare Wahl treffe.

MVP-Optionen:

- Nur lokal: Einzelgerät oder vollständig lokale Daten
- SQLite + Supabase: relationale Geschäftsdaten, Mandanten, Rollen und Reporting
- SQLite + Firebase: Google-Ökosystem und stark ereignisorientierte mobile Workflows

Nach der Generierung entstehen providerbezogene Migrationen, Sicherheitsregeln, Tests und eine Schritt-für-Schritt-Anleitung. Cloud-Projekte werden nur nach expliziter Bestätigung verbunden.

### AF-ENT-004 — State Management

Als Unternehmer möchte ich State Management über kurze Empfehlungen wählen können, ohne Architekturdetails verstehen zu müssen.

- Riverpod ist der empfohlene Flutter-Standard.
- BLoC/Cubit ist eine Alternative für große Teams und explizite Zustandsautomaten.
- MVVM wird nicht angeboten, weil es für alle erzeugten Apps verpflichtend ist.

### AF-ENT-005 — Rollenbasierter Evaluationsmodus

Als Unternehmer möchte ich vor dem Backend-Setup jede konfigurierte Rolle testen.

- AppForge erzeugt lokale Demo-Konten und realistische Beispieldaten.
- Rollen, sichtbare Navigation und erlaubte Aktionen unterscheiden sich tatsächlich.
- Demo-Zugänge sind in Production Builds technisch deaktiviert.
- Ein Rollen-Testprotokoll zeigt erlaubte und verbotene Kernabläufe.

### AF-ENT-006 — Offline und Synchronisierung

Als Nutzer möchte ich Daten offline lesen und bearbeiten und nach Wiederherstellung der Verbindung automatisch mit dem Team synchronisieren.

- SQLite ist die lokale Single Source of Truth.
- Mutation und Outbox-Eintrag werden atomar gespeichert.
- Wiederholungen sind idempotent.
- Konfliktstrategie wird je Entity festgelegt.
- Sync-Status und nicht automatisch lösbare Konflikte sind verständlich sichtbar.

### AF-ENT-007 — Datenmodell und Beziehungen

Als Unternehmer möchte ich Entities, Attribute und Beziehungen modellieren, ohne IDs manuell bestimmen zu müssen.

- Identifikatoren werden aus Provider, Offline-Strategie und Beziehungstyp abgeleitet.
- Attribute können Pflichtfeld, Typ, Validierung, Datenschutzklasse und UI-Darstellung besitzen.
- Beziehungen unterstützen Löschstrategie und Mandantengrenze.

### AF-ENT-008 — Variables Design

Als Unternehmer möchte ich Farben, Logo, App-Symbole und zulässige Komponentenvarianten bestimmen.

- Design Tokens sichern Kontrast, Lesbarkeit und Konsistenz.
- Boolean-Felder können abhängig vom Zweck als Checkbox, Switch oder Statusdarstellung erscheinen.
- Einwilligungen werden nicht als Switch empfohlen; aktive Zustände nicht als Vertrags-Checkbox.
- Logo- und Icon-Editor erzeugen zielplattformspezifische Assets.

### AF-ENT-009 — Release Center

Als Unternehmer möchte ich nach erfolgreicher Abnahme Store-Releases durchführen.

- AppForge prüft Bundle-/Application-ID, Version, Icons, Datenschutzangaben und Build-Konfiguration.
- Signing-Schlüssel bleiben außerhalb von Repository und Generator-Manifest.
- iOS und Android erhalten getrennte, konkrete Release-Checklisten.
- Veröffentlichung bleibt eine bewusste, bestätigte Aktion.

### AF-DEV-001 — Architekturvertrag

AppForge Pro und erzeugte Anwendungen folgen Clean Code, KISS, DRY, SOLID, Feature-First, MVVM, Repository Pattern, Use Cases, Dependency Injection und SSOT.

### AF-DEV-002 — Fehlerbehandlung

- technische Fehler werden typisiert
- UI zeigt nutzerfreundliche Meldungen und nächste Schritte
- Logs enthalten Diagnoseinformationen, aber keine Secrets oder unnötigen Personendaten
- Generatorfehler hinterlassen keine teilweise gültigen Zielprojekte

### AF-DEV-003 — Reproduzierbarkeit

- ProjectSpecification ist ein unveränderlicher Snapshot
- Package-Versionen und Renderer werden gelockt
- Golden Tests erkennen unbeabsichtigte Generatoränderungen

### AF-DEV-004 — Entwicklungsnachweis

Jede Änderung besitzt Issue, Branch, Tests, signierten Commit, PR, Review/CI und Merge. Notion enthält Produktkontext; GitHub bleibt Source of Truth für ausführbare Arbeit.

## Qualitätsanforderungen

- keine Warnungen in unterstützten Compiler-/Analyzer-Konfigurationen
- automatisierte Unit-, Integrations-, Architektur-, Golden- und End-to-End-Tests
- Tastaturbedienung, VoiceOver-Beschriftungen und ausreichende Kontraste
- keine Secrets in generierten Projekten
- serverseitige Mandanten- und Rollenprüfung
- verständlicher Abbruch und Wiederaufnahme langer Generierungen

## MVP-Erfolg

Der MVP ist erreicht, wenn ein fachlicher Nutzer eine Golden-Reference-App ohne Codeänderung konfigurieren, lokal mit allen Rollen testen, offline bedienen, über eine geführte Supabase-Einrichtung in Staging synchronisieren und erfolgreich als iOS- sowie Android-Testrelease bauen kann.
