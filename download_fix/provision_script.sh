#!/bin/bash
set -euo pipefail

# ── Load env vars from container environment ──────────────────────────────────
OLLAMA_MODEL="$(tr '\0' '\n' < /proc/1/environ | grep -a '^OLLAMA_MODEL=' | cut -d= -f2-)"
HF_GGUF_MODEL="$(tr '\0' '\n' < /proc/1/environ | grep -a '^HF_GGUF_MODEL=' | cut -d= -f2-)"
OUTPUT_MODEL="$(tr '\0' '\n' < /proc/1/environ | grep -a '^OUTPUT_MODEL=' | cut -d= -f2-)"

# ── Validate ──────────────────────────────────────────────────────────────────
if [[ -z "$OLLAMA_MODEL" || -z "$HF_GGUF_MODEL" || -z "$OUTPUT_MODEL" ]]; then
    echo "ERROR: One or more required env vars are missing." >&2
    echo "Container environment:" >&2
    tr '\0' '\n' < /proc/1/environ >&2
    exit 1
fi

echo "OLLAMA_MODEL=${OLLAMA_MODEL}"
echo "HF_GGUF_MODEL=${HF_GGUF_MODEL}"
echo "OUTPUT_MODEL=${OUTPUT_MODEL}"

# ── Start ollama ──────────────────────────────────────────────────────────────
OLLAMA_HOST=0.0.0.0 ollama serve > ~/ollama.log 2>&1 &

echo "==> Waiting for ollama to be ready..."
until curl -sf http://localhost:11434/api/tags > /dev/null 2>&1; do
    sleep 2
done
echo "==> ollama ready."

# ── Download and run ──────────────────────────────────────────────────────────
curl -fsSL https://raw.githubusercontent.com/bobhope9848/ollama_kickstart/refs/heads/master/download_models.sh \
    -o ~/download_models.sh
chmod +x ~/download_models.sh
bash ~/download_models.sh "${OLLAMA_MODEL}" "${HF_GGUF_MODEL}" "${OUTPUT_MODEL}"
