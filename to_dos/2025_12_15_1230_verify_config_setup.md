Verify environment configuration and API key loading.
verify_config_setup
Current State: Completed

Summary
State: Completed
Focus: Integration

Log Book
2025-12-15 12:30: Initial task creation. User requested tests to verify the configuration setup (API keys, .env).
2025-12-15 12:40: Created `test/config_test.dart` using `dotenv.testLoad` to simulate environment variables.
2025-12-15 12:45: Ran tests, confirming that `Config` class correctly reads from dotenv and handles missing keys.
