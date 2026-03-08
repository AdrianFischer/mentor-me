# Autonomous Routines & Cron Architecture Research

## 1. Overview
The goal is to transition the Assisted Intelligence agent from a purely reactive chatbot into a **proactive, autonomous worker**. By implementing a continuous watchdog, the system will execute pre-defined routines at specific intervals. When a routine triggers, it spins up a detached Gemini session with full terminal access to work independently, logs its actions/token usage, and notifies the user via Telegram only if meaningful work was accomplished.

## 2. Sequence Diagram
This sequence diagram is mapped directly from your whiteboard flowchart (`IMG_2814.jpg`).

```mermaid
sequenceDiagram
    participant W as Watchdog (Timer)
    participant FS as Routine Filesystem
    participant G as Gemini Subprocess
    participant T as OS Terminal / Tools
    participant L as Telemetry Logger
    participant B as Telegram Bot

    loop Every 1 Second
        W->>FS: get_files() (Read routines)
        FS-->>W: List of routines & last_execution_times
        
        W->>W: if current_time < last_execution_time + execute_every_seconds: continue
        
        opt Routine is Due
            W->>G: start_gemini_terminal_session(context, task)
            W->>W: session_start_time = time.time()
            
            loop while True
                W->>W: if time.time() > session_start_time + timeout: break
                
                G->>G: continue() (Thinking/Processing)
                
                opt If Tool Call Required
                    G->>T: call_tool() (e.g., Terminal Command)
                    T-->>G: tool_result
                end
                
                opt If Gemini is Done
                    G-->>W: done() == true
                    break
                end
            end
            
            W->>G: get_response()
            G-->>W: final_summary & token_usage
            
            W->>L: update_history() & write to token logs
            
            opt If Meaningful Work Done
                W->>B: text_user("Routine [Name] completed. Here is what I did: ...")
            end
        end
    end
```

## 3. Architectural Components

### A. The Watchdog (Node.js)
A lightweight background loop running via `setInterval` every 1000ms.
- **State Management:** It reads `routines/` directory. To avoid high I/O, `last_execution_time` for each routine should be kept in memory or in a lightweight `routines_state.json` file rather than modifying the core routine files.

### B. Routine Definitions (Markdown/YAML)
Routines should be defined in a dedicated folder (e.g., `data/routines/`).
Example `daily_cleanup.yaml`:
```yaml
name: "Daily Codebase Cleanup"
execute_every_seconds: 86400 # 24 hours
timeout: 600 # 10 minutes max
context: "You are a senior developer. The project root is /Users/adi/dev/AssistedIntelligence."
task: "Run `git status`. If there are untracked log files or temporary assets older than 24h, delete them. If tests fail, report them. Do NOT commit code."
```

### C. Execution Engine: Gemini CLI Detached Mode
Since the routines require "full access to the terminal" and independent work, utilizing the **Gemini CLI** natively is the strongest approach.
- **Spawning:** The Node.js watchdog uses `child_process.spawn()` to invoke the Gemini CLI headlessly.
- **Command:** `gemini -m "<task>" --context="<context>"`
- **Why it's good:** The Gemini CLI already has deep OS integrations, terminal capabilities (`run_shell_command`), and search tools. 

### D. Token Logging & Telemetry
To satisfy the requirement of logging *every token used*:
- Every routine execution will output a specific log file: `logs/routines/{routine_name}_{timestamp}.log`.
- This log will capture standard output (`stdout`), standard error (`stderr`), and extract the **Token Usage Metadata** provided by the Gemini API upon session closure.

### E. Telegram "Meaningful Work" Filter
We do not want the bot spamming you if a routine runs every hour and finds nothing to do.
- **The Filter Prompt:** The final instruction to the detached session is: *"If you actually changed files, deleted things, or found critical errors, output a SUMMARY. If you did nothing or found nothing, output exactly 'NO_ACTION_TAKEN'."*
- If the output is not `NO_ACTION_TAKEN`, the Watchdog passes the summary to the `BotService` to text you.

## 5. Acceptance Criteria (AC)

### AC 1: Watchdog Trigger Logic
- The watchdog MUST tick every 1000ms.
- A routine MUST ONLY execute if `current_time >= last_execution_time + execute_every_seconds`.
- Adding a new routine file to the `data/routines/` folder MUST be detected automatically within 1 tick (proactive discovery).

### AC 2: Detached Independent Execution
- Each routine MUST run in its own independent subprocess (e.g., Gemini CLI).
- A routine MUST have access to the full terminal environment and tools (file-first, shell commands).
- The watchdog MUST NOT block; multiple routines with overlapping schedules should run in parallel if necessary.

### AC 3: Timeout Enforcement
- If a routine exceeds its defined `timeout` (seconds), the watchdog MUST forcibly terminate the subprocess (SIGKILL).
- Terminated routines MUST log a `TIMEOUT_ERROR` and notify the user via Telegram that the process hung.

### AC 4: Telemetry & Token Logging
- Every routine execution MUST generate a log file in `logs/routines/{name}_{timestamp}.log`.
- Log files MUST contain the full `stdout` and `stderr` of the Gemini session.
- The **total token count** (input + output) MUST be extracted from the session metadata and written to a machine-readable `telemetry.json` for long-term tracking.

### AC 5: Telegram "Meaningful Work" Filter
- The watchdog MUST NOT send a Telegram message if the routine outputs the specific string `NO_ACTION_TAKEN`.
- Any other non-empty output MUST be treated as "meaningful work" and forwarded to the user's primary Telegram ID.

### AC 6: Error Resilience
- A crash or error in one routine MUST NOT stop the watchdog loop or affect other pending routines.
- All errors (syntax, tool failures, network) MUST be captured in the specific routine's log file.

## 6. Testing Strategy

### Phase 1: Unit Tests (Watchdog logic)
- **Tool:** Vitest
- **Scope:** Test the `Watchdog` class logic using mocked timers (`vi.useFakeTimers`).
- **Target:** Verify that routines are triggered at exact intervals and that `last_execution_time` is updated correctly.

### Phase 2: Integration Tests (Execution & Timeout)
- **Tool:** Vitest + Node.js `child_process`
- **Scope:** Create a "Dummy Routine" (a shell script that sleeps for 10s).
- **Target:** Verify that the watchdog successfully kills the "Dummy Routine" if the timeout is set to 5s.

### Phase 3: Telemetry Verification
- **Tool:** Manual script + `cat`
- **Scope:** Run a real Gemini CLI session via the watchdog.
- **Target:** Ensure the token metadata is correctly parsed and saved to the filesystem.

### Phase 4: E2E (Full Workflow)
- **Tool:** Manual Verification
- **Scope:** Place a `data/routines/test_routine.yaml` that simply lists files.
- **Target:** Confirm a Telegram message is received with the file list, and a log file exists with token counts.

## 7. Implementation Steps (Revised)
... (previous steps follow)
