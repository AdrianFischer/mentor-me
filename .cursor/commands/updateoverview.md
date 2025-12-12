# Update Overview Command

This command scans all todo files in the `to_dos/` directory and updates the `overview.md` file with the latest state and focus information.

## Instructions

1. **Scan all todo files**: Read all `.md` files in the `to_dos/` directory
2. **Parse each todo file** to extract:
   - **Identifier**: Found on line 2 of each todo file
   - **Description**: Found on line 1 of each todo file
   - **State**: Found in the "Summary" section, line starting with "State:"
   - **Focus**: Found in the "Summary" section, line starting with "Focus:"
3. **Update overview.md**: 
   - Replace the table rows with the latest information from all todo files
   - Format each row as: `| **identifier**<br>Description | State | Focus |`
   - Update the "Last updated" date to today's date (format: YYYY-MM-DD)
4. **Preserve the table structure**: Keep the header row and separator row intact

## Expected Output Format

The overview.md should have:
- A header "# To-Do Overview"
- A table with columns: ID / Task | State | Focus
- One row per todo file found
- A "Last updated" line at the bottom

## Example

For a todo file with:
- Line 1: "Prepare release for GLT"
- Line 2: "glt_release_preparation"
- State: "Optimization & Profiling"
- Focus: "Snapshot implementation for caching"

The table row should be:
`| **glt_release_preparation**<br>Prepare release for GLT | Optimization & Profiling | Snapshot implementation for caching |`

