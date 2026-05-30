#!/bin/bash
OLLAMA_HOST=0.0.0.0 ollama serve > ~/ollama.log 2>&1 &
sleep 5

# Download extra scripts

curl -fsSL https://raw.githubusercontent.com/bobhope9848/ollama_kickstart/refs/heads/master/download_models.sh -o ~/download_models.sh
chmod +x ~/download_models.sh
bash ~/download_models.sh
