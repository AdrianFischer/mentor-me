# analyze-allure-failures

Goal: Analyze failed tests from Allure reports downloaded by `view-ci-report.sh` to understand test failures, trace execution paths, and identify root causes.

## Critical Analysis Principles
1. **Question Assumptions**: Verify everything with evidence from test logs and source code.
2. **Understand Execution Flow**: Trace the test execution path through logs and stack traces.
3. **Correlate**: Link test failures with source code, log messages, and system behavior.
4. **Certainty**: Communicate clearly what is an assumption and what is a fact that can be proven with evidence.
5. **Propose, Do Not Implement**: Identify the root cause and propose a detailed technical implementation in the report, but **NEVER** apply the code changes to the codebase during analysis.
6. **Avoid Workspace Pollution**: **NEVER** download CI reports to workspace directories (e.g., `ci_reports/`, `reports/`). Always use `/tmp/ci-report-viewer/` or another temporary location outside the git repository.

---

## Section 0: Downloading Reports (Prerequisites)

### ⚠️ IMPORTANT: Download Location
**Always download reports to `/tmp/ci-report-viewer/` or another temporary directory outside the workspace.**
- ✅ **Correct**: `/tmp/ci-report-viewer/`
- ❌ **Wrong**: `ci_reports/`, `reports/`, or any directory in the git repository

Downloading to workspace directories will pollute your git working tree with CI artifacts.

### Method 1: Using view-ci-report.sh (Recommended)
```bash
# Run the interactive viewer, which downloads to /tmp/ci-report-viewer/
view-ci
# Select the CI run and job, then exit the viewer
# The report will be in /tmp/ci-report-viewer/
```

### Method 2: Manual Download
If you've already downloaded a report elsewhere, move it to the correct location:
```bash
# If you accidentally downloaded to workspace
mv ci_reports/brain_tests /tmp/ci-report-viewer/

# Or if you have it in another temp location
mv /path/to/your/report /tmp/ci-report-viewer/
```

---

## Section 1: Report Detection and Setup

### Information
1. **Report Location**: Allure reports should be in `/tmp/ci-report-viewer/` (or specify custom location via `REPORT_DIR` env var)
2. **Report Structure**: 
   - Test cases: `data/test-cases/*.json` (one JSON file per test)
   - Attachments: `data/attachments/*` (log files, screenshots, etc.)
   - Summary: `widgets/summary.json` (overall test statistics)
3. **Test Status**: Look for `status: "broken"` or `status: "failed"` in test case JSON files

### Setup Commands

**0. Find and Verify Allure Report**
```bash
# Set custom location if needed (defaults to /tmp/ci-report-viewer)
REPORT_DIR="${REPORT_DIR:-/tmp/ci-report-viewer}"

# Check if report exists at expected location
if [ -d "$REPORT_DIR/data/test-cases" ]; then
    echo "✓ Found report at: $REPORT_DIR"
elif [ -d "$REPORT_DIR" ]; then
    # Try to find report in subdirectories (artifact may have extracted to subdir)
    FOUND_REPORT=$(find "$REPORT_DIR" -type d -name "data" -path "*/test-cases" 2>/dev/null | head -1 | xargs dirname)
    if [ -n "$FOUND_REPORT" ]; then
        REPORT_DIR="$FOUND_REPORT"
        echo "✓ Found report at: $REPORT_DIR"
    else
        echo "ERROR: No Allure report found in $REPORT_DIR/"
        echo "Please download a report first (see Section 0)"
        exit 1
    fi
else
    echo "ERROR: Directory $REPORT_DIR does not exist"
    echo "Please download a report first (see Section 0)"
    exit 1
fi

# Verify report structure
if [ ! -d "$REPORT_DIR/data/test-cases" ]; then
    echo "ERROR: Invalid report structure. Missing data/test-cases/"
    echo "Report directory: $REPORT_DIR"
    ls -la "$REPORT_DIR"
    exit 1
fi

echo "Using report directory: $REPORT_DIR"
export REPORT_DIR
```

**1. Extract Failed Tests**
```bash
# Ensure REPORT_DIR is set (from step 0)
REPORT_DIR="${REPORT_DIR:-/tmp/ci-report-viewer}"

# Find all failed/broken test case JSON files
FAILED_TESTS=$(find "$REPORT_DIR/data/test-cases" -name "*.json" -exec sh -c 'jq -e ".status == \"broken\" or .status == \"failed\"" "$1" > /dev/null 2>&1 && echo "$1"' _ {} \;)

if [ -z "$FAILED_TESTS" ]; then
    echo "No failed or broken tests found in report"
else
    echo "Found $(echo "$FAILED_TESTS" | wc -l) failed/broken test(s):"
    echo "$FAILED_TESTS" | while read -r test_file; do
        test_name=$(jq -r '.fullName' "$test_file")
        test_status=$(jq -r '.status' "$test_file")
        echo "  - $test_status: $test_name"
    done
fi
```

**2. Get Test Summary**
```bash
REPORT_DIR="${REPORT_DIR:-/tmp/ci-report-viewer}"

# Get overall statistics
if [ -f "$REPORT_DIR/widgets/summary.json" ]; then
    echo "=== Test Summary ==="
    jq '.statistic' "$REPORT_DIR/widgets/summary.json"
else
    echo "WARNING: summary.json not found"
fi
```

---

## Section 2: Test Case Analysis

### Information
- **Test Case JSON Structure**:
  - `status`: "broken", "failed", "passed", etc.
  - `statusMessage`: Exception/error message
  - `statusTrace`: Full stack trace with file paths and line numbers
  - `fullName`: Test identifier (e.g., `customer_tests.test_mag.TestMag#test_name`)
  - `testStage.steps[]`: Steps containing attachments
  - `testStage.steps[].attachments[]`: Array with `source`, `name`, `type`, `size`

### Useful Commands

**1. Extract Test Failure Details**
```bash
TEST_CASE_FILE="path/to/test-case.json"  # Replace with actual file

# Get test name and status
jq -r '"\(.name)|\(.status)|\(.fullName)"' "$TEST_CASE_FILE"

# Get failure message
jq -r '.statusMessage' "$TEST_CASE_FILE"

# Get full stack trace
jq -r '.statusTrace' "$TEST_CASE_FILE"
```

**2. Parse Stack Trace**
```bash
# Extract file paths and line numbers from stack trace
jq -r '.statusTrace' "$TEST_CASE_FILE" | grep -E "\.py:[0-9]+" | sed 's/.*\([^\/]*\.py:[0-9]\+\)/\1/' | sort -u
```

**3. Map Test to Source Code**
```bash
# Parse fullName to get source file path
FULL_NAME=$(jq -r '.fullName' "$TEST_CASE_FILE")
# Example: customer_tests.test_mag.TestMag#test_name
# Convert: customer_tests.test_mag -> nys_test/customer_tests/test_mag.py

MODULE_PATH=$(echo "$FULL_NAME" | sed 's/#.*//' | sed 's/\.[^.]*$//')
TEST_FILE="nys_test/${MODULE_PATH//\./\/}.py"
echo "Test file: $TEST_FILE"
```

---

## Section 3: Log Extraction

### Information

#### Attachment System Architecture

The test framework uses a centralized `AttachmentTracker` system to manage all attachments. Attachments are created through several mechanisms:

1. **Automatic Log Attachments** (via `conftest.py` hooks):
   - **"Setup Logs"**: Python logger output captured during test fixture setup phase (`pytest_runtest_setup` hook)
     - Contains: Test initialization, fixture setup, database resets, container startup messages
     - Format: Text logs with timestamps, log levels, and messages
   - **"Test Body Logs"**: Python logger output captured during test execution (`pytest_runtest_call` hook)
     - Contains: Test execution steps, assertions, API calls, business logic logs
     - Format: Text logs with timestamps, log levels, and messages
   - **"Teardown Logs"**: Python logger output captured during test cleanup (`pytest_runtest_teardown` hook)
     - Contains: Cleanup operations, fixture teardown, container shutdown messages
     - Format: Text logs with timestamps, log levels, and messages

2. **Fluentd System Logs** (only attached for failed tests):
   - **"fluentd startup logs"**: System logs from Docker containers during setup phase
     - Contains: Container startup logs, service initialization, database migrations, configuration loading
     - Format: Gzipped daily log files (`combined.YYYYMMDD.log.gz`) filtered by UTC timestamps
     - Source: `/home/devuser/nys_deployment_ws/logs/combined.*.log.gz`
   - **"fluentd body logs"**: System logs from Docker containers during test execution
     - Contains: Application logs, API requests/responses, database queries, MQTT messages, ROS2 logs
     - Format: Same as above, filtered for test execution window
   - **"fluentd teardown logs"**: System logs from Docker containers during teardown phase
     - Contains: Container shutdown logs, cleanup operations, final state dumps
     - Format: Same as above, filtered for teardown window

3. **Fixture Artifacts** (collected via registered collectors during teardown):
   - **"sim screenshot"**: VNC screenshot from simulation container
     - Source: `vncsnapshot` command capturing the simulation VNC display
     - Format: JPG image
     - Collector: Registered by `sim_fixture` fixture
   - **"app screenshot"** / **"app{i} screenshot"**: Selenium screenshots from browser automation
     - Source: Selenium WebDriver `save_screenshot()` calls
     - Format: PNG image
     - Collector: Registered by `app_fixture` fixture
   - Other fixture-specific artifacts may be collected by other fixtures

4. **Manual Attachments** (from test code or helpers):
   - Brain logs, profiling results, UI screenshots, test output JSON, environment configurations, etc.
   - Created via `AttachmentTracker.attach()` or `AttachmentTracker.attach_file()` calls

#### Attachment Location and Structure

- **Attachment Location**: Files are in `data/attachments/{source}` where `source` is the filename from the attachment object
- **Attachment Metadata**: Each attachment in the test case JSON has:
  - `source`: Filename in `data/attachments/` directory
  - `name`: Human-readable name (e.g., "Setup Logs", "fluentd body logs", "sim screenshot")
  - `type`: MIME type or Allure attachment type
  - `size`: File size in bytes

#### Component Relationships

The attachment system works through the following relationships:

1. **AttachmentTracker** (`nys_test/helpers/attachment_tracker.py`):
   - Central manager that tracks all attachments in a list
   - Provides `attach()` for text content and `attach_file()` for existing files
   - Maintains a registry of fixture log collectors (`_log_collectors`)
   - All attachments are stored in `allure-results/` directory during test execution

2. **conftest.py hooks**:
   - `pytest_runtest_setup`: Captures "Setup Logs" from `BufferingHandler` (Python logger output)
   - `pytest_runtest_call`: Captures "Test Body Logs" from `BufferingHandler` (Python logger output)
   - `pytest_runtest_teardown`: 
     - Captures "Teardown Logs" from `BufferingHandler` (Python logger output)
     - For failed tests only: Attaches Fluentd logs (startup, body, teardown phases)
     - Collects fixture artifacts by calling registered collectors for each fixture

3. **Fixture Log Collectors**:
   - Fixtures register collectors during setup (e.g., `sim_fixture`, `app_fixture`)
   - Collectors are called during teardown to gather artifacts (screenshots, logs, etc.)
   - Collectors return tuples of `(source, name, extension)` or lists of such tuples

4. **Jira Integration** (`nys_test/helpers/jira_fixtures.py`):
   - `upload_attachments()` retrieves all attachments from `AttachmentTracker.get_attachments()`
   - Uploads attachments to Jira tickets for failed tests
   - Only runs when Jira integration is enabled (develop branch, no uncommitted changes)

### Useful Commands

**1. List All Attachments for a Test**
```bash
TEST_CASE_FILE="path/to/test-case.json"

# Get all attachments with their names, sources, types, and sizes
jq -r '.testStage.steps[] | select(.attachments != null and (.attachments | length) > 0) | .attachments[] | "\(.name)|\(.source)|\(.type)|\(.size)"' "$TEST_CASE_FILE"

# Or in a more readable format with headers
echo "Name|Source|Type|Size"
jq -r '.testStage.steps[] | select(.attachments != null and (.attachments | length) > 0) | .attachments[] | "\(.name)|\(.source)|\(.type // "unknown")|\(.size // "unknown")"' "$TEST_CASE_FILE" | column -t -s '|'
```

**2. Extract Specific Log Types**
```bash
TEST_CASE_FILE="path/to/test-case.json"
REPORT_DIR="${REPORT_DIR:-/tmp/ci-report-viewer}"

# Extract Setup Logs
SETUP_SOURCE=$(jq -r '.testStage.steps[] | select(.attachments != null) | .attachments[] | select(.name == "Setup Logs") | .source' "$TEST_CASE_FILE" | head -1)
if [ -n "$SETUP_SOURCE" ]; then
    cat "$REPORT_DIR/data/attachments/$SETUP_SOURCE"
fi

# Extract Test Body Logs
BODY_SOURCE=$(jq -r '.testStage.steps[] | select(.attachments != null) | .attachments[] | select(.name == "Test Body Logs") | .source' "$TEST_CASE_FILE" | head -1)
if [ -n "$BODY_SOURCE" ]; then
    cat "$REPORT_DIR/data/attachments/$BODY_SOURCE"
fi

# Extract Teardown Logs
TEARDOWN_SOURCE=$(jq -r '.testStage.steps[] | select(.attachments != null) | .attachments[] | select(.name == "Teardown Logs") | .source' "$TEST_CASE_FILE" | head -1)
if [ -n "$TEARDOWN_SOURCE" ]; then
    cat "$REPORT_DIR/data/attachments/$TEARDOWN_SOURCE"
fi

# Extract Fluentd logs (may be large)
FLUENTD_SOURCES=$(jq -r '.testStage.steps[] | select(.attachments != null) | .attachments[] | select(.name | contains("fluentd")) | .source' "$TEST_CASE_FILE")
for source in $FLUENTD_SOURCES; do
    echo "=== Fluentd log: $source ==="
    head -100 "$REPORT_DIR/data/attachments/$source"  # Show first 100 lines
done

# Extract Fixture Artifacts (screenshots, etc.)
FIXTURE_ARTIFACTS=$(jq -r '.testStage.steps[] | select(.attachments != null) | .attachments[] | select(.name | test("screenshot|Screenshot|report|Report")) | "\(.name)|\(.source)"' "$TEST_CASE_FILE")
if [ -n "$FIXTURE_ARTIFACTS" ]; then
    echo "=== Fixture Artifacts ==="
    echo "$FIXTURE_ARTIFACTS"
    # Note: Image files (jpg, png) cannot be displayed in terminal, but you can check they exist
    echo "$FIXTURE_ARTIFACTS" | while IFS='|' read -r name source; do
        if [ -f "$REPORT_DIR/data/attachments/$source" ]; then
            echo "  ✓ $name: $source ($(stat -c%s "$REPORT_DIR/data/attachments/$source" 2>/dev/null || echo "unknown") bytes)"
        else
            echo "  ✗ $name: $source (FILE NOT FOUND)"
        fi
    done
fi
```

**3. Filter Logs for Errors**
```bash
# Filter for ERROR, FATAL, Exception, Traceback
LOG_FILE="path/to/log/file.txt"
grep -iE "\[ERROR\]|ERROR|\[FATAL\]|FATAL|Exception|Traceback|Error:" "$LOG_FILE" | head -50
```

---

## Section 4: Source Code Cross-Reference

### Information
- **Stack Trace Format**: Python stack traces show file paths relative to test execution context
- **File Path Mapping**: 
  - `customer_tests/test_mag.py:35` → `nys_test/customer_tests/test_mag.py:35`
  - `helpers/misc_helpers.py:686` → `nys_test/helpers/misc_helpers.py:686`
- **UUT Identification**: Analyze test imports and function calls to identify what code is being tested

### Useful Commands

**1. Extract Source Code Context**
```bash
# Parse stack trace to get file:line pairs
STACK_TRACE=$(jq -r '.statusTrace' "$TEST_CASE_FILE")

# Extract file paths and line numbers
echo "$STACK_TRACE" | grep -oE "[a-zA-Z0-9_/]+\.py:[0-9]+" | while read -r file_line; do
    FILE=$(echo "$file_line" | cut -d: -f1)
    LINE=$(echo "$file_line" | cut -d: -f2)
    
    # Map to actual source file
    if [[ "$FILE" == *"test_"* ]] || [[ "$FILE" == helpers/* ]]; then
        SOURCE_FILE="nys_test/$FILE"
    else
        # May be in nys_engine or other locations
        SOURCE_FILE=$(find /monorepo -name "$(basename "$FILE")" -type f | head -1)
    fi
    
    if [ -f "$SOURCE_FILE" ]; then
        echo "=== $SOURCE_FILE:$LINE ==="
        # Show context around the error line (5 lines before, 10 lines after)
        sed -n "$((LINE > 5 ? LINE - 5 : 1)),$((LINE + 10))p" "$SOURCE_FILE"
    fi
done
```

**2. Find Log Messages in Source Code**
```bash
# Search for log messages mentioned in test logs
LOG_MESSAGE="asserting all logistic requests succeeded"  # Example from logs
grep -r "$LOG_MESSAGE" /monorepo/nys_test/ /monorepo/nys_engine/ 2>/dev/null
```

**3. Identify UUT (Unit Under Test)**
```bash
# Read test source file and analyze imports
TEST_FILE="nys_test/customer_tests/test_mag.py"

# Show imports
grep -E "^import |^from " "$TEST_FILE" | head -20

# Show function calls in test
grep -E "def test_" "$TEST_FILE" -A 50 | grep -E "^\s+[a-zA-Z_][a-zA-Z0-9_]*\(" | head -20
```

---

## Section 5: Analysis Report Generation

### Output Report Format

*Use this template to structure your findings. Continuously update it as you find new evidence.*
*The task is complete when all evidence is gathered and the problem is fully understood.*
*The report is saved in report-analysis/allure-YYYY-MM-DD-HH-MM-SS-analysis.md.*

```markdown
# Test Failure Analysis: [Short Descriptive Title]

## TL;DR
**Issue**: [One sentence summary of the problem]
**Root Cause**: [One sentence summary of why it happened]
**Fix**: [One sentence summary of the recommended solution]

## Problem Summary

[Brief description of what went wrong, observed symptoms, and impact]
- Test: `[test name from fullName]`
- Status: `[broken/failed]`
- Symptom 1
- Symptom 2

## Root Cause Analysis

### Test Execution Flow

1. **[Test Phase]** - [What happened]
   - File: `path/to/file.py:line`
   - Code context:
   ```python
   [Relevant code snippet]
   ```

### Key Findings

[Describe the core discovery that explains the issue]

```
[Insert relevant log snippet proving the finding]
```

### Stack Trace Analysis

**Exception**: `[Exception type and message from statusMessage]`

**Call Stack**:
1. `file.py:line` - `function_name()` - [Description]
2. `file.py:line` - `function_name()` - [Description]
3. ...

**Error Location**: `file.py:line` in `function_name()`
```python
[Code context around error line]
```

### Technical Details

#### [Subsystem/Component Name] Logic
[Explain how the system *should* work versus how it *did* work]

#### Why [Expected Behavior] Failed
1. Reason 1
2. Reason 2

#### Code Location
- **File**: `path/to/file.py`
- **Method**: `method_name()`
- **Line**: `line_number`
- **Log message**: `"Unique log message identifying the issue"`

### Log Evidence

**Setup Logs**:
```
[Relevant setup log snippets]
```

**Test Body Logs**:
```
[Relevant test execution log snippets]
```

**Fluentd Logs** (if relevant):
```
[Relevant system log snippets]
```

## Recommendations

1. **[Action Item 1]**: [Description of fix/improvement]
2. **[Action Item 2]**: [Description of fix/improvement]

## Fix with AI
*Use this prompt to instruct the next agent to implement the fix:*

```text
The analysis of the test failure revealed a critical issue in [Subsystem Name].
Please implement the following fix:

**Context**:
[Brief context about the problem]

**Task**:
0. Create a test to reproduce the issue
1. Modify [File Path]
2. Update function [Function Name] to [Description of Change]
3. [Optional: Add specific constraints or edge cases to handle]

**Reference**:
See the "Technical Details" section above for code locations and logic.
```

## Evidence

### Test Information
- **Test Name**: `[fullName]`
- **Test File**: `[mapped source file]`
- **Status**: `[broken/failed]`
- **Exception**: `[statusMessage]`

### Stack Trace
```
[Full statusTrace]
```

### Key Log Messages
```
[Important log snippets]
```
```

---

## Workflow

1. **Download Report** (Section 0): Download Allure report to `/tmp/ci-report-viewer/` using `view-ci`
2. **Detect Report** (Section 1): Find and verify the report location
3. **Extract Failed Tests** (Section 1): Parse all test case JSON files to find failed/broken tests
4. **For Each Failed Test**:
   - Extract test metadata (name, status, fullName)
   - Parse stack trace to get file paths and line numbers
   - Extract logs from attachments (Setup, Body, Teardown, Fluentd)
   - Map test name to source code file
   - Read source code context around error lines
   - Cross-reference logs with source code
   - Identify UUT and execution path
5. **Generate Analysis**: Create structured report following the template above
6. **Save Report**: Write to `report-analysis/allure-YYYY-MM-DD-HH-MM-SS-analysis.md`
7. **Cleanup** (Optional): Remove downloaded report from `/tmp/ci-report-viewer/` if no longer needed

## Tips

- **Start with stack trace**: The stack trace shows exactly where the failure occurred
- **Read source code**: Always read the actual source code around error lines to understand context
- **Correlate logs**: Match log messages in test logs with log statements in source code
- **Identify UUT**: Look at test imports and function calls to understand what's being tested
- **Attachment analysis order**:
  1. **Setup Logs**: Check first if failure occurred during fixture setup (containers, database, etc.)
  2. **Test Body Logs**: Primary source for understanding test execution flow and business logic failures
  3. **Fluentd logs**: System-level logs (only for failed tests) - check for container crashes, service errors, database issues
  4. **Fixture artifacts**: Screenshots can show UI state at failure point (if UI tests)
  5. **Teardown Logs**: Usually less relevant but may show cleanup issues
- **Fluentd log analysis**: 
  - Fluentd logs are timestamped with epoch timestamps in brackets `[1234567890.123]`
  - Logs are filtered by UTC time windows matching test phases
  - Look for ERROR/FATAL messages, exceptions, and service-specific error patterns
  - Large log files: Use `head`/`tail` or `grep` to filter relevant sections
- **Multiple failures**: If multiple tests failed, look for common patterns or root causes
- **Download location**: Always use `/tmp/ci-report-viewer/` to avoid workspace pollution

## Troubleshooting

### Report Not Found
- Verify the report was downloaded to `/tmp/ci-report-viewer/`
- Check if artifact extracted to a subdirectory: `find /tmp/ci-report-viewer -type d -name "data"`
- Ensure you have the correct artifact name from `gh run view <RUN_ID> --json artifacts`

### Invalid Report Structure
- Verify the artifact is an Allure report (should contain `data/test-cases/`, `widgets/`, etc.)
- Some artifacts may be compressed - extract first if needed

### Workspace Pollution
If you accidentally downloaded to a workspace directory:
```bash
# Move to correct location
mv ci_reports/* /tmp/ci-report-viewer/
# Remove from workspace
rm -rf ci_reports/
# Add to .gitignore if needed
echo "ci_reports/" >> .gitignore
```
