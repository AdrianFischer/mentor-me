Ziel:
- Übernehme die neuesten Änderungen aus `CHANGELOG.md` in die kundenorientierte Dokumentation unter `docs/` (MkDocs).
- Aktualisiere die Seite `docs/docs/contents/changelog.md` mit einer neuen, deutschen Release-Notiz (kundenfokussiert).
- Aktualisiere bei Bedarf weitere betroffene Doku-Seiten in `docs/docs/contents/**`.
- Ignoriere rein technische/Entwickler-Aspekte (z. B. Chore), wenn sie keinen Nutzer-Impact haben.

Eingaben:
- Entwickler-Changelog: `CHANGELOG.md` (Top‑Abschnitt = neueste Version)
- Doku-Wurzel: `docs/`
- Doku-Changelog-Seite: `docs/docs/contents/changelog.md`
- Referenzstil (Ton/Struktur): `docs/docs/contents/operation/sku-management.md`, `docs/docs/contents/operation/auth.md`

Sprach- und Stilvorgaben (kundenorientiert):
- Sprache: Deutsch (formell, präzise, technisch korrekt)
- Fokus auf Nutzen und Auswirkungen für Anwender (nicht auf Implementierungsdetails)
- Konsistente Struktur: kurze Einleitung, Funktionen/Änderungen mit Überschriften, ggf. Warnhinweise/Hinweise
- Verwende Warnstufen: Gefahr, Warnung, Vorsicht, Info – nur wenn relevant
- Keine Vermutungen/Halluzinationen: Unklare Punkte als „Info“-Hinweis markieren oder Rückfrage stellen

Aufgaben:
1) Version ermitteln
   - Lese die oberste Version in `CHANGELOG.md` (z. B. „vX.Y.Z (commit)“).
   - Ermittele das Release-Datum (falls unbekannt: mit Platzhalter „ab TT.MM.JJJJ“ belassen oder Rückfrage).

2) Inhalte kuratieren (Mapping Entwickler → Kunde)
   - Kategorien: „Added/Changed/Fixed“ in kundengerechte Nutzenaussagen übersetzen.
   - „Chore“, interne Refactors, Test-/CI-/Build-Themen weglassen, es sei denn sie haben sichtbare Auswirkung.
   - Beispiele:
     - DEV: „Added 'updated_at' column in inventory table“
       DOC: „Neue Spalte 'Aktualisiert am' in der Inventarseite – bessere Nachvollziehbarkeit von Änderungen.“
     - DEV: „Fix API iLike filters…“
       DOC: „Verbesserte Suche: Exakte Treffer erscheinen zuerst, stabilere Filterergebnisse.“

3) Doku-Changelog aktualisieren
   - In `docs/docs/contents/changelog.md` einen neuen, obersten Abschnitt einfügen:
     - Überschrift: „## v{VERSION} ({SHORT_HASH}) ab {DD.MM.YYYY}“
     - Kurze Einleitung (1–2 Sätze zum Mehrwert des Releases).
     - Danach thematisch gruppierte Unterpunkte:
       - Neue Funktionen/Verbesserungen (mit fett formatierten Schlagzeilen + 1–3 Sätzen Nutzenbeschreibung)
       - Relevante Fehlerbehebungen (nur mit Nutzerwirkung)
     - Verweise auf UI-Bereiche exakt benennen (z. B. Tabellen/Spalten/Ansichten).
     - Bilder/Videos nur referenzieren, wenn vorhanden. Pfade: `docs/docs/assets/images/changelog/`.
       - Keine Platzhalter-Bildnamen erfinden. Falls Asset fehlt: Hinweis „Info: Screenshot kann nachgereicht werden.“

4) Betroffene Fachseiten prüfen/aktualisieren
   - Wenn Änderungen die Bedienung beeinflussen (z. B. neue Spalte, neue Filter, neue Workflow-Schritte), aktualisiere die relevanten Seiten unter `docs/docs/contents/**`.
   - Struktur: Schritt-für-Schritt, UI-Elemente exakt benennen, Screenshots nur wenn vorhanden.
   - Keine Navigation ändern; `mkdocs.yml` nur anfassen, wenn wirklich neue Seiten hinzukommen.

5) Konsistenz/Qualitätssicherung
   - Terminologie konsistent (SKU, Request, Job, Inventar, etc.).
   - Deutsche Typografie/Zeichensetzung (z. B. Gedankenstrich, Anführungen).
   - Relative, funktionierende Links; vorhandene Bilder.
   - Keine inhaltlichen Widersprüche zu `CHANGELOG.md`.

Ausgaben (am Ende liefern):
- Kurze Liste der vorgenommenen Edits mit Pfaden (z. B. „Aktualisiert: `docs/docs/contents/changelog.md` – Abschnitt v{VERSION} hinzugefügt“).
- Den vollständigen neuen v{VERSION}-Abschnitt als Markdown (so wie er in `docs/docs/contents/changelog.md` eingefügt wurde).
- Falls weitere Seiten geändert wurden: jeweils 1–2 Stichpunkte, welche Nutzerinformation ergänzt/geändert wurde.
- Vorschlag für Commit-Message:
  - „docs: v{VERSION} Release-Notes (kundenorientiert) + betroffene Seiten aktualisiert“

Abbruch-/Rückfragekriterien:
- Wenn Release-Datum oder UI-Details unklar sind, nicht raten. Rückfrage stellen mit konkreter Liste offener Punkte.
- Keine Platzhalter-Bilder erzeugen. Stattdessen um Asset anfragen.

Definition of Done:
- `docs/docs/contents/changelog.md` enthält die neue Version ganz oben, in sauberem, kundenzentriertem Deutsch.
- Nur signifikante, nutzerrelevante Änderungen sind enthalten; technische Chores entfallen.
- Betroffene Fachseiten sind konsistent angepasst oder es ist klar begründet, warum keine Anpassung nötig war.