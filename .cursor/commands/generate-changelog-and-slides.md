Goal:
Generate a release changelog entry and a set of review slides (Marp format) for the changes between a base commit/tag and the current HEAD.

Context:
- User needs to prepare release artifacts (Changelog + Slides)
- Input can be a specific tag, a commit hash, or we default to the last detected release
- We rely on `gh` CLI to get rich PR metadata (title, author, labels) instead of just raw git logs
- Output files: Prepend to `CHANGELOG.md` and create/overwrite `RELEASE_SLIDES.md`

Steps:

1. **Determine the Base Commit (Start Point)**
   Identify which mode the user is requesting:

   - **Mode A: Tag Name (e.g., "v4.15.0")**
     - If the user provides a version string like `v4.15.0`, find the corresponding git tag.
     - Note: Our tags often follow the format `vX.Y.Z-commithash` (e.g., `v4.15.0-e77b9e6e4`).
     - Action: Search for a tag matching the version: `git tag --list "v4.15.0*"`
     - If found, use that tag as the base.

   - **Mode B: Commit Hash (e.g., "e77b9e6")**
     - If the user provides a hash, verify it exists: `git rev-parse --verify <INPUT>`
     - Use this hash as the base.

   - **Mode C: Auto-detect (No input)**
     - If no input is provided, find the *latest* tag reachable from HEAD.
     - Action: Run `git describe --tags --abbrev=0`
     - Show the user the detected tag and ask for confirmation to use it as the base.

2. **Fetch PR Data (Inline Script)**
   Use the following bash script to extract PR details from the commit range.
   *Agent Instruction: Run this script block to generate a JSON dataset of changes.*

   #!/bin/bash
   BASE_REF="$1" # e.g. v4.15.0-hash
   HEAD_REF="HEAD"
   
   echo "Fetching changes from $BASE_REF to $HEAD_REF..."
   
   # 1. Get all unique PR numbers mentioned in commit messages in the range
   # We look for "Merge pull request #123" or standard (#123) patterns
   PR_NUMBERS=$(git log "$BASE_REF..$HEAD_REF" --format="%s %b" | grep -oE '#[0-9]+' | tr -d '#' | sort -u -n)
   
   if [ -z "$PR_NUMBERS" ]; then
     echo "No PRs found in this range."
     exit 0
   fi
   
   echo "Found PRs: $(echo "$PR_NUMBERS" | tr '\n' ' ')"
   
   # 2. Fetch details for each PR using gh CLI
   # We use a loop, but in a real script we might parallelize or use search if the range is huge.
   # Outputting a JSON Lines format for the LLM to parse easily.
   echo "["
   FIRST=1
   for PR in $PR_NUMBERS; do
     if [ "$FIRST" -ne 1 ]; then echo ","; fi
     # Fetch JSON data: number, title, author, body, url, labels
     gh pr view "$PR" --json number,title,author,body,url,labels,createdAt --jq \
       '{ "number": .number, "title": .title, "author": .author.login, "url": .url, "labels": [ .labels[].name ] }' || echo "{ \"error\": \"Failed to fetch PR #$PR\" }"
     FIRST=0
   done
   echo "]"
   3. **Generate Content**
   Using the JSON data retrieved from Step 2, generate the following two artifacts.

   **Artifact 1: Changelog Entry**
   - **Format**: Follow strict KeepAChangelog format (same as current `CHANGELOG.md`).
   - **Header**: `## vX.Y.Z ()`
   - **Categories**:
     - `### Added` for new features.
     - `### Changed` for changes in existing functionality.
     - `### Deprecated` for soon-to-be removed features.
     - `### Removed` for now removed features.
     - `### Fixed` for any bug fixes.
     - `### Security` for vulnerabilities.
     - `### Chore` for internal tasks (maintenance, refactors, tests).
   - **Item Format**: `- Description of change, [#123](https://github.com/.../123) - _Author_`
   - **Parsing Rules**:
     - Use PR titles/bodies to determine the category.
     - If a PR has `bug` label -> Fixed. `feature` -> Added. `chore` -> Chore.
     - Ensure **every** PR from the list is mentioned.

   **Artifact 2: Review Slides (Marp)**
   - **File**: `RELEASE_SLIDES.md`
   - **Format**: Marp Markdown.
   - **Slide Structure**:
     1. **Title Slide**: Release Version, Date, Commit Range (Base..Head).
     2. **Overview Slide**:
        - High-level summary of the changelog.
        - Statistics: Total PRs, Category Breakdown (Features/Fixes/Chores), Unique Contributors.
        - A one-sentence "Theme" of the release if discernible.
     3. **Deep Dive Slides (For Major Features or Strategic Clusters)**:
        - **Selection Logic**:
          - Identify "Major Features" (large Added/Changed items).
          - **CLUSTERING**: Scan PRs for shared keywords, labels (e.g., `area:auth`), or problem domains. Group multiple PRs that target the same user value or functional area.
          - Create a single Deep Dive slide for any cluster that represents a significant body of work, rather than one slide per PR.
        - **Content per Slide**:
          - **Title**: Feature Name or Cluster Theme (e.g., "Authentication Overhaul").
          - **The What**: A synthesized summary of the changes (e.g., "Refactored login flow and added 2FA support across 3 PRs").
          - **The Why (Value Add)**:
            - *CRITICAL*: Focus on the combined customer value of the group.
            - *CONSTRAINT*: **DO NOT HALLUCINATE**. If the value isn't clear, ask the user or use a placeholder `<!-- TODO: Input Value Add -->`. Only include information you are absolutely sure about.
          - **Context**: Process changes or stakeholder implications.
     4. **Notable Changes (TL;DR)**:
        - **Structure**:
          - Group by functional area where possible (e.g., "### UI Improvements", "### Performance").
          - Consolidate related minor PRs into single bullet points (e.g., "Various fixes for the settings page (#123, #125)").
          - Concise one-liners covering items that didn't warrant a Deep Dive.

4. **Review and Write**
   - **Validation Step**:
     - Before generating the final files, show the user the list of "Major Features" selected for Deep Dives.
     - **Explicitly ask** for the "Value Add" (The Why) if any were missing from the PR bodies.
   - Present the generated Changelog text and Slide text to the user for review.
   - If approved:
     - Prepend the Changelog text to `CHANGELOG.md` (preserve existing content).
     - Overwrite/Create `RELEASE_SLIDES.md` with the slide content.

Notes:
- If `gh` CLI fails (not authenticated), do not continue. Ask the user to authenticate and try again.
- Always ask the user for the target "New Version Number" (e.g., v4.16.0) if it wasn't explicit in the prompt.
