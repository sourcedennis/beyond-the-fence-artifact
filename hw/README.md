# CUDA Litmus Test Artifact

This directory contains the CUDA litmus-test artifact for the paper's hardware experimental evaluation.

The scripts are intended to run on any CUDA-capable NVIDIA machine. For artifact evaluation, access will be given to the GB10 machine used for the official results.

## Requirements

- `python3`
- NVIDIA driver and CUDA runtime
- `nvcc`
- An NVIDIA GPU visible through `nvidia-smi`

Check the environment with:

```bash
./scripts/check_env.sh
```

## Smoke Test

Run a small build-and-run check:

```bash
./scripts/run_smoke.sh --machine gb10 --iterations 10
```

The script writes a log to `output/gb10-smoke.txt`.

What to look for:

- The CUDA kernels compile without `nvcc` errors.
- The protected Figure 2 test reports `weak: 0`.
- At least one relaxed or block-scoped test may report `weak` greater than zero. This is a useful sanity check, but short runs can miss weak behaviors.

## Key Results

Run a small paper-focused subset:

```bash
./scripts/run_key_results.sh --machine gb10 --iterations 100
```

The script writes a log to `output/gb10-key.txt`.

Compare that log against the archived official GB10 observations:

```bash
./scripts/compare_results.sh \
  --log output/gb10-key.txt \
  --official-machine gb10 \
  --output-csv output/gb10-key-comparison.csv
```

`--official-machine` must be one of `a100`, `h100`, `gh200`, or `gb10`.

What to look for:

- `Unexpected reviewer seen` should be `0`. A nonzero value means the run found a weak behavior where the official run did not.
- `Official seen but not seen in reviewer log` can be nonzero for short runs, because weak behaviors are probabilistic and some paper observations are rare.
- Increasing `--iterations` should usually reduce missed official `seen` rows, at the cost of longer runtime.

## Full Core Campaign

Run the full Table 1 hardware campaign:

```bash
./scripts/run_full_campaign.sh --machine gb10 --iterations 1000
```

The full campaign compiles and runs the CUDA variants described by `tuning-files/`, excluding helper variants that are not part of Table 1. Runtime depends heavily on the GPU and iteration count. The paper's official campaign ran A100, H100, and GB10 for 24 hours each, and GH200 for 6 hours.

## Expected Results

Archived official logs are in `expected/raw/`.

`expected/official-observations.csv` contains hardware observations only:

```text
test,suite,a100,h100,gh200,gb10
```

`suite=core` denotes the Table 1 hardware campaign.

Weak behavior observations are probabilistic. A short run may fail to rediscover rare official `seen` behaviors. The comparison script therefore distinguishes "official seen but not seen in reviewer log" from unexpected observations.
