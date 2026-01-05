# Research Task

description: Deeply research a manually provided task or ticket

## PART I - INPUT & SETUP

0. **Get Task Information**:
   - Extract ticket ID (if provided) and description from user input
   - User should provide: ticket ID (optional, e.g., "ENG-1234"), title/description, and any relevant details/comments
   - Example input: "Research ENG-1234: Fix login authentication flow" or "Research how parent-child tracking works"
   - If user provides ticket details in their message, read and parse them
   - Ask user to paste any additional ticket details, comments, or requirements if needed

0a. **Create Research Document**:
   - Create directory structure if needed: `thoughts/shared/research/`
   - Generate filename: `YYYY-MM-DD-[TICKET-ID]-kebab-case-description.md`
     - Format: `YYYY-MM-DD-ENG-XXXX-description.md` (if ticket ID provided)
     - Format: `YYYY-MM-DD-description.md` (if no ticket ID)
   - Examples:
     - With ticket: `2025-01-08-ENG-1478-parent-child-tracking.md`
     - Without ticket: `2025-01-08-error-handling-patterns.md`
   - Initialize document with header:
     - Title: [Ticket ID if exists]: [Research Topic]
     - Date: YYYY-MM-DD
     - Original Request: [User's input]

think deeply

## PART II - RESEARCH

1. **Understand Research Needs**:
   - Read any provided ticket details/comments to understand what research is needed
   - Identify any previous attempts or context mentioned
   - Note any linked documents or referenced files in the input
   - If insufficient information, ask user for clarification before proceeding

think deeply about the research needs

2. **Conduct Deep Research**:
   
   2a. **Read Research Guidance**:
   - Read `.cursor/commands/research_codebase.md` for guidance on effective codebase research
   
   2b. **External Research** (if needed):
   - If the task suggests web research is needed (external solutions, APIs, best practices), use `WebSearch` to research
   - Document findings in the research document
   
   2c. **Codebase Research**:
   - Use `codebase_search` to find relevant implementations and patterns
   - Search for similar features or related code
   - Examine existing implementations
   - Identify technical constraints and opportunities
   
   2d. **Documentation Review**:
   - Read any linked documents or referenced files mentioned in the input
   - Check relevant documentation files
   
   2e. **Be Unbiased**:
   - Don't think too much about an ideal implementation plan
   - Document all related files and how the systems work *today*
   - Focus on understanding current state, not proposing solutions yet
   
   2f. **Continuous Documentation**:
   - Continuously append findings to the research markdown file
   - Use code references (```startLine:endLine:filepath) for specific code citations
   - Organize findings by topic/area
   - Include file paths, function names, and relevant code snippets

think deeply about the findings

## PART III - SYNTHESIS

3. **Synthesize Research into Actionable Insights**:
   
   3a. **Summarize Key Findings**:
   - Add a "Synthesis" section to the research document
   - Summarize key technical decisions and findings
   - Document how systems currently work
   
   3b. **Identify Implementation Approaches**:
   - Outline potential implementation approaches (if applicable)
   - Note different options and trade-offs
   
   3c. **Note Risks and Concerns**:
   - Identify any risks or concerns discovered
   - Note unknown variables or areas needing more investigation
   
   3d. **Save Research**:
   - Ensure the research document is complete and well-formatted
   - Document is saved at: `thoughts/shared/research/YYYY-MM-DD-[ID]-description.md`

think deeply

## PART IV - COMPLETION

4. **Report Results**:
   Print a message for the user (replace placeholders with actual values):

```
✅ Completed research for [TICKET-ID/Topic]: [research topic title]

Research topic: [research topic description]

The research has been:
- Created at thoughts/shared/research/YYYY-MM-DD-[ID]-description.md

Key findings:
- [Major finding 1]
- [Major finding 2]
- [Major finding 3]

[Additional findings as needed]
```

## Notes

- Use `TodoWrite` to track your tasks throughout the research process
- When conducting research, focus on understanding the current state of the system
- Be thorough but organized - document findings as you discover them
- Use code references (```startLine:endLine:filepath) when citing existing code
- If research reveals the need for external resources or clarification, ask the user
- The research document should be comprehensive enough for someone else to understand the current system state and make informed decisions

--- End Command ---

