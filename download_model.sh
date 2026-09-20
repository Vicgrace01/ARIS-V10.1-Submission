#!/usr/bin/env bash
set -euo pipefail
mkdir -p model
curl -L -o model/ARIS-V10.1-1.5B-Q4_K_M.gguf \
  https://huggingface.co/Vicgrace/ARIS-V10.1/resolve/main/ARIS-V10.1-1.5B-Q4_K_M.gguf
echo "Downloaded model/ARIS-V10.1-1.5B-Q4_K_M.gguf"
