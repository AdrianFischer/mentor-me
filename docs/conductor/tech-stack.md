# Tech Stack: Assisted Intelligence

## Core Framework
- **Flutter (Dart):** The primary framework for building the cross-platform (macOS, iOS, Web) application.

## State Management
- **Riverpod:** Used for reactive, testable, and robust state management across the application.

## Data Persistence
- **Direct-to-Markdown (File-First):** No database. The application parses Markdown files on startup into an in-memory state (Riverpod) and writes changes directly back to the file system using a write-behind strategy with loop prevention.
- **Firebase:** Utilized for cloud-based features including Authentication, Firestore (sync), Storage, and Cloud Functions.

## AI & Agent Infrastructure
- **Firebase AI (Gemini):** Integrated via the `firebase_ai` package to provide the "Mentor" and autonomous agent capabilities.
- **Model Context Protocol (mcp_dart):** Used to facilitate standardized communication between the AI agents and the Flutter application.

## Communication & Utilities
- **shelf/shelf_router:** For embedding a local HTTP server within the app to support MCP endpoints.
- **flutter_dotenv:** For secure management of environment variables and API keys.
