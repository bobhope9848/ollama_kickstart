#!/bin/bash
set -euo pipefail

# ── Load env vars from container environment ──────────────────────────────────
export LLAMA_MODEL="$(tr '\0' '\n' < /proc/1/environ | grep -a '^LLAMA_MODEL=' | cut -d= -f2-)"
export HF_TOKEN="$(tr '\0' '\n' < /proc/1/environ | grep -a '^HF_TOKEN=' | cut -d= -f2-)"


# ── Validate ──────────────────────────────────────────────────────────────────
if [[ -z "$LLAMA_MODEL" || -z "$HF_TOKEN" ]]; then
    echo "ERROR: One or more required env vars are missing." >&2
    echo "Container environment:" >&2
    tr '\0' '\n' < /proc/1/environ >&2
    exit 1
fi

echo "LLAMA_MODEL=${LLAMA_MODEL}"
echo "HF_TOKEN=${HF_TOKEN}"

# Install hf-cli

apt-get install pip

pip install -U "huggingface_hub[cli]" --break-system-packages

pip install hf-xet --break-system-packages

hf auth login --token "${HF_TOKEN}" --add-to-git-credential

export HF_XET_HIGH_PERFORMANCE=1

# ── Download and run ──────────────────────────────────────────────────────────

hf download bartowski/TheDrummer_Behemoth-X-123B-v2-GGUF --include "TheDrummer_Behemoth-X-123B-v2-Q8_0/*.gguf"
