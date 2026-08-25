# Copilot CLI Provider Helpers

Small shell helpers to switch the GitHub Copilot CLI between providers (local Ollama, NVIDIA NIM, custom OpenAI-compatible endpoints) and persist the choice per-shell.

This repo contains a single helper script intended to live in `~/.bashrc.d/` and loaded from `~/.bashrc`.

Files
- `copilot-providers.sh` — bash helper (place it in `~/.bashrc.d/` and make executable).

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
- `use-provider <name> <base_url> <api_key> <model>` — set a generic OpenAI-compatible provider.
- `list-ollama-models` — prints available Ollama models (uses Ollama HTTP API).
- `copilot-status` — show current provider/model.
- `copilot-switch` — interactive provider chooser.

How it works
- The script persists the chosen provider into `~/.copilot-provider-config` and `source`s it so the `COPILOT_*` env vars apply immediately.
- For Ollama, `use-ollama` queries the local Ollama API (`http://localhost:11434/api/tags`) to discover model names.
- For NVIDIA, the script uses a curated list and lets you choose or enter a model manually.

Demo commands (good for video description)
```bash
source ~/.bashrc
use-ollama            # interactive Ollama model menu
use-ollama qwen2.5-coder
list-ollama-models
use-nvidia            # choose NVIDIA model
copilot-status
cat ~/.copilot-provider-config
```

Security
- Do NOT commit real API keys into public repos or share dotfiles with secrets. Replace keys with placeholders or use a secure secrets manager.

Tips for publishing
- Add this README to your GitHub repo and include the `copilot-providers` script at the repo root so viewers can `curl` or `git clone`.
- In your video description, paste the Quick install and Demo sections.

License
- MIT

---

If you want, I can also create a `README.md` in a new GitHub repo (or initialize a local Git repo and make a first commit). Which would you prefer?