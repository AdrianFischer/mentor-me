#!/usr/bin/osascript

-- Get the directory of this script
set projectPath to POSIX path of ((path to me as text) & "::")

tell application "Terminal"
    -- Window 1: Flutter App (Self-cleaning)
    activate
    do script "cd " & quoted form of projectPath & " && ./app/start_app.sh"
    
    -- Window 2: Intelligent Agent (Self-cleaning)
    delay 5
    do script "cd " & quoted form of projectPath & " && ./agent/start_agent.sh"
end tell
