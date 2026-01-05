# Assisted Intelligence - GEMINI.md

## Project Overview

**Assisted Intelligence** is a keyboard-driven task management application designed for power users. It differentiates itself through deep AI integration, featuring a "Mentor" mode that provides strategic career guidance and autonomous agents that assist with task breakdown and verification.

The application follows a **local-first** architecture for speed and privacy, utilizing **Isar** for local storage and **Firebase** for optional cloud synchronization and advanced AI features.

## Technical Stack

*   **Frontend:** Flutter (Dart) targeting macOS, iOS, and Web.
*   **Backend:** Firebase Functions (Node.js / TypeScript).
*   **State Management:** Riverpod.
*   **Database:**
    *   **Local:** Isar (NoSQL).
    *   **Cloud:** Cloud Firestore (Sync), Firebase Storage.
*   **AI & Agents:**
    *   **Model:** Google Gemini (via `firebase_ai` and Vertex AI).
    *   **Protocol:** Model Context Protocol (MCP) via `mcp_dart`.
    *   **Integration:** Embedded HTTP server (`shelf`) for Agent-App communication.
*   **Environment:** `flutter_dotenv` for configuration.

## Directory Structure

*   **`app/`**: The main Flutter application source code.
    *   `lib/`: Dart source files.
    *   `test/`: Unit and widget tests.
    *   `bin/`: Entry points for auxiliary scripts or servers (e.g., `mcp_bridge.dart`).
*   **`backend/`**: Firebase Functions implementation.
    *   `src/index.ts`: Main entry point for cloud functions.
*   **`conductor/`**: Product management and architectural documentation.
    *   `product.md`: High-level product goals and feature definitions.
    *   `tech-stack.md`: Detailed technology choices.
    *   `tracks/`: Specific development tracks and plans.
*   **`knowledge_base/`**: Contextual documents, design specs, and research.
*   **`.github/`**: CI/CD workflows and Gemini automation configuration.

## Development & Usage

### Prerequisites
*   Flutter SDK (^3.9.2)
*   Node.js (v20) & npm
*   Firebase CLI

### Setup
1.  **Environment Variables:**
    Create a `.env` file in the `app/` directory (ignored by git):
    ```env
    GEMINI_API_KEY=your_api_key_here
    SCREENSHOT_DIR=/path/to/screenshots
    ```

### Building and Running

**Flutter App:**
```bash
cd app
flutter pub get
flutter run
```
*   To run with fallback configuration if `.env` is missing:
    ```bash
    flutter run --dart-define=GEMINI_API_KEY=your_key
    ```

**Backend (Firebase Functions):**
```bash
cd backend
npm install
npm run build
# To run locally with emulators:
npm run serve
```

**Testing:**
```bash
cd app
flutter test
```

## Key Conventions

*   **State Management:** Use Riverpod for all app state. Avoid `setState` for complex logic.
*   **Data Persistence:** Prefer Isar for local data. Sync to Firestore only when necessary or explicitly triggered.
*   **AI Integration:** AI features should be implemented using the `firebase_ai` package.
*   **MCP:** New tools for the AI agent should be exposed via the embedded MCP server setup in the app.
*   **Design:** Follow a minimalist, high-contrast, distraction-free visual style.
