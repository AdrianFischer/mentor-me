# Improve Autonomous Pipeline Robustness
improve_pipeline_robustness
Enhancing the Flutter autonomous pipeline based on initial testing feedback (race conditions, noise, verification).

Summary
State: Completed
Focus: Maintenance

Log Book
- 2025-12-15: Implemented robustness features.
    - **Smart Debounce**: Added 2-second debounce timer to batch file changes.
    - **Selective Execution**: Differentiated between `lib/` changes (Hot Reload + Test) and `test/` changes (Test Only).
    - **Self-Healing**: Implemented automatic process restart loop in `autonomous_flutter.dart` to recover if `flutter run` crashes.
    - **Status Indicator**: Verified JSON status output.
- 2025-12-14: Created based on "Phase 3" testing learnings.
- Issues Identified:
    1.  **Race Condition**: Modifying `main.dart` triggers a test run immediately. If `widget_test.dart` is updated 1 second later to match the new UI, the first test run fails (False Negative).
    2.  **Noise**: Every save triggers a reload/test cycle, creating log noise.
    3.  **Process State**: Occasional need to kill/restart `flutter run` if it gets out of sync.

## Planned Improvements
1.  **Smart Debounce**:
    - Increase debounce time (e.g., to 2 seconds) to allow for multiple file saves (Logic + Test) to complete before triggering.
    - Or, detecting if multiple files are changing.
2.  **Selective Execution**:
    - If only `test/` files change -> Run Tests (No Reload).
    - If `lib/` files change -> Reload + Run Tests.
3.  **Status Indicator**:
    - Create a small `status.json` or `status.txt` (e.g., "PASS" / "FAIL") for easier machine reading than parsing the full markdown report.
4.  **Self-Healing**:
    - Script could detect if `flutter run` has died and restart it automatically.
