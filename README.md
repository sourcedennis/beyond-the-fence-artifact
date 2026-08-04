# "Beyond the Fence" Artifact

Artifact for our ASPLOS'27 paper "Beyond the Fence: Sound Compilation for GPU and Heterogeneous CPU+GPU Systems".

## Commands

Build the Docker image with:

```
docker build . --tag=beyond-the-fence
```

## Agda Proofs

The sources for the Agda proofs are included in [sourcedennis/ptx-proofs](https://github.com/sourcedennis/ptx-proofs), which the `Dockerfile` downloads together with its dependencies on the [Burrow](https://github.com/sourcedennis/agda-burrow) proof library.

Run the Agda proofs with:

```
docker run -it --rm beyond-the-fence agda src/Main.agda
```

## Alloy Litmus Tests

## CUDA Litmus Tests

The CUDA hardware artifact is in [`hw/`](hw/). It contains the CUDA litmus-test runners, official raw logs, and comparison scripts for the hardware experimental evaluation.

These commands should be run on a CUDA-enabled NVIDIA machine. For artifact evaluation, reviewers will be given access to the GB10 machine used for the official results. On such a machine, check the environment and run the small smoke test with:

```
cd hw
./scripts/check_env.sh
./scripts/run_smoke.sh --machine gb10 --iterations 10
```

For a broader subset of tests and comparison against the official GB10 observations:

```
./scripts/run_key_results.sh --machine gb10 --iterations 100
./scripts/compare_results.sh \
  --log output/gb10-key.txt \
  --official-machine gb10 \
  --output-csv output/gb10-key-comparison.csv
```

The full hardware instructions, including how to interpret results, are in [`hw/README.md`](hw/README.md).

## License

BSD-3 -- See `LICENSE`
