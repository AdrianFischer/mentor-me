# Topic: AssistedIntelligence App Design Specifications

**Date**: 2025-12-13
**Context**: Initial design briefing for the Flutter desktop application provided by the user.

## Project Context
- **Goal**: specific Flutter desktop app to manage the "AssistedIntelligence" personal project.
- **Data Source**: Local Markdown files.
    - `overview.md`: Summary table of all tasks (List View source).
    - `to_dos/*.md`: Detailed task files (Detail View source).
- **File Structure**:
    - **Header**: Description, Identifier.
    - **Summary**: State (e.g., Preparing), Focus (e.g., Podcast Rehearsal).
    - **Log Book**: Chronological updates.

## Design Constraints
- **Platform**: Flutter Desktop.
- **Input**: 100% Keyboard-driven. NO MOUSE interaction.
- **Style**: High-efficiency, keyboard-centric (Vim/Raycast/Superhuman inspired).

## Navigation Model
- **Layout**: Split View (Left: Task List, Right: Task Details).
- **Key Bindings**:
    - `Arrow Up/Down`: Traverse Left Pane list. Instant preview in Right Pane.
    - `Arrow Right`: Shift focus to Right Pane (Dive in).
    - `Arrow Left`: Return focus to Left Pane (Pop out).
    - `Enter`: Edit selected element (Inline editing).
    - `Space`: Summon "AI Agent" overlay (Conversational interface).
    - `Esc`: Cancel/Exit edit mode.

## Selected Top 3 Designs (Refined)

### 1. The Neuro-Link (Refined)
**Score: 10/10**
*   **Visual Metaphor**: **Bi-Directional Command Line**. A modernized terminal that predicts intent. Dark mode, monospaced fonts, but with fluid, organic transitions.
*   **The Innovation**: **"Fluid State Transitions"**.
    The boundary between "Navigation" and "Action" is blurred. As you type, the interface morphs. If you are navigating the list and start typing, the Left Pane fades slightly, and your keystrokes instantly filter the list *or* begin a command for the active item.
*   **Refinement - "Contextual Action Hints"**:
    When typing or hovering, the UI displays ghost-text suggestions for available keyboard commands based on the exact context (e.g., if on a "Waiting" task, typing `c` might suggest `complete` or `check-in`). The Split View is now dynamic; the active pane expands to 70% width, while the inactive one shrinks to 30%, but this ratio is user-configurable or auto-adjusts based on content density (e.g., reading a long Log Book expands the right pane further).

### 2. The Glass Cockpit (Refined)
**Score: 9.8/10**
*   **Visual Metaphor**: **Fighter Jet HUD**. High-contrast green/amber text on semi-transparent dark layers.
*   **The Innovation**: **"Heads-Up Overlays"**.
    Instead of a hard split view, the Details Pane is a glass layer that slides in *over* the list when you press `Arrow Right`. You can still see the faint outline of your list context behind it.
*   **Refinement - "Critical Path Highlighting"**:
    When the overlay is active, critical information (like Next Actions or Deadlines) glows with slightly higher intensity, guiding the eye. The `Space` bar now acts as a "Quick Toggle" to summon/dismiss the overlay instantly without shifting hand position, allowing for rapid-fire "peek and dismiss" workflows. `Esc` still dissolves the layer.

### 3. The Tiling Master (Refined)
**Score: 9.5/10**
*   **Visual Metaphor**: **Tiling Window Manager (i3 / Sway)**. Sharp borders, absolute maximizing of screen real estate.
*   **The Innovation**: **"Infinite Context Stack"**.
    If a task has sub-tasks or linked notes, `Arrow Right` opens a *third* column, pushing the parent list to the left. You can drill down infinitely (List -> Task -> Linked Note -> Reference).
*   **Refinement - "Minimap Navigation"**:
    To prevent getting lost in deep stacks, a small "Minimap" or breadcrumb bar in the top-right corner visualizes the entire column depth, highlighting your current active column. Additionally, "Collapsed States" are introduced: when a 3rd or 4th column opens, the leftmost columns (like the main list) automatically collapse to icon-only strips to preserve screen real estate for the active context.
