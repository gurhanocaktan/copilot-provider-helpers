#!/usr/bin/env bash

# copilot-providers (SANITIZED)
# Interactive helpers for switching Copilot CLI providers.
# IMPORTANT: Replace placeholder API keys with your own. Do NOT commit secrets.

COPILOT_CONFIG_FILE="$HOME/.copilot-provider-config"

# Known NVIDIA models (single source of truth)
NVIDIA_MODELS=(
    "meta/llama-3.3-70b-instruct"
    "meta/llama-3.2-3b-instruct"
    "meta/llama-3.2-1b-instruct"
    "meta/llama-3.1-79b-instruct"
    "meta/llama-3.1-8b-instruct"
    "qwen/qwen3-coder-480b-a35b-instruct"
)
# Initialize config with placeholders if it doesn't exist
if [[ ! -f "$COPILOT_CONFIG_FILE" ]]; then
    cat > "$COPILOT_CONFIG_FILE" << 'EOFCONFIG'
export COPILOT_PROVIDER_TYPE=openai
export COPILOT_PROVIDER_BASE_URL=https://integrate.api.nvidia.com/v1
export COPILOT_PROVIDER_API_KEY=<YOUR_NV_API_KEY>
export COPILOT_MODEL=qwen/qwen3-coder-480b-a35b-instruct
EOFCONFIG
fi

# Load config on every shell start (when this file is sourced)
source "$COPILOT_CONFIG_FILE"

# Interactive Ollama Provider with model selection
use-ollama() {
    local model

    # Check if Ollama is running
    if ! curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
        echo "❌ Ollama is not running. Start Ollama first: ollama serve"
        return 1
    fi

    # If model argument provided, use it directly
    if [[ -n "$1" ]]; then
        model="$1"
    else
        # Get available models interactively with select
        echo "Available Ollama models:"
        local -a models
        mapfile -t models < <(curl -s http://localhost:11434/api/tags | jq -r '.models[].name')

        if [[ ${#models[@]} -eq 0 ]]; then
            echo "❌ No models found"
            return 1
        fi

        PS3="Select model (number): "
        select model in "${models[@]}" "Cancel"; do
            [[ "$model" == "Cancel" ]] && return 1
            [[ -n "$model" ]] && break
        done
    fi

    # Save to config file
    cat > "$COPILOT_CONFIG_FILE" << EOFCONFIG
export COPILOT_PROVIDER_TYPE=openai
export COPILOT_PROVIDER_BASE_URL=http://localhost:11434/v1
export COPILOT_PROVIDER_API_KEY=ollama
export COPILOT_MODEL=$model
EOFCONFIG

    # Load it immediately
    source "$COPILOT_CONFIG_FILE"
    echo "✅ Switched to Ollama (model: $model)"
}

# Interactive NVIDIA provider with model selection
use-nvidia() {
    local model

    # If model argument provided, use it directly
    if [[ -n "$1" ]]; then
        model="$1"
    else
        # Show NVIDIA models menu (use centralized list)
        echo "Available NVIDIA NIM Models:"
        local -a models=("${NVIDIA_MODELS[@]}")

        PS3="Select model (number): "
        select choice in "${models[@]}" "Other (manual entry)" "Cancel"; do
            if [[ "$choice" == "Cancel" ]]; then
                return 1
            elif [[ "$choice" == "Other (manual entry)" ]]; then
                read -p "Enter NVIDIA model name: " model
                [[ -z "$model" ]] && return 1
                break
            elif [[ -n "$choice" ]]; then
                model="$choice"
                break
            fi
        done
    fi

    # Save to config file (placeholder API key)
    cat > "$COPILOT_CONFIG_FILE" << EOFCONFIG
export COPILOT_PROVIDER_TYPE=openai
export COPILOT_PROVIDER_BASE_URL=https://integrate.api.nvidia.com/v1
export COPILOT_PROVIDER_API_KEY=<YOUR_NV_API_KEY>
export COPILOT_MODEL=$model
EOFCONFIG

    # Load it immediately
    source "$COPILOT_CONFIG_FILE"
    echo "✅ Switched to NVIDIA (model: $model)"
}

# List Ollama models
list-ollama-models() {
    if ! curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
        echo "❌ Ollama not running"
        return 1
    fi
    echo "Available Ollama Models:"
    curl -s http://localhost:11434/api/tags | jq -r '.models[] | "\(.name) - \(.details.parameter_size) (\(.details.quantization_level))"'
}

# Show current config
copilot-status() {
    echo "Current Copilot Config:"
    echo "  Model:    ${COPILOT_MODEL:-not set}"
    echo "  Endpoint: ${COPILOT_PROVIDER_BASE_URL:-not set}"
}

# Show available NVIDIA models
nvidia-models() {
    echo "Available NVIDIA NIM Models:"
    for i in "${!NVIDIA_MODELS[@]}"; do
        idx=$((i+1))
        printf "  %d) %s\n" "$idx" "${NVIDIA_MODELS[i]}"
    done
    echo ""
    echo "Usage: use-nvidia <model_name>"
    echo "Example: use-nvidia ${NVIDIA_MODELS[0]}"
}

# Quick provider switcher
copilot-switch() {
    echo "Choose provider:"
    PS3="Select: "
    select choice in "Ollama" "NVIDIA" "Cancel"; do
        case $choice in
            Ollama) use-ollama; break ;;
            NVIDIA) use-nvidia; break ;;
            Cancel) break ;;
        esac
    done
}
