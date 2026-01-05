# test-and-fix

run the tests, read the output of failures and identify the root cause. 

the pattern of successes/failures as well as the log output from the test may be useful for narrowing down the root cause. Reference READMEs for context on the desired behavior of features. 

use in the test directory: `/monorepo/nys_test`
PYTHONUNBUFFERED=1 pytest -vv -s -o log_cli=true --log-cli-level=DEBUG --maxfail=1 2>&1 | tee pytest_debug.log

## Useful variants

- Last failed only (fastest iteration):

```bash
cd /monorepo/nys_test
PYTHONUNBUFFERED=1 pytest -vv -s -o log_cli=true --log-cli-level=DEBUG --lf 2>&1 | tee pytest_debug.last.log
```

- Filter by keyword or file, or a single test:

```bash
cd /monorepo/nys_test
# by keyword
PYTHONUNBUFFERED=1 pytest -vv -s -o log_cli=true --log-cli-level=DEBUG -k collapsed_include

# single file
PYTHONUNBUFFERED=1 pytest -vv -s -o log_cli=true --log-cli-level=DEBUG app_tests/test_storage_view.py

# single test
PYTHONUNBUFFERED=1 pytest -vv -s -o log_cli=true --log-cli-level=DEBUG app_tests/test_storage_view.py::test_name
```

- Filter by markers (skip release/slow tests during iteration):

```bash
cd /monorepo/nys_test
# Skip release tests (like CI does)
PYTHONUNBUFFERED=1 pytest -vv -s -o log_cli=true --log-cli-level=DEBUG -m "not release"
```

- Richer summary at the end:

```bash
cd /monorepo/nys_test
PYTHONUNBUFFERED=1 pytest -vv -s -o log_cli=true --log-cli-level=DEBUG -rA
```

## Logging tips

```bash
cd /monorepo/nys_test
PYTHONUNBUFFERED=1 pytest -vv -s -o log_cli=true --log-cli-level=DEBUG 2>&1 | tee "pytest_$(date +%H%M%S).log"
```

## Narrowing scope quickly

- Use `--maxfail=1` while iterating; remove it before pushing.
- Prefer `--lf` during fix cycles; switch back to full runs before commit.
- Use `-k` to filter by test name patterns: `-k "brain_restart"` (matches all `test_brain_restart_*` tests)
- Use `-m` to filter by markers: `-m "not release"`
- **Avoid running entire test folders** - each folder takes ~1 hour. Prefer single files or tests.

## Debugging tips

### Traceback options
Add to any command for better error context:
- `--tb=short` - concise traceback (recommended)
- `--tb=long` - full traceback with source context
- `--showlocals` - show local variable values in tracebacks

Example: `pytest ... --tb=short --showlocals`

### Fixture debugging
- Use `--setup-show` to see fixture execution order
- Use `--fixtures` to list all available fixtures

### Fluentd logs
All Docker container logs are automatically collected by Fluentd and combined into daily gzipped files at `~/nys_deployment_ws/logs/combined.YYYYMMDD.log.gz`. The `conftest.py` automatically extracts and attaches Fluentd logs relevant to each test phase (setup, body, teardown) based on epoch timestamps in brackets like `[1234567890.123]`.

**List available log files:**
```bash
ls -lh ~/nys_deployment_ws/logs/combined.*.log.gz
```

**View logs from today (or specific date):**
```bash
# Today's logs
zcat ~/nys_deployment_ws/logs/combined.$(date +%Y%m%d).log.gz | less

# Specific date (e.g., 2024-11-12)
zcat ~/nys_deployment_ws/logs/combined.20241112.log.gz | less
```

**Extract logs by epoch timestamp range (similar to conftest.py):**
```bash
# Convert your start/end times to epoch timestamps, then:
START_EPOCH=1700000000  # Replace with your start epoch
END_EPOCH=1700003600    # Replace with your end epoch
LOG_FILE=~/nys_deployment_ws/logs/combined.$(date -d @$START_EPOCH +%Y%m%d).log.gz

# Python script that mirrors conftest.py logic
python3 <<EOF
import gzip
import re
import sys

start_epoch = float("$START_EPOCH")
end_epoch = float("$END_EPOCH")
log_file = "$LOG_FILE"
epoch_re = re.compile(r'\[(\d{10}(?:\.\d+)?)\]')
writing = False

with gzip.open(log_file, 'rt', encoding='utf-8', errors='replace') as f:
    for line in f:
        m = epoch_re.search(line)
        if m:
            ts = float(m.group(1))
            if not writing and ts >= start_epoch:
                writing = True
            if writing and ts >= end_epoch:
                break
        if writing:
            print(line, end='')
EOF
```

**Search for specific patterns in logs:**
```bash
# Search today's logs for an error
zcat ~/nys_deployment_ws/logs/combined.$(date +%Y%m%d).log.gz | grep -i "store_orchstrator"

# Search with context (5 lines before/after)
zcat ~/nys_deployment_ws/logs/combined.$(date +%Y%m%d).log.gz | grep -i -C 5 "traceback"

# Search across all available log files
zcat ~/nys_deployment_ws/logs/combined.*.log.gz | grep -i "your_search_term"
```

**View recent logs (last N lines):**
```bash
# Last 100 lines from today
zcat ~/nys_deployment_ws/logs/combined.$(date +%Y%m%d).log.gz | tail -100

# Last 1000 lines with timestamps
zcat ~/nys_deployment_ws/logs/combined.$(date +%Y%m%d).log.gz | grep -E '\[[0-9]+\.[0-9]+\]' | tail -1000
```

**Note:** The `conftest.py` automatically extracts logs between test start/end timestamps and writes them to `/tmp/fluentd_<name>_<start>_<end>.log`. Check `/tmp/fluentd_*.log` for automatically extracted log files from recent test runs.

## Devcontainer notes

- pytest is installed system-wide (no venv needed) - use `pytest` directly
- pytest.ini is automatically found when running from `/monorepo/nys_test`
- All test paths in examples are relative to `/monorepo/nys_test`