# Deep Research Prompt 2 — Technical Feasibility: AI-Automated Integrations

Kopiere diesen Prompt in eine zweite Deep Research Session (parallel zur ersten).

---

## Der Prompt

```
Ich bin ein Software Engineer und will einen AI-gestützten Integrations-Service für Warehouse-/Logistik-Kunden aufbauen. Mein Ziel: Kunden haben ein bestehendes System (SAP, Excel-Prozesse, Nischen-ERP, WMS) und ein neues automatisiertes Lagersystem. Ich will die Brücke dazwischen möglichst automatisiert bauen — mit AI-Agenten die den Großteil der Arbeit machen.

Mein Tech-Stack: Python, FastAPI, PostgreSQL. Ich nutze AI Coding Agents (Claude Code, Cursor) und kann komplexe Agent-Workflows bauen.

## Was ich brauche

Erstelle einen technischen Deep Dive mit folgenden Abschnitten:

### 1. Anatomy of a Warehouse Integration
- Was sind die 10 häufigsten Integrationsszenarien zwischen einem WMS/Lagersystem und externen Systemen?
- Für jedes Szenario: Welche Daten fließen? In welche Richtung? Welche Protokolle/Formate (REST API, SOAP, EDI, CSV, SAP RFC/BAPI, OData)?
- Welche Szenarien sind einfach (Stunden), mittel (Tage), komplex (Wochen)?
- Wo scheitern Integrationen typischerweise? (Datenqualität, fehlende Doku, Edge Cases)

### 2. SAP Integration — Deep Dive
- Wie verbindet man sich programmatisch mit SAP? (RFC, BAPI, IDoc, OData, SAP Integration Suite)
- Welche Open-Source-Tools/Libraries gibt es? (PyRFC, SAP Cloud SDK, etc.)
- Was kostet SAP-Zugang für einen externen Integrator? Brauche ich Lizenzen?
- Häufigste SAP-Module die bei Warehouse-Kunden relevant sind (MM, WM, EWM, SD)
- Realistische Einschätzung: Kann ein AI-Agent SAP-Integrationen teilautomatisiert bauen?

### 3. AI-Powered Data Mapping & Transformation
- State of the Art: Wie gut können LLMs/AI-Agents Daten-Mappings automatisch erkennen?
- Konkrete Tools & Papers: Schema Matching, Ontology Alignment, Auto-ETL
- Beispiel-Workflow: Kunde gibt mir eine Excel-Datei und eine API-Spezifikation → AI mapped die Felder → generiert den Transformationscode → ich reviewe
- Welche Teile funktionieren heute zuverlässig, welche brauchen noch Human-in-the-Loop?
- Open Source Projekte die relevant sind (z.B. Airbyte, Meltano, Singer, dbt, LangChain für structured data)

### 4. iPaaS & Integration Platforms — Build vs. Buy
- Vergleich der relevanten Plattformen: Make.com, n8n, Workato, Tray.io, Prismatic, Merge.dev
- Für jedes Tool: Pricing, Stärken, Schwächen, Warehouse/ERP-Support
- Kann ich eine dieser Plattformen als Basis nutzen und AI-Automatisierung draufsetzen?
- Oder ist es besser, ein eigenes leichtgewichtiges Framework in Python zu bauen?
- Hybrid-Ansatz: Wo lohnt sich eine Plattform, wo Custom Code?

### 5. Agent-Architektur für Integrations-Projekte
- Wie designt man einen AI-Agent-Workflow der:
  1. Kundenanforderungen (natürliche Sprache, Excel-Beispiele) als Input nimmt
  2. Die bestehende API/Datenstruktur des Lagersystems kennt
  3. Automatisch ein Mapping vorschlägt
  4. Integrationscode generiert (Python/FastAPI)
  5. Tests generiert und ausführt
  6. Mir einen Review-Ready Pull Request liefert
- Welche Agent-Frameworks eignen sich? (Claude Agent SDK, LangGraph, CrewAI, AutoGen)
- Wie halte ich den Human-in-the-Loop effizient? (nur Review-Gates, kein Micro-Management)
- Wie manage ich Secrets, Credentials und Kundendaten sicher?

### 6. Proof of Concept: Template-Architektur
- Skizziere eine konkrete Architektur für einen "Integration Accelerator":
  - Input: Kunden-Datenformat (Excel, CSV, API-Spec) + Ziel-API-Spec des Lagersystems
  - Processing: AI-Agent analysiert, mapped, generiert Code
  - Output: Deploybare FastAPI-Microservice als Bridge
  - Monitoring: Logging, Error-Handling, Retry-Logic
- Was wäre ein realistischer MVP den ich in 2 Wochen (= 2 Arbeitstage) bauen könnte?
- Welche Integrationstypen sollte der MVP zuerst unterstützen?

### 7. Competitive Moat durch Technik
- Wie baue ich technischen Vorsprung auf, den andere nicht leicht kopieren können?
- Ist es das Tooling? Die Templates? Das Domain-Wissen im Agent? Die Daten aus vergangenen Integrationen?
- Wie nutze ich jede abgeschlossene Integration um die nächste schneller zu machen? (Flywheel-Effekt)

## Format
- Technisch konkret mit Code-Beispielen wo sinnvoll
- Konkrete Tool-Namen, Libraries, GitHub-Repos, Pricing
- Realistische Einschätzungen — kein AI-Hype, sondern was HEUTE funktioniert
- Für jeden Abschnitt: "Bottom Line" mit einer klaren Empfehlung
```

---

## Ergebnis

Speichere das Ergebnis als `data/shared/side_hustle_tech_research.md`.
