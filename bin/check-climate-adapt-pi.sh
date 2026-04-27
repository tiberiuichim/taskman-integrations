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

# Call pi with the prompt, loading the Redmine tools extension,
# in print mode (-p) for non-interactive execution.
# Output is captured to a temp file and rendered via glow at the end.
# Spinner shows progress while pi processes.
run_agent_with_spinner "Pi is analyzing Climate-ADAPT issues..." \
    pi -p --extension ./pi/pi-redmine-tools.ts "$PROMPT"
