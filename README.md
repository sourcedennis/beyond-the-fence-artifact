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
docker run -it --rm beyond-the-fence agda ptx-proofs/src/Main.agda
```

## Alloy Litmus Tests

To run the Alloy litmus tests you can just run 
```
docker run --rm \
  -v "$PWD/alloy:/home/proof/alloy" \
  -w /home/proof/alloy \
  beyond-the-fence \
  bash runlitmus.sh
```

This should take about 1-2 h, depending on your hardware. You can then inspect the output csv file:
```
less alloy/results.csv
```

## Combined Alloy/CUDA Results

After running the Alloy litmus tests, combine the Alloy model results with the bundled official GB10 hardware observations:

```
python3 tools/combine_results.py \
  --alloy-csv alloy/results.csv \
  --hw-source official \
  --official-machine gb10 \
  --output hw/output/combined-official-gb10.csv
```

The script writes a combined CSV and prints a mismatch summary. It exits nonzero only if hardware observed a weak behavior that Alloy reports as `UNSAT`. Alloy-allowed behaviors that are not observed in hardware are reported but do not fail, because weak hardware observations are probabilistic.

## CUDA Litmus Tests

The CUDA hardware artifact is in [`hw/`](hw/). It contains the CUDA litmus-test runners, official raw logs, and comparison scripts for the hardware experimental evaluation.

These commands should be run on a CUDA-enabled NVIDIA machine. For artifact evaluation, reviewers will be given access to the GB10 machine used for the official results. On such a machine, check the environment and run the small smoke test with:

```
cd hw
./scripts/check_env.sh
./scripts/run_smoke.sh --official-machine gb10 --test-environments 1 --iterations-per-test 100
```

For a broader subset of tests and comparison against the official GB10 observations:

```
./scripts/run_key_results.sh --test-environments 10 --iterations-per-test 1000
./scripts/compare_results.sh \
  --log output/key.txt \
  --official-machine gb10 \
  --output-csv output/key-comparison.csv
cd ..
python3 tools/combine_results.py \
  --alloy-csv alloy/results.csv \
  --hw-source hw/output/key.txt \
  --output hw/output/combined-reviewer-key.csv
```

The full hardware instructions, including how to interpret results, are in [`hw/README.md`](hw/README.md).

## License

BSD-3 -- See `LICENSE`
