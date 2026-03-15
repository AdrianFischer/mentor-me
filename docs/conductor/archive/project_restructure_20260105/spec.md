# Track Spec: Project Restructuring and Markdown-First Data Sync

## Overview
This track involves a comprehensive reorganization of the project structure to eliminate "messiness," clarify project boundaries, and implement a "Markdown-First" data synchronization strategy. The goal is to make the codebase more maintainable and to allow Gemini to interact with project data directly via local text files.

## Functional Requirements
- **Top-Level Reorganization:** Implement a clean, standardized directory structure:
    - `app/`: Contains the Flutter application (moved from `src/flutter_app`).
    - `backend/`: Contains Firebase Functions (extracted from the Flutter source tree).
    - `data/`: The central hub for all syncable Markdown data (Projects, Tasks, Knowledge).
    - `conductor/`: Existing management directory for tracks and specs.
    - `scripts/`: Consolidated location for all utility and maintenance scripts.
- **Markdown-First Architecture (Local Only):**
    - Define a strict Markdown format for data: `#` for Projects, `-` for Tasks, `Tab + -` for Subtasks.
    - Implement a bidirectional synchronization mechanism between the `data/` Markdown files and the application's *local* Isar database.
- **Cleanup & Consolidation:**
    - Identify and consolidate redundant scripts currently scattered across `scripts/`, `src/scripts/`, etc.
    - Move all knowledge base entries and to-dos into the new `data/` structure.
    - Archive or delete legacy files in `.cursor/plans`, `knowledge_base/`, and `to_dos/` that are now obsolete.

## Non-Functional Requirements
- **Simplicity:** The restructuring and sync logic must remain as simple as possible, avoiding over-engineering.
- **Performance:** Synchronization between text files and the database should be near-instantaneous.

## Acceptance Criteria
- The root directory contains only the defined `app/`, `backend/`, `data/`, `conductor/`, and `scripts/` folders plus essential config files.
- All functional code for the app and backend is correctly separated and buildable in their new locations.
- Any change made to a Markdown file in `data/` is automatically reflected in the application's local database (Isar) and vice-versa.
- There are no duplicate or redundant files for scripts, knowledge, or task tracking.

## Out of Scope
- Major feature additions to the Flutter app itself.
- Online/Cloud synchronization of the database or files (local sync only).
