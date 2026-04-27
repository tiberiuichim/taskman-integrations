#!/bin/bash
# Shared helper: run an agent command, capture stdout to a temp file,
# show an animated spinner while waiting, then render the captured
# markdown through glow for a clean formatted result.
#
# Usage:
#   run_agent_with_spinner "Agent is analyzing X..." "<agent_command>"
#
# The agent command's stdout is captured to a temp file (for glow).
# stderr goes to the terminal (so the spinner is visible).

run_agent_with_spinner() {
    local spinner_text="$1"
    shift

    local tmpfile
    tmpfile=$(mktemp /tmp/taskman-agent-output.XXXXXX.md)

    # Save original stdout
    exec 3>&1

    # Start spinner in background, writes to original stdout (terminal)
    (
        local i=0
        local spinchars=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
        while kill -0 $! 2>/dev/null; do
            printf "\r  %s %s" "$spinner_text" "${spinchars[$i]}"
            i=$(( (i + 1) % 10 ))
            sleep 0.1
        done
        printf "\r  \033[K" 2>/dev/null  # clear spinner line
    ) &
    local spid=$!

    # Run agent: stdout -> temp file, stderr -> terminal (fd 3)
    "$@" > "$tmpfile" 2>&3
    local exit_code=$?

    # Kill spinner if still running
    kill $spid 2>/dev/null
    wait $spid 2>/dev/null

    exec 3>&-

    if [ $exit_code -ne 0 ]; then
        echo "  ❌ Agent exited with code $exit_code" >&2
        cat "$tmpfile" >&2
        rm -f "$tmpfile"
        return $exit_code
    fi

    # Render the captured markdown through glow
    glow "$tmpfile"

    rm -f "$tmpfile"
}
