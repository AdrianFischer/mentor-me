# Create Plan

description: You are tasked with creating detailed implementation plans through an interactive, iterative process. You should be skeptical, thorough, and work collaboratively with the user to produce high-quality technical specifications.

## PART I - INVOCATION & SETUP

0. **Parameter Check & Initial Response**
   - If the command is invoked **with** a file path or ticket reference, skip the default prompt, immediately read the provided file(s) **fully (no offsets/limits)**, and start the research process.
   - If **no parameters** are provided, respond with:
     ```
     I'll help you create a detailed implementation plan. Let me start by understanding what we're building.

     Please provide:
     1. The task/ticket description (or reference to a ticket file)
     2. Any relevant context, constraints, or specific requirements
     3. Links to related research or previous implementations

     Tip: You can also invoke this command with a ticket file directly: `/create_plan thoughts/shared/tickets/eng_1234.md`
     For deeper analysis, try: `/create_plan think deeply about thoughts/shared/tickets/eng_1234.md`
     ```
   - Then wait for user input.

## PART II - CONTEXT GATHERING & INITIAL ANALYSIS

1. **Read All Mentioned Inputs Immediately**
   - Read every cited file (tickets, research docs, prior plans, JSON/data) **fully** with no offsets/limits.
   - Do **not** spawn sub-tasks until you have personally read the files in the main context.

2. **Spawn Initial Research Tasks (in parallel)**
   - Before asking questions, launch focused research using the right tools:
     - `codebase_search` (and `rg` where exact matches help) to locate relevant source files, configs, and tests.
     - Search the `thoughts/` tree for related research or plans (`thoughts/shared/research`, `thoughts/shared/plans`, tickets).
     - If external tickets exist (e.g., Linear/Jira), read them fully when accessible.
   - Be explicit about target directories (e.g., `nys_engine/react_storage_ui`, `nys_engine/nys_api`, `nys_engine/nys_brain`, `nys_deployment`) and what to extract (flows, data models, patterns, tests).

3. **Read All Files Identified by Research**
   - After tools return candidates, read the relevant files **fully** into context.

4. **Analyze & Verify Understanding**
   - Cross-check ticket requirements against actual code.
   - Note discrepancies, implicit constraints, and assumptions needing confirmation.

5. **Present Understanding + Focused Questions**
   - Provide a concise, evidence-based summary with file references.
   - Ask only the questions you cannot answer from code/notes.

## PART III - RESEARCH & DISCOVERY LOOP

1. **Incorporate Clarifications**
   - If the user corrects or adds context, verify by reading the referenced files/dirs yourself.

2. **Create a Research Todo List**
   - Use `TodoWrite` to track exploration tasks; keep at most one `in_progress`.

3. **Parallel Deep Dives**
   - Use targeted searches for:
     - Data models/migrations (`common/nys_store_db`, `nys_engine/nys_api/app/services`, `nys_engine/nys_api/app/api`).
     - UI flows (`nys_engine/react_storage_ui`).
     - Robotics/brain flows (`nys_engine/nys_brain`).
     - Deploy/ops impacts (`nys_deployment`).
     - Tests and fixtures (`nys_test`).
   - Request and capture specific file references in findings.

4. **Synthesize Findings & Options**
   - Share current-state findings, patterns to follow, constraints, and 2–3 design options with pros/cons.
   - List open questions explicitly; do not proceed with unknowns.

## PART IV - PLAN STRUCTURE ALIGNMENT

1. **Propose Outline**
   - Offer a brief plan structure (overview + phased steps) and confirm order/granularity with the user.

2. **Adjust per Feedback**
   - Update outline before writing the full plan.

## PART V - PLAN DRAFTING

1. **File Location & Naming**
   - Write the plan to `thoughts/shared/plans/YYYY-MM-DD-[ENG-XXXX-]kebab-description.md`
     - Include ticket ID (e.g., `ENG-1234`) when available; otherwise omit.

2. **Template**
   - Use this structure:
     ```
     # [Feature/Task Name] Implementation Plan

     ## Overview
     [Brief description of what we're implementing and why]

     ## Current State Analysis
     [What exists now, what's missing, key constraints discovered]

     ## Desired End State
     [Specification of the desired end state and how to verify it]

     ### Key Discoveries:
     - [Important finding with file:line reference]
     - [Pattern to follow]
     - [Constraint to work within]

     ## What We're NOT Doing
     [Explicitly list out-of-scope items]

     ## Implementation Approach
     [High-level strategy and reasoning]

     ## Phase 1: [Descriptive Name]
     ### Overview
     [What this phase accomplishes]

     ### Changes Required:
     #### 1. [Component/File Group]
     **File**: `path/to/file.ext`
     **Changes**: [Summary]
     ```[language]
     // Specific code to add/modify (if helpful)
     ```

     ### Success Criteria:
     #### Automated Verification:
     - [ ] Command(s): `make <target>` / `pytest ...` / `npm run ...`
     - [ ] Type/lint targets as applicable
     - [ ] Relevant integration/feature tests

     #### Manual Verification:
     - [ ] User-facing behavior confirmed
     - [ ] Performance/edge cases verified
     - [ ] No regressions in adjacent flows

     **Implementation Note**: After automated checks pass, pause for human confirmation of manual steps before proceeding to the next phase.

     ---

     ## Phase 2: ...
     [Repeat structure for additional phases]

     ## Testing Strategy
     ### Unit Tests:
     - [What to test and key edge cases]
     ### Integration Tests:
     - [End-to-end scenarios]
     ### Manual Testing Steps:
     1. [Step-by-step validation]

     ## Performance Considerations
     [Implications/optimizations]

     ## Migration Notes
     [Data/backfill/rollback steps if applicable]

     ## References
     - Ticket: `path/to/ticket`
     - Related research: `thoughts/shared/research/...`
     - Similar implementation: `[file:line]`
     ```

3. **Be Skeptical, Thorough, and Interactive**
   - No unresolved questions in the final plan.
   - Use measurable success criteria; prefer `make` targets over ad-hoc commands.
   - Include rollback/migration considerations when relevant.

## PART VI - REVIEW & SYNC

1. **Surface the Draft**
   - Share the plan path and request review on scope, success criteria, and technical details.

2. **Iterate**
   - Incorporate feedback; update the plan file.

3. **(Optional) Sync**
   - If a sync step is in use (e.g., syncing `thoughts`), run it after updates; otherwise note that syncing is manual.

## NOTES

- Use `TodoWrite` to track planning tasks; update statuses as you complete steps.
- Always read referenced files completely before planning.
- Keep citations with `file:line` references when noting findings.
- Focus on incremental, testable phases; avoid scope creep.
- If information is missing, pause and ask for clarification before drafting the plan.


