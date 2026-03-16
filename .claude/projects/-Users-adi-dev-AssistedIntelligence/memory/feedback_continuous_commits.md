---
name: Kontinuierlich committen
description: User will, dass nach jeder produktiven Änderung sofort ein Git-Commit gemacht wird
type: feedback
---

Nach jeder produktiven Änderung (Code, Config, Daten) sofort einen Git-Commit erstellen – nicht erst am Ende einer Session oder auf Nachfrage.

**Why:** Der User möchte einen sauberen, granularen Git-Verlauf und will nicht explizit nach jedem Schritt um einen Commit bitten müssen.

**How to apply:** Sobald eine funktionale Änderung abgeschlossen ist (z.B. neues Feature eingebaut, Bug gefixt, Refactoring fertig), direkt committen. Gilt nicht für temporäre/explorative Änderungen die wieder rückgängig gemacht werden.
