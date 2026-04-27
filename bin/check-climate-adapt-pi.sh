#!/bin/bash

# Ensure we run from the project root
cd "$(dirname "$0")/.." || exit 1

# Load Redmine credentials from .env
source .opencode/.env

PROMPT_FILE="prompts/climate_adapt_check.txt"

if [ ! -f "$PROMPT_FILE" ]; then
	echo "Error: Prompt file $PROMPT_FILE not found."
	exit 1
fi

PROMPT=$(cat "$PROMPT_FILE")

# Call pi with the prompt, loading the Redmine tools extension,
# in print mode (-p) for non-interactive execution.
# No glow: pi -p streams output live; glow would block until completion.
pi -p --extension ./pi/pi-redmine-tools.ts "$PROMPT"
