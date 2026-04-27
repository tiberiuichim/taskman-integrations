.DEFAULT_GOAL := help

.PHONY: help
help: ## Show this help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

.PHONY: check-climate-adapt
check-climate-adapt: ## Check Climate-ADAPT project for issues requiring immediate intervention
	@./bin/check-climate-adapt.sh

.PHONY: check-climate-adapt-opencode
check-climate-adapt-opencode: ## Check Climate-ADAPT project using OpenCode (opencode CLI)
	@./bin/check-climate-adapt-opencode.sh

.PHONY: check-climate-adapt-pi
check-climate-adapt-pi: ## Check Climate-ADAPT project using pi agent
	@./bin/check-climate-adapt-pi.sh

.PHONY: check-genai-ai-hub
check-genai-ai-hub: ## Check GenAI - AI Hub project for issues requiring immediate intervention
	@./bin/check-genai-ai-hub.sh

.PHONY: check-genai-ai-hub-opencode
check-genai-ai-hub-opencode: ## Check GenAI - AI Hub project using OpenCode (opencode CLI)
	@./bin/check-genai-ai-hub-opencode.sh

.PHONY: check-genai-ai-hub-pi
check-genai-ai-hub-pi: ## Check GenAI - AI Hub project using pi agent
	@./bin/check-genai-ai-hub-pi.sh
