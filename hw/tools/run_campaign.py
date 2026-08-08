#!/usr/bin/env python3
import argparse
import time

from litmus_lib import OUTPUT_DIR, compile_test, detect_arch, load_manifest, manifest_key, run_test, write_stress_params


SMOKE_TESTS = {
    ("paper-example1", "TB_0_1_2_3", "SCOPE_DEVICE", "FENCE_SCOPE_DEVICE", "DISALLOWED"),
    ("iriw", "TB_01_23", "SCOPE_DEVICE", "NO_FENCE", "RELAXED"),
    ("z6-3", "TB_0_1_2", "SCOPE_BLOCK", "NO_FENCE", "RELAXED"),
}


KEY_TESTS = {
    ("paper-example1", "TB_0_1_2_3", "SCOPE_DEVICE", "FENCE_SCOPE_DEVICE", "DISALLOWED"),
    ("paper-example2", "TB_0_1_2_3", "SCOPE_DEVICE", "FENCE_SCOPE_DEVICE", "DISALLOWED"),
    ("paper-example2", "TB_0_1_2_3", "SCOPE_DEVICE", "NO_FENCE", "RELAXED"),
    ("counterexample", "TB_012_3", "SCOPE_DEVICE", "NO_FENCE", "DEFAULT"),
    ("iriw", "TB_01_23", "SCOPE_DEVICE", "NO_FENCE", "ACQUIRE"),
    ("iriw", "TB_01_23", "SCOPE_DEVICE", "NO_FENCE", "RELAXED"),
    ("2+2w", "TB_0_1", "SCOPE_BLOCK", "NO_FENCE", "RELAXED"),
    ("3.2w", "TB_0_1_2", "SCOPE_BLOCK", "NO_FENCE", "RELAXED"),
    ("z6-3", "TB_0_1_2", "SCOPE_BLOCK", "NO_FENCE", "RELAXED"),
    ("rwc", "TB_0_1_2", "SCOPE_BLOCK", "NO_FENCE", "RELAXED"),
    ("wrc", "TB_0_1_2", "SCOPE_BLOCK", "NO_FENCE", "RELAXED"),
    ("wwc", "TB_0_1_2", "SCOPE_BLOCK", "NO_FENCE", "RELAXED"),
    ("wrw+2w", "TB_0_1_2", "SCOPE_BLOCK", "NO_FENCE", "RELAXED"),
    ("isa2", "TB_0_1_2", "SCOPE_BLOCK", "NO_FENCE", "RELAXED"),
}


def key(test):
    return manifest_key(test)


def select_tests(mode):
    tests = load_manifest("core")
    if mode == "smoke":
        selected = [test for test in tests if key(test) in SMOKE_TESTS]
    elif mode == "key":
        selected = [test for test in tests if key(test) in KEY_TESTS]
    elif mode == "full":
        selected = tests
    else:
        raise ValueError(mode)
    if not selected:
        raise SystemExit(f"no tests selected for mode {mode}")
    return selected


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--mode", choices=["smoke", "key", "full"], required=True)
    parser.add_argument("--official-machine", choices=["a100", "gb10", "gh200", "h100"], default=None)
    parser.add_argument("--test-environments", type=int, default=1)
    parser.add_argument("--iterations-per-test", type=int, default=100)
    parser.add_argument("--iterations", type=int, help="Deprecated alias for --iterations-per-test")
    parser.add_argument("--arch", default=None)
    parser.add_argument("--no-build", action="store_true")
    parser.add_argument("--build-only", action="store_true")
    args = parser.parse_args()

    iterations_per_test = args.iterations if args.iterations is not None else args.iterations_per_test
    if args.test_environments < 1:
        parser.error("--test-environments must be at least 1")
    if iterations_per_test < 1:
        parser.error("--iterations-per-test must be at least 1")
    arch = args.arch or detect_arch()
    tests = select_tests(args.mode)
    OUTPUT_DIR.mkdir(exist_ok=True)
    if args.build_only:
        for test in tests:
            print(f"Compiling {test['test']} {test['tb']} {test['scope']} {test['fence_scope']} {test['variant']}")
            compile_test(test, arch)
        return

    log_path = OUTPUT_DIR / f"{args.mode}.txt"

    start = time.monotonic()
    with open(log_path, "w") as output:
        output.write(f"Mode: {args.mode}\n")
        if args.official_machine:
            output.write(f"Official comparison machine: {args.official_machine}\n")
        output.write(f"CUDA arch: {arch}\n")
        output.write(f"Test environments: {args.test_environments}\n")
        output.write(f"Iterations per test/environment: {iterations_per_test}\n")
        output.write(f"Tests per environment: {len(tests)}\n")
        for test in tests:
            if not args.no_build:
                print(f"Compiling {test['test']} {test['tb']} {test['scope']} {test['fence_scope']} {test['variant']}")
                compile_test(test, arch)
        for environment in range(args.test_environments):
            stress_params = OUTPUT_DIR / f"{args.mode}-env{environment + 1:03d}-params.txt"
            write_stress_params(stress_params, iterations_per_test, environment)
            output.write(f"Environment: {environment + 1}\n")
            print(f"Environment {environment + 1}/{args.test_environments}: {stress_params}")
            for test in tests:
                print(f"Running {test['test']} {test['tb']} {test['scope']} {test['fence_scope']} {test['variant']}")
                run_test(test, stress_params, output)
        elapsed = time.monotonic() - start
        output.write(f"Elapsed seconds: {elapsed:.2f}\n")
        output.write(f"Runner invocations: {len(tests) * args.test_environments}\n")
        output.write(f"Average seconds per runner invocation: {elapsed / (len(tests) * args.test_environments):.4f}\n")

    print(log_path)


if __name__ == "__main__":
    main()
