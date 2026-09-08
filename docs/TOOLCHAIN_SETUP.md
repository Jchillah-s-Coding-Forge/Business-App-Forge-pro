# Toolchain Setup und Environment Doctor

## Ziel

AppForge Pro erzeugt Quellcode nur dann, wenn die für die ausgewählten Zielplattformen zwingend benötigte lokale Toolchain einsatzbereit ist. Der Environment Doctor trennt deshalb zwischen erforderlichen Build-Werkzeugen und optionalen Komfort-/Backend-Werkzeugen.

AppForge installiert keine Systemsoftware still. Jede Installation oder Weiterleitung erfordert eine ausdrückliche Nutzeraktion.

## Readiness-Vertrag

Für Flutter gelten aktuell folgende Pflichtwerkzeuge:

- immer: Git und Flutter SDK
- Apple-Ziele: vollständiges Xcode inklusive aktivem Command-Line-Tools-Developer-Directory
- Android: vollständiges Android SDK und kompatibles JDK

Optionale Werkzeuge blockieren die Generierung nicht:

- VS Code
- Android Studio
- XcodeGen
- Supabase CLI
- Docker-kompatible CLI

`ToolchainReport.isReady` und `ToolchainReadinessGate` sind die verbindliche Generator-Grenze. Ein Renderer oder Generator darf erforderliche Fehler nicht ignorieren oder automatisch herunterstufen.

## Flutter

Ein vorhandenes Flutter SDK kann über seinen SDK-Root ausgewählt werden. Der Root muss `bin/flutter` enthalten.

Fehlt Flutter, kann der Nutzer einen vorhandenen, beschreibbaren Elternordner auswählen. `VerifiedFlutterSDKInstaller`:

1. ermittelt das aktuelle stabile macOS-Release aus dem offiziellen Flutter-Manifest,
2. akzeptiert nur die erwartete offizielle Storage-Quelle,
3. lädt das Architektur-passende SDK,
4. prüft SHA-256 vor dem Entpacken,
5. entpackt in einen temporären Staging-Ordner,
6. validiert `bin/flutter --version`,
7. verschiebt das validierte SDK atomar nach `<Ziel>/flutter`,
8. überschreibt nie einen vorhandenen `flutter`-Eintrag,
9. räumt temporäre Artefakte auch bei Fehlern auf.

Alternativ führt AppForge über eine explizite Setup-Aktion zur offiziellen Flutter-/VS-Code-Anleitung.

## Apple Toolchain

Die Xcode-Prüfung besteht aus zwei Teilen:

- `xcode-select -p` muss ein aktives Developer Directory liefern,
- das aktive Verzeichnis muss zu einer vollständigen `.app/Contents/Developer`-Installation gehören,
- `xcodebuild -version` muss erfolgreich ausführbar sein,
- die erkannte Xcode-Version muss die hinterlegte Mindestversion erfüllen.

Standalone Command Line Tools allein gelten für Apple-App-Builds nicht als vollständige Xcode-Toolchain.

Fehlt Xcode, öffnet AppForge auf Nutzeraktion den offiziellen Apple-App-Store-Eintrag. AppForge führt keine stille Xcode-Installation aus.

## Android Toolchain

Die Android-SDK-Prüfung akzeptiert `ANDROID_SDK_ROOT`, `ANDROID_HOME` oder den macOS-Standardpfad `~/Library/Android/sdk`.

Ein SDK gilt nur als vollständig, wenn mindestens vorhanden sind:

- `platform-tools/adb`,
- Command-line Tools mit ausführbarem `sdkmanager`,
- mindestens ein Build-Tools-Paket,
- mindestens eine installierte Android-Plattform,
- vorhandene SDK-Lizenzdaten.

Zusätzlich wird die Platform-Tools-Version über `adb version` geprüft. Das JDK wird separat validiert.

AppForge akzeptiert oder verändert Android-Lizenzen nicht still. Wenn Komponenten fehlen, verweist die UI auf den offiziellen Android-Studio-Setupweg.

## Optionale Entwickler- und Backend-Werkzeuge

XcodeGen, Supabase CLI und Docker werden erkannt, sind aber nicht global erforderlich. Sie werden erst in späteren Generator-/Backend-Slices kontextabhängig zu Pflichtanforderungen, wenn die konkrete Projektkonfiguration sie benötigt.

Damit bleibt ein reines Flutter-Projekt ohne lokalen Supabase-Stack generierbar, auch wenn Supabase CLI oder Docker fehlen.

## Report-Export

Der Environment Doctor kann den aktuellen `ToolchainReport` als JSON speichern. Der Export verwendet:

- ISO-8601 für Datumswerte,
- sortierte JSON-Schlüssel,
- Pretty Printing,
- atomisches Schreiben.

Damit erzeugt derselbe Report byte-identische JSON-Ausgabe und kann für Support, reproduzierbare Builds und spätere CI-Vergleiche verwendet werden.

## IDE-Handoff

Die bevorzugte IDE ist eine Nutzerpräferenz und keine Runtime-Abhängigkeit. Unterstützt sind:

- VS Code,
- Android Studio,
- Xcode,
- Finder,
- Terminal.

Nach der späteren Projektgenerierung öffnet `GeneratedProjectOpening` ausschließlich den tatsächlich erzeugten Projektordner in der gewählten Umgebung.

## Sicherheitsregeln

- keine stillen Installationen,
- kein ungefragtes `sudo`,
- keine versteckten Lizenzannahmen,
- keine fremden Flutter-Downloadquellen,
- keine ungeprüften Flutter-Archive,
- keine automatischen Änderungen an Xcode-Auswahl oder Android-SDK-Komponenten,
- optionale Tools blockieren nicht global,
- erforderliche Toolchain-Fehler werden vor der Generierung hart abgewiesen.


## IDE-Handoff nach Generierung

Nach erfolgreicher Produktionsgenerierung erkennt AppForge unterstützte macOS-Entwicklungsumgebungen über Bundle-IDs und bekannte Application-Pfade. Die bevorzugte IDE wird als Primäraktion angeboten, wenn sie aktuell verfügbar ist; Finder und Systemstandard bleiben explizite Alternativen.

Der Handoff verändert den generierten Source Tree nicht und verwendet keine Shell-Kommandoketten.

Der vollständige Detection-, Command- und No-Fallback-Vertrag ist in [IDE_HANDOFF.md](IDE_HANDOFF.md) dokumentiert.
