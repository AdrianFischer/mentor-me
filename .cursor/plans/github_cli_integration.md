# Strategic Plan: GitHub CLI Integration for Agent

This plan document is a communication tool across multiple different agents. Therefore, every relevant file, every relevant information, and every learning MUST be documented in this file. A human or an AI agent has to know EXACTLY the state of this plan at all times. This single file MUST give all context relevant to continue the work.

## 1. Understanding the Goal
The objective is to empower the agent with the ability to interact directly with GitHub. Specifically, the agent needs to be able to fetch branches, read comments, and inspect Cloud Runs (via GitHub Actions/deployments) directly from GitHub. This will likely involve giving the agent access to the `gh` (GitHub CLI) tool or a dedicated GitHub API integration.

## 2. Investigation & Analysis
### Current State
- The agent currently uses an MCP server (`app/bin/mcp_bridge.dart` / `app/lib/ai_tools/`) to interact with local app data.
- The agent has a Node.js-based "Brain" (`agent/agent.js`) that manages tool execution, routing local tools (routines) and remote tools (MCP).
- There is currently no direct GitHub integration documented in the available tools.

### Key Questions to Answer
1.  **Tooling Approach:** Should we use the `gh` CLI directly via `exec` in Node.js, create a new Dart-based MCP tool, or use the official GitHub REST/GraphQL API via a Node.js library (like `octokit`)?
    - *Hypothesis:* Using the `gh` CLI is often the fastest way to get human-readable output for branches and PRs, but `octokit` is more robust for programmatic use. Given the prompt specifically mentions "github cli", we should explore wrapping `gh` CLI commands first.
2.  **Authentication:** How will the agent authenticate with GitHub? It needs a `GH_TOKEN` or needs to run in an environment where `gh auth status` is already valid.
3.  **Scope of Tools:** What specific commands do we need?
    - Fetch branches (`gh repo view` or `gh pr list` / `gh branch list`?)
    - Fetch comments (`gh pr view <number> --comments`)
    - Fetch Cloud Runs (`gh run list` / `gh run view`)

### Investigation Steps Taken
- Searched codebase for existing `github` or `gh` references.
- Reviewed `agent/agent.js` to understand how local tools are currently registered (via `routinesManager.getTools()`).
- Reviewed `app/lib/ai_tools/` to understand how Dart-based tools are registered.

## 3. Proposed Strategic Approach

We will build the integration into the Node.js agent (`agent/`) rather than the Dart MCP server, as interacting with external APIs/CLIs is better suited for the Node.js environment where we can easily spawn child processes or use native libraries.

### Phase 1: Authentication and Environment Setup (✅ DONE)
- **Objective:** Ensure the agent has the necessary credentials to use the `gh` CLI.
- **Actions:**
  - Add `GH_TOKEN` to `agent/.env`.
  - Update `agent/config.js` to validate the presence of this token.
  - Create a utility function in the agent (e.g., `agent/github.js`) that verifies `gh auth status` on startup.

### Phase 2: Building the Tool Wrappers (Node.js) (✅ DONE)
- **Objective:** Create specific, narrowly scoped tools that the LLM can use.
- **Actions:**
  - Create a new module: `agent/github_tools.js`.
  - Implement wrapper functions using Node's `child_process.execSync` or `exec` to call the `gh` CLI.
    - `get_github_branches`: Executes `gh pr list` or `gh branch`.
    - `get_github_pr_comments`: Executes `gh pr view <number> --comments --json comments`.
    - `get_github_runs`: Executes `gh run list --limit 10`.
  - Ensure all wrappers return clean, parsed JSON or strictly formatted text to minimize token usage.

### Phase 3: Registering Tools with the Agent (✅ DONE)
- **Objective:** Expose the new tools to the Gemini model.
- **Actions:**
  - Define the JSON schemas for these new tools.
  - Update `agent/agent.js` (specifically the `_gatherTools` and `_executeTool` methods) to include these new GitHub tools alongside the existing `mcpTools` and `localTools`.

### Phase 4: Error Handling and Prompt Updates (✅ DONE)
- **Objective:** Ensure the agent knows when and how to use these tools safely.
- **Actions:**
  - Handle common `gh` errors (e.g., repository not found, not a git repository, rate limits).
  - Update the agent's system prompt (in `agent/gemini.js`) to explain that it has access to GitHub and should use these tools when asked about PRs, branches, or CI/CD runs.

## 4. Verification Strategy
- **Unit Testing:** Write tests in `agent/test/` to mock the `child_process.exec` calls and verify the tool schemas and parsing logic.
- **Integration Testing:**
  - Run the agent locally.
  - Ask: "What are the latest branches on this repository?" -> Verify it calls `get_github_branches`.
  - Ask: "Show me the comments on PR #1" -> Verify it calls `get_github_pr_comments`.
  - Ask: "Did the latest cloud run succeed?" -> Verify it calls `get_github_runs`.
- **Security Check:** Ensure no secrets are leaked in the console output or returned to the user unnecessarily.

## 5. Anticipated Challenges & Considerations
- **Dependency:** This approach strictly requires the `gh` CLI to be installed on the host machine running the agent.
- **Context Size:** `gh pr view` or `gh run view` can return massive amounts of text (especially logs). We must enforce limits (e.g., `--limit 5`, or truncating long logs) to avoid blowing up the LLM context window.
- **Repository Context:** The `gh` CLI usually relies on the current working directory being a git repository. The agent needs to either run from the root of the target repository or pass the `-R <owner>/<repo>` flag explicitly to all commands. We should probably design the tools to require the repository name as an argument to make it flexible.

## Updates & Learnings
- [2026-03-09] Initial plan created. Decided to focus on Node.js integration wrapping the `gh` CLI rather than Dart MCP, as it allows faster iteration and leverages existing CLI capabilities.

- [2026-03-09] Implemented GithubTools module wrapping gh CLI. Tools successfully registered in agent.js and system prompt updated. Tests passed. Ready for review.
