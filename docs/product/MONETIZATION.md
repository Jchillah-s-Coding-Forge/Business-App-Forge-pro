# Monetization Strategy

## Grundmodell

AppForge Pro ist ein professionelles Entwicklungs- und Produktivitätswerkzeug. Der Nutzer bezahlt für Generator, geprüfte Vorlagen, Updates, Quality Gates und Release-Unterstützung – nicht für den Besitz seiner generierten Laufzeit-App.

## Preis-Hypothesen zur Validierung

Die Beträge sind Experimente und werden vor Launch durch Interviews und Zahlungsbereitschaftstests validiert.

| Plan | Zielgruppe | Hypothese | Kernumfang |
|---|---|---:|---|
| Evaluation | Ersttest | 14 Tage | vollständiger lokaler Test, keine Produktivfreigabe |
| Starter | Einzelunternehmer | 39–59 € / Monat | wenige aktive Projekte, Kernvorlagen, lokale Generierung |
| Professional | Entwickler/KMU | 99–149 € / Monat | unbegrenzte Projekte, Backends, Quality und Releases |
| Agency | Agenturen | 249–399 € / Monat | Kunden-Workspaces, White-Label, Team-Sitze, Prioritätssupport |
| Enterprise | größere Firmen | Angebot | SSO, private Registry, Audit, SLA, Onboarding |

Jahrespreise sollen einen klaren Rabatt erhalten. Ein späterer einmaliger Export- oder Supportservice ist möglich, darf aber den Source-Code-Besitz nicht einschränken.

## Technischer Billing-Vorschlag

Für den direkten, signierten und notarisierten macOS-Vertrieb:

- Stripe Billing für wiederkehrende Pläne
- Stripe Checkout Sessions für den Kauf
- Stripe Customer Portal für Wechsel, Kündigung und Zahlungsdaten
- serverseitige Entitlements; keine geheimen Stripe-Schlüssel in der macOS-App
- getrennte Test-, Staging- und Produktionsumgebungen
- signierte Webhooks und idempotente Verarbeitung

Für einen Mac-App-Store-Vertrieb wird StoreKit separat bewertet. Digitale SaaS-Funktionen und externe Kaufverweise unterliegen Apples jeweils aktuellen Review- und Regionsregeln. Bis zur rechtlichen und Store-seitigen Freigabe wird keine Mischintegration versprochen.

## Produktkatalog

Jeder Plan ist ein eigenes Produkt. Monats- und Jahrespreise sind Preise desselben Plans. Add-ons werden nur eingeführt, wenn sie einen klar messbaren Kosten- oder Nutzentreiber besitzen.

## Entitlements

Beispiele:

- Anzahl aktiver Projekte
- verfügbare Golden References
- Backend- und Release-Automation
- Team-Sitze
- private Packages
- Support-Level

Entitlements werden serverseitig signiert und lokal nur kurzzeitig gecacht. Eine abgelaufene Lizenz darf vorhandenen Source Code niemals löschen oder unzugänglich machen.

## Steuer und Compliance

Vor Aktivierung automatischer Steuerberechnung müssen tatsächliche Steuerregistrierungen vorhanden sein. Für EU-/US-Kunden werden Stripe Tax, Rechnungsanforderungen, Umsatzsteuer-ID und Aufbewahrungspflichten vor Launch fachlich geprüft.

## Messgrößen

- Aktivierung: erster valider Projektentwurf
- Aha-Moment: erste lokal getestete Rolle
- Conversion: Evaluation zu bezahltem Plan
- Time-to-Value: Zeit bis zur ersten grünen Generierung
- Retention: aktive Projekte und erfolgreiche Regenerierungen
- Qualität: Anteil der Generierungen mit grünen Gates
