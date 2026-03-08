# Strategic Plan: Codebase Simplification & Testing Efficiency

> **CROSS-AGENT COMMUNICATION MANDATE:** This document is the primary source of truth for this simplification effort. Every relevant file modified, information discovered, and learning gained MUST be documented here immediately. This ensures that any human or AI agent can resume work with full context. DO NOT delete any information or steps from this plan.

## 1. Understanding the Goal
The objective is to reduce the architectural complexity of the Assisted Intelligence application. By eliminating redundant patterns, decoupling UI from business logic, and centralizing data access, we aim to create a codebase that is easier to reason about, faster to test, and more resilient to regressions during long-term development.

## 2. Investigation & Analysis
- **Map Data Access Patterns:** `DataService` currently uses triple-nested loops for almost all updates.
- **Audit UI Monolith:** `app.dart` contains filtering, sorting, and metadata calculation logic.
- **Review Provider Dependencies:** `SelectionProvider` and `DataProvider` interaction is tightly coupled.
- **Identify Test Bottlenecks:** Logging overhead and complex UI interactions in widget tests.

### Key Files:
- `app/lib/services/data_service.dart` (Target for Phase 1)
- `app/lib/app.dart` (Target for Phase 2 & 4)
- `app/lib/providers/selection_provider.dart` (Target for Phase 3)
- `app/lib/models/models.dart` (Target for Phase 2)

## 3. Proposed Strategic Approach

### Phase 1: Data Layer Optimization (Unified Lookup)
- **Objective:** Eliminate redundant nested loops in `DataService`.
- **Status:** [DONE]
- **Action:** Implement `_findItemPath(String id)` to return indices and parent references.
- **Refactor:** Updated `updateTitle`, `updateNotes`, `setItemStatus`, `setAiStatus`, `addLocalImagePath` to use the unified lookup.

### Phase 2: Domain Logic Extraction
- **Objective:** Move pure logic out of UI and Services into models/extensions.
- **Status:** [DONE]
- **Action:** Move `_extractTags` and `_cycleAiStatus` to model extensions.
- **Action:** Extract Goal progress calculation logic.
- **Learning:** `GoalMetadata` was duplicated in `editable_item_widget.dart` and `models.dart`. Unified them into `models.dart` to fix type mismatch.

### Phase 3: Scoped Filtered Providers
- **Objective:** Decouple filtering/sorting from the UI layer.
- **Status:** [IN PROGRESS]
- **Action:** Create `filteredTasksProvider(projectId)` and similar.

### Phase 4: UI Componentization
- **Objective:** Break down the `app.dart` monolith.
- **Status:** [TODO]
- **Action:** Extract column builders into independent widgets.

## 4. Verification Strategy
- **Unit Test the Lookup:** Verify `_findItemPath` resolves all levels correctly.
- **Regression Testing:** Run `./verify_all.sh` after each phase.
- **Logic Validation:** Ensure tags and status cycling behave identically via unit tests.

## 5. Progress & Learnings
- **2026-03-06:** Plan initiated. Starting Phase 1 refactor of `DataService`.
- **2026-03-06:** Phase 1 DONE. `DataService` refactored with `_findItemPath`. Redundant loops eliminated. Regression tests passed (17s).
- **2026-03-06:** Phase 2 DONE. Logic for tags, AI status next, and goal metadata extracted to `models.dart` extensions. UI cleaned. Type conflict in `GoalMetadata` resolved. Regression tests passed (16s).
