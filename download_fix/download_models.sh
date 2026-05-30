#!/usr/bin/env bash
# ollama_merge.sh
# Pulls official Ollama model + matching HuggingFace GGUF, merges into a combined local model.
#
# Usage:
#   ./ollama_merge.sh <ollama_model> <hf_gguf_model> <output_model_name>
#
# Example (replicating the original commands):
#   ./ollama_merge.sh \
#     "gpt-oss:20b" \
#     "hf.co/mradermacher/gpt-oss-20b-heretic-GGUF:MXFP4_MOE" \
#     "mradermacher/gpt-oss:20b-heretic"
#
# What it does:
#   1. Pulls the base Ollama model.
#   2. Pulls the HuggingFace GGUF variant via Ollama's hf.co resolver.
#   3. Extracts the base model's Modelfile, strips the FROM line.
#   4. Appends the HF model's FROM line (pointing to the GGUF weights).
#   5. Creates a new local Ollama model from the merged Modelfile.
#   6. Cleans up the temporary Modelfile.

set -euo pipefail

# ── Argument validation ───────────────────────────────────────────────────────
if [[ $# -ne 3 ]]; then
    echo "Usage: $0 <ollama_model> <hf_gguf_model> <output_model_name>" >&2
    echo ""
    echo "  ollama_model     : base model tag in Ollama registry  (e.g. gpt-oss:20b)"
    echo "  hf_gguf_model    : HuggingFace GGUF ref via hf.co     (e.g. hf.co/mradermacher/gpt-oss-20b-heretic-GGUF:MXFP4_MOE)"
    echo "  output_model_name: name for the merged local model    (e.g. mradermacher/gpt-oss:20b-heretic)"
    exit 1
fi

OLLAMA_MODEL="$1"
HF_GGUF_MODEL="$2"
OUTPUT_MODEL="$3"

MODELFILE="$(mktemp /tmp/Modelfile.XXXXXX)"
trap 'rm -f "$MODELFILE"' EXIT

# ── Dependency check ──────────────────────────────────────────────────────────
if ! command -v ollama &>/dev/null; then
    echo "Error: ollama is not installed or not in PATH." >&2
    exit 1
fi

# ── Step 1: Pull base Ollama model ────────────────────────────────────────────
echo "==> Pulling base Ollama model: ${OLLAMA_MODEL}"
ollama pull "${OLLAMA_MODEL}"

# ── Step 2: Pull HuggingFace GGUF model ───────────────────────────────────────
echo "==> Pulling HuggingFace GGUF model: ${HF_GGUF_MODEL}"
ollama pull "${HF_GGUF_MODEL}"

# ── Step 3: Extract Modelfile from base, strip FROM line ─────────────────────
echo "==> Extracting Modelfile from: ${OLLAMA_MODEL}"
ollama show --modelfile "${OLLAMA_MODEL}" | grep -v "^FROM" > "${MODELFILE}"

# ── Step 4: Append FROM line from the HF GGUF model ──────────────────────────
echo "==> Appending FROM line from: ${HF_GGUF_MODEL}"
ollama show --modelfile "${HF_GGUF_MODEL}" | grep "^FROM" >> "${MODELFILE}"

# ── Sanity check: ensure FROM line was captured ───────────────────────────────
if ! grep -q "^FROM" "${MODELFILE}"; then
    echo "Error: No FROM line found in ${HF_GGUF_MODEL}'s Modelfile. Aborting." >&2
    exit 1
fi

echo "==> Merged Modelfile contents:"
echo "────────────────────────────────────────"
cat "${MODELFILE}"
echo "────────────────────────────────────────"

# ── Step 5: Create the merged local model ────────────────────────────────────
echo "==> Creating merged local model: ${OUTPUT_MODEL}"
ollama create "${OUTPUT_MODEL}" -f "${MODELFILE}"

echo ""
echo "Done. Model available as: ${OUTPUT_MODEL}"
echo "Run with: ollama run ${OUTPUT_MODEL}"
