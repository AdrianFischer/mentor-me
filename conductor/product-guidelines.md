# Product Guidelines: Assisted Intelligence

## Communication Tone
- **Default:** Professional, concise, and highly technical. Focus on clarity and precise industry terminology to respect the user's expertise.
- **Narrative Shift:** When the user requests an explanation ("Explain..."), deep discussion ("Let's discuss..."), or similar, the Mentor should switch to an **Inspiring & Narrative** style, using storytelling and visionary language to provide broader context and motivation.

## Keyboard Interaction Design
- **Single-Key Core Actions:**
    - `Space`: Toggle task/project completion status.
    - `Enter`: Open details/notes/editor for the selected item.
    - `Tab`: Indent an item or move it into a subtask hierarchy.
- **Lightning-Fast Experience:** Every core action must be accessible with minimal keystrokes. Shortcuts should be intuitive and require no complex modifiers for primary workflows.

## AI Mentor Integration & UI
- **Context-Aware Chat:** The Mentor resides in a dedicated message area.
- **Entry Ownership:** Conversations are "owned" by specific entries (projects, tasks, or subtasks).
- **Deep Linking:** Mentor messages should contain clear, actionable links to the relevant entries. Clicking or activating these links must navigate the user directly to the focused entry and open its details.

## Visual & Structural Design
- **Multi-Column Hierarchy:** Navigation follows a left-to-right flow.
    - **Left Column:** High-level overview (e.g., Projects).
    - **Middle Column:** Mid-level focus (e.g., Tasks).
    - **Right Column:** Low-level detail (e.g., Subtasks or focused entry details).
- **Progressive Disclosure:** Details, notes, and extended data are hidden by default to maintain a minimalist aesthetic. They are only revealed upon explicit selection (e.g., pressing `Enter` on an entry).
- **Minimalist Aesthetic:** Maintain high contrast and clean typography. Avoid visual clutter by hiding secondary information until it is contextually relevant.

## Core Engineering Principle
- **Absolute Simplicity:** Simplicity is the paramount rule for both App Design and Code Implementation.
    - **No Over-Engineering:** Avoid complex patterns, unnecessary abstractions, or "clever" code unless absolutely required by a specific constraint.
    - **Minimalist Solutions:** Always choose the simplest, most direct path to a working feature. Complex UI elements or intricate architectural layers are explicitly discouraged unless they significantly simplify the user experience.
