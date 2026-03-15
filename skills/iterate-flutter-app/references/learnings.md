# Learnings: Iterative Flutter App Workflow

This file tracks continuous learnings, new findings, and efficiency improvements discovered while running the `iterate-flutter-app` workflow.

## Known Challenges & Solutions

*   **Hot Reload Triggering**: `run_shell_command` with `is_background: true` isolates stdin. To send `r` (hot reload), you MUST start the app inside a `screen` session: 
    `screen -L -d -m -S flutter_app bash -c "cd app && flutter run -d macos -t lib/main_dev.dart --dart-define=SCREENSHOT_DIR=...`
    Then trigger hot reload with: `screen -S flutter_app -p 0 -X stuff "r"`
*   **Environment Setup**: `.env` variables loaded via `flutter_dotenv` require `.env` to be declared in `pubspec.yaml` `assets`. However, early app lifecycle scripts (like `Config.screenshotDir`) often use `String.fromEnvironment`, which requires passing `--dart-define=SCREENSHOT_DIR=...` to the `flutter run` command directly.
*   **Visual Mapping**: If a UI exception occurs, the screenshot (`current_state.png`) will display the classic red "Flutter Error" screen. This visually confirms a critical rendering failure.
*   **Log Mapping**: Using `grep_search` on `screenlog.0` for terms like `EXCEPTION CAUGHT BY WIDGETS LIBRARY` reliably surfaces stack traces with exact file paths and line numbers (e.g., `package:flutter_app/app.dart:150:5`). We can parse these to locate the exact failing widget.
*   **Reporting Format**: A Markdown ledger entry with `[Date] - [Error Type]`, `Hypothesized Cause`, a `Log Excerpt` block containing the stack trace, and `Visual Context` is highly effective for agents.

*(When iterating on the flutter app, append new discoveries here.)*