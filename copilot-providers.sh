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
_require_cmd() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "❌ Required command '$1' not found. Please install it."
        return 1
    fi
}

# Helper: write config atomically and securely, then source it
_write_config() {
    local provider_type="$1" base_url="$2" api_key="$3" model="$4"
    local tmp
    tmp=$(mktemp "${COPILOT_CONFIG_FILE}.XXXX") || return 1
    cat > "$tmp" <<EOF
export COPILOT_PROVIDER_TYPE='${provider_type}'
export COPILOT_PROVIDER_BASE_URL='${base_url}'
export COPILOT_PROVIDER_API_KEY='${api_key}'
export COPILOT_MODEL='${model}'
EOF
    chmod 600 "$tmp"
    mv -f "$tmp" "$COPILOT_CONFIG_FILE"
    # shellcheck disable=SC1090
    source "$COPILOT_CONFIG_FILE"
}

# Initialize config with placeholders if it doesn't exist
if [[ ! -f "$COPILOT_CONFIG_FILE" ]]; then
    _write_config openai https://integrate.api.nvidia.com/v1 "<YOUR_NV_API_KEY>" qwen/qwen3-coder-480b-a35b-instruct
fi

# Load config on every shell start (when this file is sourced)
if [[ -f "$COPILOT_CONFIG_FILE" ]]; then
    # shellcheck disable=SC1090
    source "$COPILOT_CONFIG_FILE"
fi

# Interactive Ollama Provider with model selection
use-ollama() {
    local model
    _require_cmd curl || return 1
    _require_cmd jq || return 1

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

    # Save to config file (use literal 'ollama' as API key marker)
    _write_config openai http://localhost:11434 'ollama' "$model"
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

    # Preserve an existing API key if set, otherwise leave placeholder
    local api_key
    api_key=${COPILOT_PROVIDER_API_KEY:-"<YOUR_NV_API_KEY>"}

    # Save to config file
    _write_config openai https://integrate.api.nvidia.com/v1 "$api_key" "$model"
    echo "✅ Switched to NVIDIA (model: $model)"
}

# Generic provider setter: use-provider <type> <base_url> <api_key> <model>
use-provider() {
    if [[ $# -lt 4 ]]; then
        echo "Usage: use-provider <provider_type> <base_url> <api_key> <model>"
        return 1
    fi
    local provider_type="$1" base_url="$2" api_key="$3" model="$4"
    _write_config "$provider_type" "$base_url" "$api_key" "$model"
    echo "✅ Switched to provider '$provider_type' (model: $model)"
}

# Revert to GitHub-hosted Copilot (remove BYOK config and unset env vars)
use-github() {
    if [[ -f "$COPILOT_CONFIG_FILE" ]]; then
        rm -f "$COPILOT_CONFIG_FILE" || true
    fi
    unset COPILOT_PROVIDER_TYPE COPILOT_PROVIDER_BASE_URL COPILOT_PROVIDER_API_KEY COPILOT_MODEL
    echo "✅ Reverted to GitHub-hosted Copilot (removed ~/.copilot-provider-config and unset COPILOT_* vars)."
}

# List Ollama models
list-ollama-models() {
    _require_cmd curl || return 1
    _require_cmd jq || return 1
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
    echo "  Provider: ${COPILOT_PROVIDER_TYPE:-github-default}"
    echo "  Model:    ${COPILOT_MODEL:-not set}"
    echo "  Endpoint: ${COPILOT_PROVIDER_BASE_URL:-not set}"
    if [[ -n "${COPILOT_PROVIDER_API_KEY:-}" ]]; then
        echo "  API Key:  set (hidden)"
    else
        echo "  API Key:  not set"
    fi
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
    select choice in "Ollama" "NVIDIA" "GitHub Default" "Cancel"; do
        case $choice in
            Ollama) use-ollama; break ;;
            NVIDIA) use-nvidia; break ;;
            "GitHub Default") use-github; break ;;
            Cancel) break ;;
        esac
    done
}
