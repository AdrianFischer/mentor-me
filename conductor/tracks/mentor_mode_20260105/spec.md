# Track Spec: Build Core Mentor Mode Infrastructure

## Overview
This track focuses on establishing the foundational infrastructure for "Mentor Mode." The goal is to create a specialized chat interface that is context-aware, meaning it "owns" and understands the user's career status, goals, and daily challenges.

## Objectives
- Implement a persistent data model for Mentor conversations.
- Create a user interface for the Mentor chat area that follows the multi-column design.
- Link chat conversations to specific project/task entries.
- Integrate the "Mentor Personality" (Analytical, Objective, Direct) into the prompt engineering.

## Requirements
- Use Isar for local persistence of chat messages and user context.
- Implement Riverpod providers for managing chat state and Mentor interaction.
- Ensure the UI adheres to the minimalist aesthetic and progressive disclosure principles.
- Support deep-linking from chat messages back to task entries.

## Technical Considerations
- **Data Model:** `MentorMessage` and `UserContext` Isar collections.
- **AI Integration:** Use `firebase_ai` to communicate with Gemini.
- **Context Ownership:** Each project or top-level task can have an associated `MentorThread`.
