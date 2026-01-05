Goal:
Create a pull request from the current branch's diff against the develop branch (or another base branch if specified) using the GitHub CLI (`gh`).

Context:
- The user is on a feature branch and wants to create a PR
- Generate an AI-powered PR title and description that follows our team's standards
- Use `gh pr create` to submit the PR
- The default base branch is `develop`, but developers may specify a different base branch

Steps:

1. **Get the current branch name**
   - Run: `git branch --show-current`
   - This will be used as the head branch for the PR

2. **Verify we're not on main/master/develop**
   - If on main, master, or develop branch, abort and tell the user to switch to a feature branch first

3. **Determine the base branch and get the git diff**
   - Default base branch is `develop`
   - If the developer provided a base branch (e.g., in their message or context), use that instead
   - Run: `git fetch origin <BASE_BRANCH>`
   - Run: `git diff origin/<BASE_BRANCH>...HEAD`
   - If the diff is empty, abort and tell the user there are no changes
   - If the diff has more than 1000 changed lines, warn the user but continue

4. **Analyze & Generate PR Content**
   You are an AI assistant responsible for capturing the **proven value** of this change.

   **A. HYPERTHINK: Analyze the "Who" and "Why"**
   Before generating text, analyze the diff to determine the *Beneficiary* and the *Value Proposition*. Do not just look at code; look at the impact on specific teams.
   
   - **Sales & Success**:
     - *Trigger*: Changes to monitoring, assembly/setup flows, documentation, or performance metrics.
     - *Value Examples*: "Improves system throughput/stability," "Reduces assembly time," "Adds sales collateral/assets," "Better visibility for support."
   
   - **Hardware Team**:
     - *Trigger*: Changes to charging logic, bot command interfaces, setup/ack protocols, or RFID writing.
     - *Value Examples*: "Updates charging profile," "Fixes bot command reliability," "Improves RFID write success rate."
   
   - **Customers**:
     - *Trigger*: Visible UI changes, public API updates, bug fixes in core flows.
     - *Value Examples*: "New feature," "Smoother experience," "Fixes critical bug."
   
   - **Developers**:
     - *Trigger*: Refactoring, CI/CD, tests, internal tooling.
     - *Value Examples*: "Reduces technical debt," "Speeds up build time," "Improves test coverage."

   **B. THE UNCERTAINTY CHECK (Dynamic Interaction)**
   If the *Value Add* is not self-evident from the code (e.g., a confusing logic change without comments), **do not guess**. 
   Instead, pause and ask the user to clarify by proposing 2-3 specific, context-aware options based on what you see. Push back if the value add is not described properly.
   
   *Example Interaction:*
   "I see changes to `rfid_writer.cpp`. I'm unsure of the business value. Is this:
    1. Improving write speed for higher throughput? (Sales/KPI Value)
    2. Fixing a specific hardware compatibility issue? (Hardware Team Value)
    3. Adding logging for better debugging? (Success/Monitoring Value)"

   **C. GENERATE THE CONTENT**
   Once the value is clear (either deduced from artifacts or confirmed by user), generate the PR description using the template below.

 **PR TITLE REQUIREMENTS:**
   - Prefix with exactly one category: **Feature:**, **Change:**, **Fix:**, **Chore:**, or **Security:**
     - *Feature*  → New user/customer-facing functionality or capability (something users or customer support would want to know about)
     - *Change*   → Modification to existing user/customer-facing behavior (something users or customer support would want to know about)
     - *Fix*      → Bug fix or correction for user/customer-facing issues (something users or customer support would want to know about)
     - *Chore*    → Maintenance, refactor, build tasks, infrastructure changes, developer experience improvements, deployment updates, test fixes, CI/CD changes, dependency updates, tooling improvements (internal-only changes)
     - *Security* → Security-related improvement or patch
   - Keep it **50-70 characters** total (including prefix)
   - Write in **imperative mood** ("Add", "Update", "Fix")
   - Example → `Feature: Add cursor-based pagination to user API`
   
   **TONE & STYLE:**
   - Friendly yet professional: Imagine explaining over coffee
   - Concise & direct: Spare the fluff, keep the clarity
   - Natural voice: No corporate-robot phrasing; contractions welcome
   - Touch of warmth: A dash of humor is fine—sparingly
 
   **PR DESCRIPTION TEMPLATE:**
   
   ## Summary
   *What changed (1-2 sentences).*
   
   ## Context & Value
   *Why are we doing this? Explicitly state the value add.*
   *Examples:*
   *- "Updates the charging logic to prevent battery degradation."*
   *- "Adds new monitoring metrics to help CS troubleshoot assembly issues."*
   *- "Optimizes the RFID write sequence to increase throughput by 10%."*
   *- "Refactors the auth loop to prevent race conditions."*
   
   ## Key Changes
   - Bullet 1
   - Bullet 2
   - Bullet 3
   
   ## Impact & Risk
   *Breaking changes? Migration steps? Rollback plan? Mention here.*
   
      ## Issue Links & Closing
   *Use one of:*
   - `Resolves #123`
   - `Fixes JIRA-456`
   - `Closes GH-789`
   
   ## Additional Notes
   *Screenshots, API docs links, follow-up work, kudos, etc.*
   
   ---
   
   **EXAMPLE OUTPUT:**
   
   TITLE: Feature: Add cursor-based pagination to user API
   
   DESCRIPTION:
   ## Summary
   Added cursor-based pagination to `/api/users` so large datasets load faster.
   
   ## Context / Motivation
   Infinite scroll was timing out for enterprise tenants with 10k+ users.
   
   ## Key Changes
   - Introduced `PaginationService` with opaque cursor tokens
   - Updated `UserController` to accept `after` & `limit` params
   - Added happy-/edge-case integration tests (200 users, invalid cursors)
   
   ## Impact & Risk
   No breaking API changes; old `page`/`size` parameters remain for now.
   If response caching degrades, revert commit `abc123`.
   
   ## Issue Links & Closing
   Resolves #742
   
   ## Additional Notes
   Perf improved from ~4 s → 500 ms on staging. 🎉
   ---
   
   Based on the git diff provided, generate a PR title and description following the template above.

5. **Create the PR using gh CLI**
   - Use the generated title and description
   - Use the base branch determined in step 3 (default: `develop`)
   - Optionally add reviewers and assignees (see Team Members section below)
   - **Assignees should include all reviewers plus the PR author** (the person creating the PR)
   - Run: `gh pr create --title "<TITLE>" --body "<DESCRIPTION>" --base <BASE_BRANCH> [--reviewer USER1,USER2] [--assignee USER1,USER2,AUTHOR]`
   - Example with reviewers: `gh pr create --title "<TITLE>" --body "<DESCRIPTION>" --base develop --reviewer BenStringer3,AdrianFischer --assignee BenStringer3,AdrianFischer,$(git config user.name)`
   - If successful, show the user the PR URL
   - If it fails (e.g., gh not authenticated, no remote, etc.), show the error and suggest solutions

6. **Confirm Success**
   - Display the PR URL
   - Show a brief summary of what was created

## Team Members for Reviewers & Assignees

When creating PRs, you can add reviewers and assignees using their GitHub usernames:

**Available Reviewers (with write access):**
- `AdrianFischer` - Adrian
- `BenStringer3` - Ben
- `DaviidYan` - David
- `gpanicucci` - Gianluca
- `mayershoc` - Chris
- `Sajsaaa` - Sajsaaa (sha)

**To add reviewers/assignees:**
```bash
# Add reviewers when creating PR
gh pr create --title "..." --body "..." --base develop --reviewer BenStringer3,AdrianFischer

# Add assignees when creating PR (should include reviewers + author)
# Get current user: gh api user --jq .login
gh pr create --title "..." --body "..." --base develop --assignee BenStringer3,$(gh api user --jq .login)

# Add both reviewers and assignees (assignees = reviewers + author)
AUTHOR=$(gh api user --jq .login)
gh pr create --title "..." --body "..." --base develop --reviewer BenStringer3,AdrianFischer --assignee BenStringer3,AdrianFischer,$AUTHOR

# Add reviewers/assignees to existing PR
gh pr edit <PR_NUMBER> --add-reviewer BenStringer3,AdrianFischer
gh pr edit <PR_NUMBER> --add-assignee BenStringer3,$(gh api user --jq .login)
```

**Note:** Assignees should always include all reviewers plus the PR author (the person creating the PR). This ensures proper tracking and notification.

**To list all potential reviewers:**
```bash
# Get repository collaborators with write access
gh api repos/noyes-tech/nys_monorepo/collaborators --jq '.[] | select(.permissions.push == true) | .login'
```

Notes:
- If `gh` CLI is not installed or not authenticated, provide clear instructions
- Handle errors gracefully and provide actionable feedback
- The description should be generated purely from analyzing the code diff
- Be smart about identifying the type of change (Feature/Fix/Chore/etc.)
- **Important**: Only use **Feature:**, **Change:**, or **Fix:** for user/customer-facing changes (things users or customer support would want to know about)
- **Important**: Infrastructure, developer experience, deployment, test fixes, CI/CD, and tooling changes should always be categorized as **Chore:**
