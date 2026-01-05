# analyze-logs

Goal: Analyze log files from customer systems (called a report) to understand system behavior, track requests/jobs, and debug issues.

## Critical Analysis Principles
1. **Question Assumptions**: Verify everything with evidence.
2. **Understand Behavior**: Gather evidence of what happened over time.
3. **Correlate**: Link logs from different components (Brain, Bot, etc.).
4. **Certainty**: Communicate clearly what is an assumption and what is a fact that can be proven with evidence.
5. **Propose, Do Not Implement**: Identify the root cause and propose a detailed technical implementation in the report, but **NEVER** apply the code changes to the codebase during log analysis.

---

## Section 1: Basics // Overview

*These steps are always helpful to provide context and a solid starting point.*

### Information
1. **Environment Setup**: Define your log directory variables first.
2. **Noise Filtering**: The logs contain high-frequency telemetry (RSSI, Wifi scan, Free memory) that obscures important events. Always filter this out.
3. **Error Scouting**: Quickly identifying Errors, Fatals, and Tracebacks gives you the "health pulse" of the system.
4. **Log File Formats**: Logs may be in different formats:
   - Individual service logs: `nys_deployment_ws-*.logs` (e.g., `nys_deployment_ws-brain-1.logs`)
   - Combined logs: `combined.YYYYMMDD.log` (all services combined with prefixes like `brain:`, `noyes-api:`)
   - Adjust grep patterns accordingly (e.g., for combined logs, you may need to search without the `-name "*.logs"` filter)

### Useful Greps

**0. Setup Environment Variables**
```bash
LOG_DIR="nys_deployment_ws-..."  # Set this to your log folder

# Convert Unix timestamp to human-readable (useful for timeline analysis)
timestamp_to_date() {
    date -r "$1" 2>/dev/null || date -d "@$1" 2>/dev/null
}
```

**1. Filter Noise (The "Clean" View)**
Use this chain to see "everything except the noise". This filters out high-frequency bot logs.
```bash
alias grep_clean='grep -v "nys_bot_logger.*rssi:" | grep -v "nys_bot_logger.*Free memory:" | grep -v "nys_bot_logger.*Neighbour channel mask" | grep -v "nys_bot_logger.*wifi scan" | grep -v "nys_bot_logger.*wifi_scan" '

# Usage example for .logs files:
find "$LOG_DIR" -name "*.logs" -exec grep . {} \; | grep_clean | head -50

# Usage example for combined.log files:
find "$LOG_DIR" -name "combined.*.log" -exec grep . {} \; | grep_clean | head -50
```

**2. Find Errors and Fatals**
```bash
echo "=== ERRORS & FATALS ==="
find "$LOG_DIR" -name "*.logs" -exec grep -iE "\[ERROR\]|ERROR|\[FATAL\]|FATAL" {} \; | grep_clean | sort
```

**3. Find Python Tracebacks**
```bash
echo "=== TRACEBACKS ==="
find "$LOG_DIR" -name "*.logs" -exec grep -iE "Traceback|Exception|Error:" {} \; | grep_clean | sort
```

**4. Find All Events**
```bash
echo "=== EVENTS ==="
find "$LOG_DIR" -name "*.logs" -exec grep "\[EVENT\]" {} \; | grep_clean | sort
```

**5. Timeline Analysis by Timestamp Range**
When investigating a specific time period, search by timestamp prefix to narrow down events.

```bash
# Example: Search for bot activity during Nov 1-2 (timestamps starting with 176198, 176199, 17620, 17621)
BOT_ID="1093"
TIMESTAMP_PREFIX="176198" # First 6 digits of timestamp (Nov 1, 2025)
find "$LOG_DIR" -name "*.logs" -exec grep "bot${BOT_ID}" {} \; | grep "$TIMESTAMP_PREFIX" | grep_clean | sort

# For brain logs specifically (which are very large), use direct grep on the file
cat "$LOG_DIR/nys_deployment_ws-brain-1.logs" | grep "bot${BOT_ID}" | grep "$TIMESTAMP_PREFIX" | grep_clean | sort

# Convert timestamp to date for reference:
# timestamp_to_date 1761981226  # Returns human-readable date
```


---

## Section 4: Tracing what the robot does

*Use when analyzing robot connectivity, driver issues, or command execution.*
*Relevant Files: `nys_bot_driver/bot_driver.py`, `nys_bot_driver/bot_driver_manager.py`*

### Information
- **Setup Messages**: The heartbeat of the connection. When a bot connects/reconnects, it sends a `setup_bot` message.
- **Acknowledgments**: The Brain sends a `setup_confirmation` ack. If this loop fails, the bot isn't properly connected.
- **Command/Feedback**: The Driver sends commands and waits for `noyesbot_feedback`.
- **Onboarding/Offboarding**: `BotDriverManager` handles adding/removing bots from the fleet.
- **BotCommander Activity**: The absence of `BotCommander botXXX` logs or `Got feedback for command` indicates a bot is not responding to movement commands, even if telemetry is still being received.

### Useful Greps

**1. Bot Connection & Setup**
Check for bots connecting (`setup_bot`) and getting acknowledged (`setup_confirmation`).
```bash
find "$LOG_DIR" -name "*.logs" -exec grep -E "setup_bot|setup_confirmation|setup message|BotDriverManager" {} \; | grep_clean | sort
```

**2. Specific Bot Driver Activity**
Focus on one bot's driver to see commands sent and feedback received.
```bash
BOT_ID="1063" # Replace with target bot
find "$LOG_DIR" -name "*.logs" -exec grep "bot${BOT_ID}" {} \; | grep_clean | sort
```

**3. Command Execution Problems**
Find where commands might be retrying or failing (e.g. "Didn't receive feedback").
```bash
find "$LOG_DIR" -name "*.logs" -exec grep -E "Didn't receive feedback|sending again|Exceeded number of tries" {} \; | sort
```

**4. BotCommander Activity (Command Execution)**
Check if a bot is responding to movement commands. Absence of these logs indicates the bot is not executing commands.
```bash
BOT_ID="1071" # Replace with target bot
find "$LOG_DIR" -name "*.logs" -exec grep "BotCommander.*bot${BOT_ID}\|Got feedback.*bot${BOT_ID}" {} \; | grep_clean | sort
```
---

## Section 2: Charging related problems

*Use when analyzing battery issues, charging behavior, or charging manager errors.*
*Relevant Files: `nys_charging_manager/main.py`, `bot_driver.py`, `BatteryStatus.msg`, `bot.py`*

### Information
- **Key Component**: `ChargingManager` manages the state machine for each bot (INIT -> CHARGED -> ENROUTE -> CHARGING...).
- **Battery Status**: Bots send `BatteryStatus` messages. Look for voltage drops, drifts, or messages where `charging_state` doesn't match the `ChargingManager` state.
- **Drift**: The system monitors for "Drift" where voltage and percentage don't align (e.g., high voltage but low SOC).
- **Timeouts**: There are timeouts for reaching the charger or charging not starting.
- **State Desynchronization**: A critical failure mode occurs when the Charging Manager enters `CHARGING` state (based on "Docked" message) but the bot never actually starts charging (`charging_state=False` in battery messages). Always verify that `charging_state=True` appears in battery messages after docking.
- **Docking vs Charging**: A bot can dock without charging starting. The "Docked" message indicates physical connection, but `charging_state=True` in battery messages confirms actual charging is occurring.
- **ChargingJob vs ChargingManager**: 
  - `ChargingJob` is an orchestrator-level job that coordinates sending a bot to charge
  - `ChargingManager` is the component that manages the charging state machine
- **Normal Charging Behavior at High SOC**: 
  - **IMPORTANT**: Bots at charging stations may show `charging_state=False` when:
    - SOC is at 100% (fully charged, no current pushed into battery)
    - SOC is between 90-100% (charger may cycle on/off to increase battery lifetime)
  - This is **normal behavior** and not a failure. Only investigate if `charging_state=False` persists at SOC < 90% while ChargingManager is in CHARGING state.
- **Battery Message Frequency**: Battery messages typically arrive every 10-70 seconds. Gaps > 10 minutes indicate potential communication issues.

### Useful Greps

**1. Charging Manager Overview**
See all decisions made by the Charging Manager.
```bash
find "$LOG_DIR" -name "*.logs" -exec grep "charging_manager" {} \; | grep_clean | sort
```

**2. Battery Status & Drifts for a Specific Bot**
See raw battery updates and drift warnings.
```bash
BOT_ID="1063" # Replace with target bot
find "$LOG_DIR" -name "*.logs" -exec grep "bot${BOT_ID}" {} \; | grep -iE "Battery|drift|voltage|soc" | sort
```

**3. Charging State Transitions**
Track when bots are requested to charge or uncharge.
```bash
find "$LOG_DIR" -name "*.logs" -exec grep -E "Request.*charging|transition|state=" {} \; | grep "charging_manager" | sort
```

**4. Warnings and Thresholds**
Find logs related to critical battery levels, temperature, or thresholds.
```bash
find "$LOG_DIR" -name "*.logs" -exec grep -iE "CRITICAL|WARN|temperature|threshold" {} \; | grep "charging_manager" | sort
```

**5. Detect Charging State Desynchronization**
**Critical Pattern**: Check if Charging Manager believes a bot is charging, but battery messages show `charging_state=False`. This indicates a state desynchronization where the bot docked but charging never started.

```bash
BOT_ID="1093" # Replace with target bot
# Step 1: Find when Charging Manager entered CHARGING state
find "$LOG_DIR" -name "*.logs" -exec grep "charging_manager.*bot${BOT_ID}.*now charging\|bot${BOT_ID}.*state=ChargeState.CHARGING" {} \; | grep_clean | sort

# Step 2: Find battery messages after that timestamp showing charging_state=False
# Extract timestamp from Step 1, then search for battery messages after that time
TIMESTAMP_START="1761981226" # Replace with timestamp from Step 1
find "$LOG_DIR" -name "*.logs" -exec grep "bot${BOT_ID}.*BatteryStatus.*charging_state=False" {} \; | awk -v ts="$TIMESTAMP_START" '$0 ~ ts || $0 ~ /\[.*\]/ {if ($0 ~ /\[.*\]/) {match($0, /\[([0-9]+\.[0-9]+)\]/, arr); if (arr[1] > ts) print}}' | sort

# Alternative: Simple check for any battery messages with charging_state=False while in CHARGING state
find "$LOG_DIR" -name "*.logs" -exec grep "bot${BOT_ID}" {} \; | grep -E "BatteryStatus.*charging_state=False|now charging.*bot${BOT_ID}" | sort
```

**6. Verify Docking vs Actual Charging**
**Important**: "Docked" message doesn't guarantee charging started. Always verify with battery messages showing `charging_state=True`.

```bash
BOT_ID="1093" # Replace with target bot
# Find docking event
find "$LOG_DIR" -name "*.logs" -exec grep "bot${BOT_ID}.*Docked\|Docked.*bot${BOT_ID}" {} \; | grep_clean | sort

# Then verify charging actually started (should see charging_state=True within minutes)
find "$LOG_DIR" -name "*.logs" -exec grep "bot${BOT_ID}.*BatteryStatus.*charging_state=True" {} \; | grep_clean | sort
```
---

## Section 3: Tracing Requests and Jobs

*Use when analyzing order flow, stuck jobs, or orchestration logic.*
*Relevant Files: `store_orchestrator_2/main.py`, `request_manager.py`, `request.py`, `jobs.py`, `magician.py`*

### Information
- **Request Lifecycle**: Requests move from `CREATED` -> `ACCEPTED` -> `EXECUTING` -> `SUCCEEDED` (or `ABORTED`/`CANCELLED`).
- **Job Graph**: The `Head_level` or `[JobGraph]` logs show the active jobs and their dependencies.
- **Magician**: The `[MAGICIAN]` component makes decisions about buffer usage, carrier selection, and job generation.
- **Job Updates**: `[JobUpdate]` tags show status changes (EXECUTING -> SUCCEEDED).
- **Stuck Jobs**: Jobs can get stuck if:
  - Bot disconnects during execution
  - Bot becomes unresponsive to commands
  - Job has no timeout mechanism
  - Look for jobs that appear repeatedly in executor logs without status updates

### Useful Greps

**1. Request Lifecycle (High Level)**
See how requests flow through the system.
```bash
find "$LOG_DIR" -name "*.logs" -exec grep -E "\[RequestManager\]|Request.*(ACCEPTED|EXECUTING|SUCCEEDED|ABORTED)" {} \; | sort
```

**2. Job Updates**
Track individual jobs succeeding or failing.
```bash
find "$LOG_DIR" -name "*.logs" -exec grep "\[JobUpdate\]" {} \; | sort
```

**3. Magician Decisions**
See why specific decisions were made (buffer updates, carrier selection).
```bash
find "$LOG_DIR" -name "*.logs" -exec grep "\[MAGICIAN\]" {} \; | sort
```

**4. Trace a Specific Request UUID**
Once you find a Request UUID (e.g., from the high-level view), trace it everywhere.
```bash
REQ_UUID="53dac74b..." # Replace with your UUID
find "$LOG_DIR" -name "*.logs" -exec grep "$REQ_UUID" {} \; | grep_clean | sort
```

**5. Detect Stuck Jobs**
Find jobs that appear repeatedly in executor logs but never complete.
```bash
# Find jobs that appear in executor repeatedly
find "$LOG_DIR" -name "*.logs" -exec grep "\[Executor\].*Starting executable jobs" {} \; | grep_clean | sort | uniq -c | sort -rn

# For a specific job, check if it ever completed
JOB_ID="e2a5" # Replace with job ID
find "$LOG_DIR" -name "*.logs" -exec grep "${JOB_ID}" {} \; | grep -E "SUCCEEDED|ABORTED|CANCELLED|JobUpdate" | grep_clean | sort
```

---

## Section 5: Output Report Format

*Use this template to structure your findings. Continuously update it as you find new evidence.*
*The task is complete when all evidence is gathered and the problem is fully understood.*
*The report is saved in report-analysis/nys_deployment_ws-YYYY-MM-DD-HH-MM-SS-analysis.md.*

```markdown
# Log Analysis: [Short Descriptive Title]

## TL;DR
**Issue**: [One sentence summary of the problem]
**Root Cause**: [One sentence summary of why it happened]
**Fix**: [One sentence summary of the recommended solution]

## Problem Summary

[Brief description of what went wrong, observed symptoms, and impact]
- Symptom 1
- Symptom 2

## Root Cause Analysis

### Timeline of Events

1. **[HH:MM:SS]** - [Event Description] (UUID: `...`)
2. **[HH:MM:SS]** - [Event Description]
   - Detail A
   - Detail B
### Key Findings

[Describe the core discovery that explains the issue]

```
[Insert relevant log snippet proving the finding]
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
- **Log message**: `"Unique log message identifying the issue"`

### Resolution/Workaround observed
[How was the system recovered? e.g. Restart, specific command, manual intervention]

## Recommendations

1. **[Action Item 1]**: [Description of fix/improvement]
2. **[Action Item 2]**: [Description of fix/improvement]

## Fix with AI
*Use this prompt to instruct the next agent to implement the fix:*

```text
The analysis of the logs revealed a critical issue in [Subsystem Name].
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

### [Evidence Category 1]
[List specific UUIDs, IDs, or key values]

### [Evidence Category 2]
```
[Paste supporting log snippets here]
```
```
