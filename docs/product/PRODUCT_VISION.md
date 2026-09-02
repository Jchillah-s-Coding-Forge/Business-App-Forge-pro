# Product Vision

## Problem

Kleine Unternehmen und Neugründer benötigen häufig individuelle Prozesssoftware, können aber weder ein Entwicklungsteam finanzieren noch Architektur-, Backend- und Store-Entscheidungen sicher treffen. Klassische No-Code-Produkte vereinfachen den Einstieg, erzeugen jedoch oft Abhängigkeiten von einer proprietären Laufzeit.

## Vision

AppForge Pro übersetzt verständliche Geschäftsentscheidungen in normalen, getesteten und vollständig editierbaren Source Code.

```text
Geschäftsbedarf
  → geführte Fachfragen
  → unveränderliche ProjectSpecification
  → geprüfte Forge Packages
  → deterministischer Renderer
  → Quality Gates
  → Business-App + Setup- und Release-Anleitung
```

Der Unternehmer entscheidet über Prozesse, Rollen, Daten, Design und Plattformen. AppForge Pro übernimmt die technische Architektur.

## Zielgruppen

1. Unternehmer und Fachanwender ohne Programmierkenntnisse
2. Agenturen und freiberufliche Entwickler, die wiederkehrende Grundlagen automatisieren
3. Interne IT-Teams mit standardisierten Business-App-Portfolios

## Produktversprechen

- Nutzen und nächster Schritt sind auf jedem Screen erkennbar.
- Jede erzeugte Rolle kann vor dem Cloud-Setup mit einem lokalen Demo-Zugang getestet werden.
- Offline-Lesen und -Schreiben ist ein Produktstandard, wenn Team-Synchronisierung gewählt wurde.
- Backend- und State-Management-Optionen werden mit kurzen realen Einsatzszenarien erklärt.
- Architekturqualität ist kein optionaler Schalter.
- Der Nutzer besitzt das generierte Projekt; AppForge Pro ist keine Runtime-Abhängigkeit.
- Generierung endet nicht bei Dateien, sondern erst nach Format-, Analyse-, Test- und Build-Prüfungen.
- Die Übergabe enthält Datenbank-, Rollen-, Datenschutz- und Release-Anleitungen.

## Leitprinzipien

- Progressive Disclosure: Anfänger sehen Fachbegriffe nur, wenn sie wirklich helfen.
- Determinismus: Spezifikation + Lockfile + Generatorversion ergeben dieselbe Ausgabe.
- Secure by Default: keine Secrets im Client, serverseitige Autorisierung, Least Privilege.
- Offline First: lokale SSOT, atomare Mutation und Outbox, kontrollierte Konfliktstrategie.
- Open Output: normale Flutter-, SwiftUI- oder Compose-Projekte ohne proprietäre Runtime.

## Nicht-Ziele des MVP

- kein allgemeiner Drag-and-Drop-Editor
- kein eigener Cloud- oder Auth-Provider
- keine unkontrollierte KI-Codegenerierung
- kein Marketplace
- keine parallele Implementierung aller Frameworks

Der MVP beweist den vollständigen Weg für Flutter und eine Golden Reference. SwiftUI und Compose folgen erst nach reproduzierbarer Abnahme.
