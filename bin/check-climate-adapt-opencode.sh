#!/bin/bash

# Ensure we run from the project root
cd "$(dirname "$0")/.." || exit 1

# Load Redmine credentials from .env
source .opencode/.env

source bin/_check-common.sh

PROMPT_FILE="prompts/climate_adapt_check.txt"

if [ ! -f "$PROMPT_FILE" ]; then
	echo "Error: Prompt file $PROMPT_FILE not found."
	exit 1
fi

PROMPT=$(cat "$PROMPT_FILE")

# Call OpenCode with the prompt, auto-approve permissions.
# Output is captured to a temp file and rendered via glow at the end.
# Spinner shows progress while opencode processes.
run_agent_with_spinner "OpenCode is analyzing Climate-ADAPT issues..." \
    opencode run "$PROMPT" --dangerously-skip-permissions
