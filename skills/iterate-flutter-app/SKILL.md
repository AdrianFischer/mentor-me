---
name: iterate-flutter-app
description: An iterative workflow for starting the Flutter application, finding errors on your own, reporting them, and autonomously fixing them. Use this skill when you need to continuously iterate on the Assisted Intelligence Flutter app and discover bugs without human intervention.
---

# Iterate Flutter App

This skill provides a structured workflow to run the Assisted Intelligence Flutter app autonomously, observe its state via logs and screenshots, report errors, and apply fixes.

## Workflow Execution

Follow these steps to iterate on the application:

1. **Environment Preparation**: Ensure `.env` is configured correctly with `SCREENSHOT_DIR` pointing to a local directory (e.g., `app/test_artifacts/`). Check that an `error_reports.md` ledger exists for the session.
2. **Headless Start**: Launch the Flutter app using `flutter run -d macos -t lib/main_dev.dart` as a background process, piping stdout and stderr to a log file (e.g., `app/test_artifacts/app.log`). Note its process ID.
3. **State Manipulation**: Use the built-in MCP server (`http://localhost:8081/mcp`) to inject test data or trigger specific app states.
4. **Observation**: 
   - Write `r` to the Flutter process stdin to trigger a hot reload and save a screenshot (`current_state.png`).
   - Read the latest `app.log` entries for caught exceptions or layout overflows.
   - Use visual and log data to identify logic or UI bugs.
5. **Reporting & Fixing**: Append a structured error report to `error_reports.md`, implement a fix in the codebase, and verify by repeating the observation step.

## Mandatory: Continuous Learning

This workflow is highly experimental. You MUST continuously document every new finding, learning, efficiency improvement, and gotcha inside the shared learnings document.

**See [learnings.md](references/learnings.md) for the current list of accumulated knowledge.**

Whenever you encounter a new failure mode (e.g., Flaky hot reload, MCP connection drop, visual mapping strategy), you MUST immediately append your learning to `references/learnings.md` so future agents can avoid the same mistake.