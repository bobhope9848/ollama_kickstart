#!/bin/bash
set -euo pipefail

# ── Load env vars from container environment ──────────────────────────────────
export OLLAMA_MODEL="$(tr '\0' '\n' < /proc/1/environ | grep -a '^OLLAMA_MODEL=' | cut -d= -f2-)"
export HF_TOKEN="$(tr '\0' '\n' < /proc/1/environ | grep -a '^HF_TOKEN=' | cut -d= -f2-)"


# ── Validate ──────────────────────────────────────────────────────────────────
if [[ -z "$OLLAMA_MODEL" || -z "$HF_TOKEN" ]]; then
    echo "ERROR: One or more required env vars are missing." >&2
    echo "Container environment:" >&2
    tr '\0' '\n' < /proc/1/environ >&2
    exit 1
fi

echo "OLLAMA_MODEL=${OLLAMA_MODEL}"
echo "HF_TOKEN=${HF_TOKEN}"

# ── Start ollama ──────────────────────────────────────────────────────────────
OLLAMA_HOST=0.0.0.0 ollama serve > ~/ollama.log 2>&1 &

echo "==> Waiting for ollama to be ready..."
until curl -sf http://localhost:11434/api/tags > /dev/null 2>&1; do
    sleep 2
done
echo "==> ollama ready."

# Install hf-cli

pip install -U "huggingface_hub[cli]"

pip install hf_transfer

hf auth login --token "${$HF_TOKEN}" --add-to-git-credential

export HF_HUB_ENABLE_HF_TRANSFER=1

# ── Download and run ──────────────────────────────────────────────────────────

ollama pull "${OLLAMA_MODEL}"
