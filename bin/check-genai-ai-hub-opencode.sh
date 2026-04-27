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

# Call OpenCode with the prompt, auto-approve permissions.
# No glow: opencode run buffers output internally, so piping to glow would
# double-buffer. We let the CLI's own formatting reach the terminal directly.
echo "⏳ OpenCode is analyzing GenAI - AI Hub issues..."
opencode run "$PROMPT" --dangerously-skip-permissions
echo
