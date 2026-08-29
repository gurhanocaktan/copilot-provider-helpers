# Copilot CLI Provider Helpers

Small shell helpers to switch the GitHub Copilot CLI between providers (local Ollama, NVIDIA NIM, custom OpenAI-compatible endpoints) and persist the choice per-shell.

This repo contains a single helper script intended to live in `~/.bashrc.d/` and loaded from `~/.bashrc`.

Files
Files
- `copilot-providers.sh` — bash helper (place it in `~/.bashrc.d/`). The script is intended to be sourced from your `~/.bashrc`; it does not need to be executable to work, but you may make it executable for convenience.

Quick install
```bash
# copy the script into place
mkdir -p ~/.bashrc.d
cp copilot-providers.sh ~/.bashrc.d/copilot-providers.sh
chmod +x ~/.bashrc.d/copilot-providers.sh
# ensure your ~/.bashrc sources ~/.bashrc.d/* (most distros do)
source ~/.bashrc
```

Usage
- `use-ollama [model]` — query local Ollama for available models (interactive menu) or set a model by name.
- `use-nvidia [model]` — choose from a short NVIDIA model list (interactive) or pass a model name.
- `use-provider <provider_type> <base_url> <api_key> <model>` — set a generic OpenAI-compatible provider.
- `list-ollama-models` — prints available Ollama models (uses Ollama HTTP API).
- `copilot-status` — show current provider/model.
- `copilot-switch` — interactive provider chooser.
 - `use-github` — revert to GitHub-hosted Copilot (remove local BYOK config for current shell).

How it works
- The script persists the chosen provider into `~/.copilot-provider-config` and `source`s it so the `COPILOT_*` env vars apply immediately. The config file is written atomically and is set to restricted permissions (`600`) to avoid accidental exposure of API keys.
- When switching providers, the script will preserve an existing `COPILOT_PROVIDER_API_KEY` if present; otherwise it will write a placeholder (`<YOUR_NV_API_KEY>`) so you can replace it with a real key.
- For Ollama, `use-ollama` queries the local Ollama API (`http://localhost:11434/api/tags`) to discover model names.
- For NVIDIA, the script uses a curated list and lets you choose or enter a model manually.

Demo commands
```bash
source ~/.bashrc
use-ollama            # interactive Ollama model menu
use-ollama qwen2.5-coder
list-ollama-models
use-nvidia            # choose NVIDIA model
copilot-status
cat ~/.copilot-provider-config
```

Reverting to GitHub-hosted Copilot (default)

If you want to stop using a local or external BYOK provider and return to the default GitHub-hosted Copilot behavior, remove the local config and unset the environment variables. For example:

```bash
# remove persisted BYOK config
rm -f ~/.copilot-provider-config

# unset variables in the current shell (or open a fresh shell)
unset COPILOT_PROVIDER_BASE_URL COPILOT_PROVIDER_API_KEY COPILOT_MODEL COPILOT_PROVIDER_TYPE

# restart Copilot CLI
copilot
```

Alternatively, use the included helper:

```bash
copilot-switch    # then choose "GitHub Default"
```

License
- MIT