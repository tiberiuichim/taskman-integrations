#!/bin/bash

# Ensure we run from the project root
cd "$(dirname "$0")/.." || exit 1

PROMPT_FILE="prompts/genai_ai_hub_check.txt"

if [ ! -f "$PROMPT_FILE" ]; then
        echo "Error: Prompt file $PROMPT_FILE not found."
        exit 1
fi

PROMPT=$(cat "$PROMPT_FILE")

# Call the gemini CLI with the prompt and pipe to glow for visual formatting
gemini -p "$PROMPT" --skip-trust --approval-mode=yolo | glow
