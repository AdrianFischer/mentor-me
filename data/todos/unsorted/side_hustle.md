---

id: a1b2c3d4-e5f6-7890-abcd-ef1234567890

version: 1

---


# Side Hustle - Warehouse Integration Service

AI-gestützter Integrations-Service für Warehouse-Kunden. Productized Service: "Blueprint Sprint" + "Connector-in-a-Box" + Retainer.

## Markt-Kontext (aus Deep Research)

- WMS-Services-Markt Europa: ~830 Mio USD/Jahr, 80% davon Services/Integration
- Mittlerer Connector am Markt: ~13k€ (BDU-Tagessatz Ø 1.300€/Tag)
- 70% der WMS-Projektverzögerungen durch "Kunde kennt eigene Prozesse nicht" (Fraunhofer)
- Marktlücke: Zwischen teuren Systemintegratoren (Accenture, Capgemini) und überforderten Kunden
- Pricing-Referenz: Blueprint Sprint 1.300-3.900€ | Connector 5-13k€ | Retainer monatlich
- Detaillierte Recherche: data/shared/side_hustle_market_research.md + side_hustle_tech_research.md

## Technischer Ansatz (aus Deep Research)

- MVP: "CSV/Excel → AI-MappingSpec → FastAPI Bridge" (realistisch in 2 Arbeitstagen)
- AI-Mapping: ~60-80% der Felder automatisch, Rest Human-in-the-Loop (Review-Gates)
- SAP: OData-first (sauberer HTTP), RFC/IDoc als Enterprise-Pfad später
- Stack: FastAPI + PostgreSQL + Pydantic + Pandera + OpenTelemetry + Tenacity
- Flywheel: Jede bestätigte Integration → Mapping Registry → nächste Integration schneller
- Agent-Pipeline: Requirement Intake → Schema Profiling → Candidate Mapping → Codegen → Tests → PR

## Phase 1: Self-Discovery & Idea (DONE)

- [x] Write down your personal skills inventory <!-- id: sh-0101 -->
  Python, FastAPI, ROS 2, Flutter, AI agent workflows, systems thinking, process design. Senior Software & Robotics Engineer, bald Teamlead.

- [x] Identify your unfair advantages <!-- id: sh-0102 -->
  Deep domain knowledge in Warehouse-Automation, direkter Zugang zu echten Kunden über die eigene Firma, UG bereits gegründet, Google Cloud kostenlos, AI-Agent-Workflows beherrscht, Gründer der Firma steht hinter ihm.

- [x] Define your constraints and goals <!-- id: sh-0103 -->
  1 Tag pro Woche. Solo, keine Angestellten. Lean, schnelle Iterationen. Ziel: erhebliches Vermögen aufbauen. Agenten sollen die meiste Entwicklungsarbeit machen.

- [x] Brainstorm and select business idea <!-- id: sh-0104 -->
  Gewählt: AI-gestützter Integrations-Service für Warehouse-Systeme. Problem: Kunden kaufen Systeme für ~100k€ aber die Integration (ERP, SAP, Excel, Nischen-Prozesse) bleibt ungeklärt. Zu teuer für Systemintegratoren, zu komplex für Kunden, zu zeitaufwändig für Adrians Firma.

- [x] Deep Research: Markt, Wettbewerb, Recht, Playbook <!-- id: sh-0105 -->
  Ergebnis: data/shared/side_hustle_market_research.md — Markt validiert, Pricing-Bänder klar, UG reicht, Nebentätigkeits-Freigabe einholen.

- [x] Deep Research: Technische Machbarkeit & Architektur <!-- id: sh-0106 -->
  Ergebnis: data/shared/side_hustle_tech_research.md — 10 häufigste Integrationsszenarien, SAP-Deep-Dive, AI-Mapping State of the Art, MVP-Architektur, Flywheel-Strategie.

## Phase 2: Validation — Kundengespräche

- [ ] Schriftliche Nebentätigkeits-Freigabe beim Arbeitgeber einholen <!-- id: sh-0200 -->
  Arbeitsvertrag auf Nebentätigkeitsklausel und IP-Klauseln prüfen. Schriftliche Genehmigung einholen — auch wenn Chef mündlich okay sagt. Strikte Trennung: keine Arbeitgeber-Assets, keine Arbeitszeit, keine Kundendaten.

- [ ] Gründer/Chef fragen ob er Kontakte zu 3 Kunden herstellen kann <!-- id: sh-0201 -->
  Pitch: "Ich möchte verstehen wie unsere Kunden das Integrationsproblem lösen — das hilft uns als Firma und mir persönlich." Deadline: bis 22.03.2026

- [ ] Kundengespräch 1 führen (Mom Test Approach) <!-- id: sh-0202 -->
  Fragen (aus Recherche optimiert):
  (1) "Wann ist das letzte Mal ein Auftrag im Lager 'verschwunden' oder doppelt angelegt worden?"
  (2) "Welche Workarounds habt ihr heute — Excel, Copy-Paste, Screenshots? Wer macht das, wie oft?"
  (3) "Was kostet euch ein Tag Stillstand / falscher Bestand / verspäteter Versand?"
  (4) "Wenn jemand das in 2 Wochen statt 3 Monaten lösen könnte — was wäre euch das wert?"
  Ergebnis dokumentieren: Datenobjekte, Failure-Modes, Zahlungsbereitschaft.

- [ ] Kundengespräch 2 führen <!-- id: sh-0203 -->
  Gleiche Fragen, anderer Kunde. Muster erkennen.

- [ ] Kundengespräch 3 führen <!-- id: sh-0204 -->
  Gleiche Fragen. Ab 3 Gesprächen: reichen die Signale für Go/No-Go?

- [ ] Go/No-Go Entscheidung treffen <!-- id: sh-0205 -->
  Kriterien: Zahlen mindestens 2 von 3 Kunden 5.000€+ für eine Integration? Wenn ja → Phase 3. Wenn nein → neue Idee.

## Phase 3: Erster bezahlter Pilot

- [ ] Offer-Paket finalisieren (Productized Service) <!-- id: sh-0300 -->
  Drei Stufen:
  **Blueprint Sprint** (Fixpreis ~2-3k€): Prozesslandkarte, Datenobjekt-Katalog, Source-of-Truth pro Feld, Integrations-Backlog, 1 Happy-Path Demo-Flow.
  **Connector-in-a-Box** (Fixpreis ~5-13k€ je nach Scope): Werkvertrag mit klaren Abnahmekriterien (Testfälle, Acceptance-Checklist). Supported happy path + definierte Exceptions + Monitoring + Runbook.
  **Retainer** (monatlich): Monitoring, Error-Triage, kleine Anpassungen, monatlicher Reconciliation-Report.

- [ ] MVP "Integration Accelerator" bauen (2 Arbeitstage) <!-- id: sh-0301 -->
  Scope: CSV/Excel Upload → AI-MappingSpec mit Confidence Scores → FastAPI Bridge Service (Pydantic validation, Tenacity retries, OpenTelemetry tracing, DLQ). Kein SAP, kein EDI — nur File-to-REST als erste Lane.

- [ ] Einen Kunden als Pilot-Kunden gewinnen <!-- id: sh-0302 -->
  Starte mit Blueprint Sprint — niedriges Risiko für Kunden, hoher Lerneffekt für dich. Preis bewusst unter Markt (z.B. 1.500€) aber nicht kostenlos.

- [ ] Pilot-Integration liefern <!-- id: sh-0303 -->
  AI-Agenten für die Umsetzung nutzen. Dokumentieren: echte Zeit, AI-Anteil vs. manuell, Effective Hourly Rate. Ergebnis: funktionierende Integration + Erfahrungswerte.

- [ ] Feedback einholen und Prozess dokumentieren <!-- id: sh-0304 -->
  Was hat funktioniert? Was war unerwartet komplex? Wo hat AI geholfen, wo nicht? Case Study schreiben (anonymisiert).

- [ ] Zweiten und dritten Kunden abschließen <!-- id: sh-0305 -->
  Mit dem Pilot-Ergebnis als Referenz. Preis anpassen basierend auf echtem Aufwand. Referral: "Kennst du einen ähnlichen Betrieb? 1h Process-Audit gratis."

## Phase 4: Skalierung durch Automatisierung

- [ ] Wiederkehrende Integrations-Patterns identifizieren <!-- id: sh-0401 -->
  Top-10 Szenarien aus Recherche als Checkliste: Artikel-Stammdaten, Inbound Orders, GR-Bestätigung, Outbound Release, Pick/Pack/Ship, Inventory Feed, Inventur, Returns, EDI, Lagerstruktur. Welche kommen bei deinen Kunden vor?

- [ ] Mapping Registry aufbauen (Flywheel starten) <!-- id: sh-0402 -->
  Jede bestätigte FieldMap speichern: (source_schema, target_schema) → Mapping + Rationale + Edge Cases. Failure Taxonomy: UoM-Mismatch, fehlende Stammdaten, Status-Konflikte, Idempotency-Violations.

- [ ] AI-Agent-Pipeline für Standard-Integrationen bauen <!-- id: sh-0403 -->
  Pipeline: Requirement Intake → System Knowledge → Mapper Agent (Retrieval + Confidence) → Codegen → Test Agent → PR Agent. Claude Agent SDK oder LangGraph als Framework. Review-Gates: MappingSpec Approval, Tests Green, Security Check.

- [ ] Pricing-Modell verfeinern <!-- id: sh-0404 -->
  Basierend auf echten Daten: Was ist der Effective Hourly Rate? Wie viel schneller wirst du durch Flywheel? Value-based Pricing statt Stunden.

- [ ] Entscheidung: Nur eigene Firma oder auch andere Warehouse-Anbieter? <!-- id: sh-0405 -->
  Wenn Tooling generisch genug wird: andere Warehouse-Firmen haben das gleiche Problem. Prismatic-Modell: "Embedded Integration" für Automationsanbieter.

## Ongoing

- [ ] Weekly Review: Was ist diese Woche passiert? Nächster Schritt? <!-- id: sh-0501 -->

- [ ] Monthly: Revenue, Kosten, Zeitaufwand, Effective Hourly Rate <!-- id: sh-0502 -->

