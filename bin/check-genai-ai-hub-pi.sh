#!/bin/bash

# Ensure we run from the project root
cd "$(dirname "$0")/.." || exit 1

# Load Redmine credentials from .env
source .opencode/.env

PROMPT_FILE="prompts/genai_ai_hub_check.txt"

if [ ! -f "$PROMPT_FILE" ]; then
	echo "Error: Prompt file $PROMPT_FILE not found."
	exit 1
fi

PROMPT=$(cat "$PROMPT_FILE")

# Call pi with the prompt, loading the Redmine tools extension,
# in print mode (-p) for non-interactive execution, pipe to glow for formatting
pi -p --extension ./pi/pi-redmine-tools.ts "$PROMPT" | glow
