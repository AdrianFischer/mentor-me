# analyze-jira-ticket

Analyze a Jira ticket (especially test failure tickets), download and analyze logs, then generate and post an analysis comment to the ticket.

## 1. Get Jira Ticket Information
Ask the user for the Jira ticket URL or ticket key (e.g., "NOYPB-9965" or full URL).

**Example input:**
- `https://noyes-tech.atlassian.net/browse/NOYPB-9965`
- `NOYPB-9965`

## 2. Fetch Ticket Details
Use the Jira client to fetch the ticket information:

```python
from jira import JIRA
import os
import re

# Extract ticket key from URL if needed
ticket_url_or_key = "<user_input>"
ticket_key = ticket_url_or_key.split('/')[-1].split('?')[0] if '/' in ticket_url_or_key else ticket_url_or_key

# Initialize Jira client (use credentials from nys_test/helpers/jira_fixtures.py)
jira_client = JIRA(
    server='https://noyes-tech.atlassian.net', 
    basic_auth=('ben@noyes-tech.com', 'ATATT3xFfGF03USBYBSN7Z6SjxIAejdQ7iDeYoS48IQMN9imKotuJxat-gBvi7A6msRb2qQRhQ-dReq1pwgKTChidTnjcx1ZZHWIJNh61JvadEJiqoLPIJS1uxUQf7F-EUBM2qlC1wcJP28qZyKDg-KvbysulrvfAJooTYFt-XZoRjRHMzOO1lM=2C747A7F'),
    options={'rest_api_version': '3'}
)

issue = jira_client.issue(ticket_key)

# Check if it's a test failure ticket
is_test_failure = (
    issue.fields.issuetype.name == 'Test' and 
    'NYS_TEST_FAILED' in issue.fields.labels
)
```

## 3. Download Log Files
If it's a test failure ticket, download log attachments from Jira:

```python
import os

os.makedirs('container_logs', exist_ok=True)

# Download the main body logs file (fluentd_body_logs)
for attachment in issue.fields.attachment:
    if 'fluentd_body_logs' in attachment.filename or attachment.filename.endswith('.log'):
        print(f'Downloading {attachment.filename}...')
        with open(f'container_logs/{attachment.filename}', 'wb') as f:
            f.write(attachment.get())
        print(f'Downloaded to container_logs/{attachment.filename}')
        break
```

## 4. Analyze the Logs
Use the `/analyze-logs` command methodology to analyze the downloaded logs:

1. **Extract failure information from ticket:**
   - Read the ticket description/table to get failure reason
   - Extract test name, error message, and any relevant context

2. **Perform log analysis:**
   - Search for tracebacks
   - Check for stuck jobs
   - Analyze path planning failures
   - Check elevator state
   - Look for deadlocks
   - Review bot coordinator status
   - Follow the analysis steps from `/analyze-logs` command

3. **Identify root cause:**
   - Determine if it's a timeout issue, deadlock, path planning failure, etc.
   - Summarize findings

## 5. Generate Analysis Comment
Create a structured comment with:

- **Author attribution** (get from git config):
```python
import subprocess
git_name = subprocess.check_output(['git', 'config', 'user.name']).decode('utf-8').strip()
git_email = subprocess.check_output(['git', 'config', 'user.email']).decode('utf-8').strip()
```

- **Problem Description** (3-5 lines)
- **Analysis** (1-5 lines)  
- **Proposed Strategy** (1-100 lines with room for double-checking)

Format the comment in ADF (Atlassian Document Format) for Jira API v3.

## 6. Show Comment to User
Display the generated comment to the user and ask for confirmation:

```
Generated analysis comment:
---
[Show the formatted comment here]
---

Do you want to post this comment to the Jira ticket? (yes/no)
```

## 7. Post Comment to Jira
If user confirms, post the comment:

```python
comment_body = {
    'type': 'doc',
    'version': 1,
    'content': [
        {
            'type': 'paragraph',
            'content': [
                {'type': 'text', 'marks': [{'type': 'strong'}], 'text': f'Analysis by: {git_name}'},
                {'type': 'text', 'text': f' ({git_email})'}
            ]
        },
        {
            'type': 'rule'
        },
        # ... rest of analysis content in ADF format
    ]
}

jira_client.add_comment(issue.key, comment_body)
print(f'Successfully posted comment to {issue.key}')
```

## 8. Non-Test Failure Tickets
If the ticket is not a test failure ticket:
- Still fetch ticket details
- Analyze the description and any attachments
- Generate appropriate analysis based on ticket type
- Follow steps 5-7 to create and post comment

## Notes
- Always get the user's git name and email for attribution
- Use ADF format for Jira comments (API v3)
- Reference the `/analyze-logs` command for detailed log analysis steps
- Be thorough but concise in the analysis
- Include actionable fix strategies when possible

--- End Command ---

