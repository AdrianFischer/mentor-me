# Side Hustle Strategy Summary

Kompakte Zusammenfassung der wichtigsten Erkenntnisse aus beiden Deep Research Reports. Diese Datei dient als schneller Kontext wenn die vollen Reports zu groß für den Context sind.

## Markt

- WMS-Services-Markt Europa: ~830 Mio USD/Jahr, 80% davon Services/Integration
- WMS-Markt Deutschland: ~214 Mio USD (2025), DACH geschätzt ~250-320 Mio USD
- Warehouse-Automation Europa: 5,76 Mrd USD (2025) → 15,43 Mrd USD (2031)
- iPaaS global: 15,63 Mrd USD (2025) → 108,76 Mrd USD (2034)

## Pricing-Benchmarks

- BDU-Tagessatz Consulting DACH: Ø 1.300€/Tag (Partner ~1.600€, Analyst ~700€)
- Freelancer-Stundensatz DE: Ø 104€, SAP-Umfeld Ø 117€
- Mittlerer Connector (Marktpreis): ~13.000€
- Dein Angebot: Blueprint Sprint 1.300-3.900€ | Connector 5-13k€ | Retainer monatlich

## Validiertes Problem (Fraunhofer-Studie)

- 81% Verzögerungen durch Personalkapazitätsengpässe auf Kundenseite
- 73% durch Scope-Expansion
- 70% durch "Kunde kennt eigene Prozesse nicht"
- Top-Kriterium bei WMS-Auswahl: "Einfache Integration in bestehende Prozesse/IT"

## Marktlücke

Zwischen teuren Systemintegratoren (Accenture/Capgemini, BDU-Overhead) und überforderten Kunden (iPaaS braucht interne Kompetenz die fehlt). Es fehlt ein "Zwischenprodukt": productized Integration + Prozessklärung, günstig aber schnell.

## Strategie: Productized Service

### Stufe 1 — Blueprint Sprint (Fixpreis ~2-3k€)
- Prozesslandkarte (Order → Picking → Shipping → Inventory)
- Datenobjekt-Katalog + Source-of-Truth pro Feld
- Integrations-Backlog + Risiko-Register
- 1 Happy-Path End-to-End Demo-Flow
- Löst das #1-Problem sofort ("Kunde versteht Prozesse nicht")

### Stufe 2 — Connector-in-a-Box (Fixpreis ~5-13k€)
- Werkvertrag (BGB §631) mit klaren Abnahmekriterien
- Supported happy path + definierte Exceptions + Monitoring + Runbook
- Change-Order-Mechanik gegen Scope-Creep

### Stufe 3 — Retainer (monatlich ~500-1.500€)
- Monitoring, Error-Triage, kleine Anpassungen
- Monatlicher Reconciliation-Report
- Recurring Revenue = Business statt Freelancing

## Technischer Ansatz

### MVP (2 Arbeitstage): File-to-API Integration Generator
- Input: CSV/Excel + Ziel-API-Spec (OpenAPI/REST)
- Processing: AI-MappingSpec mit Confidence Scores
- Output: FastAPI Bridge Service (Pydantic, Tenacity retries, OpenTelemetry, DLQ)
- Kein SAP, kein EDI im MVP — nur File-to-REST

### AI-Mapping Pipeline
1. Profiling & Schema Inference (deterministisch, Pandera)
2. Candidate Generation (LLM + Retrieval, ReMatch/Magneto-Logik)
3. Confidence Scoring + Human Gate (nur Low-Confidence/High-Impact)
4. Codegen: Transformations + FastAPI Bridge + pytest Tests

### SAP-Strategie
- OData-first (HTTP, sauberer): wenn verfügbar, immer bevorzugen
- RFC/IDoc als Enterprise-Pfad: mit Setup-Checklisten + Review-Gates
- PyRFC für Python-Anbindung (braucht SAP NetWeaver RFC SDK vom Kunden)
- Lizenzen: Kunde stellt technische User bereit, du baust "gegen" deren System

### 10 häufigste Integrationsszenarien
1. Artikel-/Material-Stammdaten (Tage)
2. Lagerstruktur & Locations (Tage)
3. Inbound Order / Delivery (Tage-Wochen)
4. Wareneingangsbestätigung (Tage)
5. Outbound Order Release (Tage-Wochen)
6. Pick/Pack/Ship Confirmation (Tage-Wochen)
7. Inventory Visibility / ATP Feed (Stunden-Tage)
8. Inventur / Cycle Count (Tage)
9. Returns / Reverse Logistics (Tage-Wochen)
10. EDI-basierte Partnerintegration (Wochen)

### Flywheel
- Mapping Registry: (source_schema, target_schema) → bestätigte Mappings + Edge Cases
- Failure Taxonomy: UoM-Mismatch, fehlende Stammdaten, Status-Konflikte
- Auto-generated Checklists pro Technologiepfad
- Jede Integration macht die nächste schneller

## Wettbewerber-Landscape

| Segment | Player | Relevanz |
|---|---|---|
| Enterprise Integratoren | Accenture, Capgemini, IBM | Zu teuer/schwer für dein Segment |
| iPaaS SMB | Make, n8n, Zapier | Brauchen interne Kompetenz die fehlt |
| iPaaS Enterprise | Workato, Tray.ai | Starke SAP-Story, aber Enterprise-Pricing |
| Embedded iPaaS | Prismatic | "Build once, deploy to customers" Modell |
| Data Integration | Airbyte, Meltano/Singer | ELT-Bausteine für Datenpipelines |
| EDI/B2B | Stedi | Partner-Connectivity, späteres Upsell |

## Rechtliches (DE)

- UG reicht für den Start (kein UG-Stigma bei B2B-IT-Services dieser Größe)
- Schriftliche Nebentätigkeits-Freigabe einholen (§60 HGB: keine wettbewerbliche Tätigkeit)
- AVV/DPA-Vorlage + TOM-Anhang für DSGVO (Art. 28/32)
- Werkvertrag für Blueprint + Connector, Dienstvertrag für Retainer
- Strikte Trennung: keine Arbeitgeber-Assets, keine Arbeitszeit, keine Kundendaten

## Risiken

1. Employer-Konflikt/IP (größtes Risiko — schriftliche Freigabe ist Pflicht)
2. Scope-Creep (73% der Projekte betroffen — Werkvertrag + Change-Order schützen)
3. Betriebsstabilität (Integration ist nie "fertig" — Retainer adressiert das)
4. DSGVO/AVV (sauberes Security-Setup + Processor-Verträge nötig)
