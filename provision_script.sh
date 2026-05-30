#!/bin/bash


# Set envs

set -euo pipefail

# Pull env vars injected into the container by Vast at Docker level
# These exist in the container env but not in the SSH shell session

OLLAMA_MODEL="$(tr '\0' '\n' < /proc/1/environ | grep '^OLLAMA_MODEL=' | cut -d= -f2-)"
HF_GGUF_MODEL="$(tr '\0' '\n' < /proc/1/environ | grep '^HF_GGUF_MODEL=' | cut -d= -f2-)"
OUTPUT_MODEL="$(tr '\0' '\n' < /proc/1/environ | grep '^OUTPUT_MODEL=' | cut -d= -f2-)"

# Run ollama
OLLAMA_HOST=0.0.0.0 ollama serve > ~/ollama.log 2>&1 &

# Wait for ollama API to be ready
echo "==> Waiting for ollama to be ready..."
until curl -sf http://localhost:11434/api/tags > /dev/null 2>&1; do
    sleep 2
done
echo "==> ollama ready."

# Download extra scripts

curl -fsSL https://raw.githubusercontent.com/bobhope9848/ollama_kickstart/refs/heads/master/download_models.sh -o ~/download_models.sh
chmod +x ~/download_models.sh
bash ~/download_models.sh
