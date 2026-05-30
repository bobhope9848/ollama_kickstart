#!/bin/bash
OLLAMA_HOST=0.0.0.0 ollama serve > /workspace/ollama.log 2>&1 &
sleep 5

# Download extra scripts

curl -fsSL https://github.com/bobhope9848/ollama_kickstart/blob/master/download_models.sh -o ~/download_models.sh
chmod +x ~/download_models.sh
bash ~/download_models.sh
