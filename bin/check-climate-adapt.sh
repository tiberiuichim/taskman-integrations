#!/bin/bash

# Ensure we run from the project root
cd "$(dirname "$0")/.." || exit 1

source bin/_check-common.sh

PROMPT_FILE="prompts/climate_adapt_check.txt"

if [ ! -f "$PROMPT_FILE" ]; then
        echo "Error: Prompt file $PROMPT_FILE not found."
        exit 1
fi

PROMPT=$(cat "$PROMPT_FILE")

# Call the gemini CLI with the prompt.
# Output is captured to a temp file and rendered via glow at the end.
# Spinner shows progress while gemini processes.
run_agent_with_spinner "Gemini is analyzing Climate-ADAPT issues..." \
    gemini -p "$PROMPT" --skip-trust --approval-mode=yolo
