---

id: 42806dac-5c75-4959-a01d-6570bdc7a5b8

version: 1

---


# Inbox


- [x] Fix MCP not connecting <!-- id: 3c74339c-c17b-43bb-af6a-605d7b54cb17 -->

- [x] Implement AI Tool for CI Test Log Analysis <!-- id: 12bf2282-ad6a-4d65-8035-1a1bf65d609b -->
  **Objective:** Provide the AI Agent with the ability to read GitHub Actions run logs, extract failing tests, and compare them against the latest `develop` run to determine if a PR introduced a bug or if the tests are already broken/flaky on `develop`.
  **Required Capabilities (Tools/Endpoints):**
  1. **`get_github_run_logs(run_id, repo)`**
  - The AI currently only sees metadata. We need a tool that downloads and parses the actual logs (or test result artifacts like JUnit XML) for a specific `run_id`.
  - *Alternative/Better:* A specific `get_github_failed_tests` endpoint that parses the logs/annotations server-side and just returns an array of failed test names/errors (saves context window).
  2. **`get_latest_branch_run(branch_name, repo)`**
  - We need an easy way to grab the *latest completed* run specifically for the `develop` branch to serve as our baseline for comparison.
  **How the AI will use this:**
  1. Call `get_github_runs` to find the failing PR run.
  2. Call `get_github_run_logs` (or `get_github_failed_tests`) using that run's ID to extract the exact list of failing tests.
  3. Call `get_github_runs` to find the most recent run on the `develop` branch.
  4. Call `get_github_run_logs` for the `develop` run to get its failing tests.
  5. Compare the two lists and output a summary (e.g., "Test A is new to your PR, but Test B is already failing on develop").
  - [x] Create `get_github_run_logs` or `get_failed_tests` API tool for AI Agent <!-- id: 66b46636-43c8-4c26-8e58-670dea7d0020 -->
  - [x] Build capability to find and retrieve latest test runs specifically on the develop branch <!-- id: 681e63bf-33d9-4165-877a-881e960416e1 -->

