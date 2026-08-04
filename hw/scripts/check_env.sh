#!/usr/bin/env bash
set -euo pipefail

echo "Python:"
python3 --version

echo
echo "CUDA compiler:"
if command -v nvcc >/dev/null 2>&1; then
  nvcc --version
elif [ -x /usr/local/cuda/bin/nvcc ]; then
  /usr/local/cuda/bin/nvcc --version
elif [ -x /usr/local/cuda-13.0/bin/nvcc ]; then
  /usr/local/cuda-13.0/bin/nvcc --version
elif [ -x /usr/local/cuda-13/bin/nvcc ]; then
  /usr/local/cuda-13/bin/nvcc --version
else
  echo "nvcc not found"
fi

echo
echo "NVIDIA GPU:"
if command -v nvidia-smi >/dev/null 2>&1; then
  nvidia-smi --query-gpu=name,compute_cap,driver_version --format=csv
else
  echo "nvidia-smi not found"
fi
