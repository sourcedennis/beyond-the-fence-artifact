#!/usr/bin/env python3
import csv
import random
import re
import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
TUNING_DIR = ROOT / "tuning-files"
PARAMS_DIR = ROOT / "params"
SRC_DIR = ROOT / "src"
KERNELS_DIR = SRC_DIR / "kernels"
BUILD_DIR = ROOT / "build"
OUTPUT_DIR = ROOT / "output"

OFFICIAL_MACHINES = {"a100", "h100", "gh200", "gb10"}

def run(cmd, *, cwd=ROOT, stdout=None):
    return subprocess.run(cmd, cwd=cwd, check=True, text=True, stdout=stdout)


def find_nvcc():
    candidates = [
        "nvcc",
        "/usr/local/cuda/bin/nvcc",
        "/usr/local/cuda-13.0/bin/nvcc",
        "/usr/local/cuda-13/bin/nvcc",
        "/usr/local/cuda-12.0/bin/nvcc",
        "/usr/local/cuda-12/bin/nvcc",
    ]
    for candidate in candidates:
        try:
            subprocess.run(
                [candidate, "--version"],
                check=True,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
            return candidate
        except Exception:
            continue
    return "nvcc"


def detect_arch():
    try:
        query = subprocess.check_output(
            ["nvidia-smi", "--query-gpu=compute_cap", "--format=csv,noheader"],
            text=True,
        ).strip().splitlines()[0]
    except Exception:
        return "sm_80"

    match = re.search(r"(\d+)\.(\d+)", query)
    if not match:
        return "sm_80"
    return f"sm_{match.group(1)}{match.group(2)}"


def safe_name(*parts):
    return "-".join(part for part in parts if part)


def make_even(value):
    return value if value % 2 == 0 else value + 1


def kernel_name(test_name):
    return f"{test_name}.cu"


def load_tuning_file(path):
    lines = [line.strip() for line in path.read_text().splitlines() if line.strip()]
    if not lines:
        return []

    first = lines[0].split()
    if len(first) == 6:
        test_name, params, tb, scope, fence_scope, variant = first
        return [
            {
                "test": test_name,
                "params": params,
                "tb": tb,
                "scope": scope,
                "fence_scope": fence_scope,
                "variant": variant,
            }
        ]

    test_name, params = first
    threadblocks = lines[1].split()
    scopes = lines[2].split()
    variants = lines[3].split()
    fence_scopes = []
    fence_variants = []
    if len(lines) >= 6:
        fence_scopes = lines[4].split()
        fence_variants = lines[5].split()

    tests = []
    for tb in threadblocks:
        for scope in scopes:
            for variant in variants:
                tests.append(
                    {
                        "test": test_name,
                        "params": params,
                        "tb": tb,
                        "scope": scope,
                        "fence_scope": "NO_FENCE",
                        "variant": variant,
                    }
                )
            for fence_scope in fence_scopes:
                for variant in fence_variants:
                    tests.append(
                        {
                            "test": test_name,
                            "params": params,
                            "tb": tb,
                            "scope": scope,
                            "fence_scope": fence_scope,
                            "variant": variant,
                        }
                    )
    return tests


def load_manifest(suite="core"):
    tuning_files = sorted(TUNING_DIR.glob("*.txt"))
    tests = []
    for path in tuning_files:
        tests.extend(load_tuning_file(path))
    if suite == "core":
        pass
    elif suite != "all":
        raise ValueError(f"unknown suite: {suite}")
    return tests


def manifest_key(test):
    return (
        test["test"],
        test["tb"],
        test["scope"],
        test["fence_scope"],
        test["variant"],
    )


def test_id(test):
    return safe_name(test["test"], test["tb"], test["scope"], test["fence_scope"], test["variant"])


def binary_path(test):
    return BUILD_DIR / f"{test_id(test)}-runner"


def compile_test(test, arch):
    BUILD_DIR.mkdir(exist_ok=True)
    cmd = [
        find_nvcc(),
        f"-D{test['tb']}",
        f"-D{test['scope']}",
    ]
    if test["fence_scope"] != "NO_FENCE":
        cmd.append(f"-D{test['fence_scope']}")
    cmd.extend(
        [
            f"-D{test['variant']}",
            "-I",
            str(SRC_DIR),
            "-rdc=true",
            "-arch",
            arch,
            str(SRC_DIR / "runner.cu"),
            str(KERNELS_DIR / kernel_name(test["test"])),
            "-o",
            str(binary_path(test)),
        ]
    )
    run(cmd)


def write_stress_params(path, iterations, environment_index=0):
    rng = random.Random(0xC0DA + environment_index)
    stress_line_size = rng.randint(2, 10) ** 2
    stress_target_lines = rng.randint(1, 16)
    testing_workgroups = rng.randint(4, 1024)
    max_workgroups = rng.randint(testing_workgroups, 1024)
    params = {
        "testIterations": iterations,
        "testingWorkgroups": testing_workgroups,
        "maxWorkgroups": max_workgroups,
        "workgroupSize": make_even(rng.randint(1, 256)),
        "shufflePct": rng.randint(0, 100),
        "barrierPct": rng.randint(0, 100),
        "stressLineSize": stress_line_size,
        "stressTargetLines": stress_target_lines,
        "scratchMemorySize": 32 * stress_line_size * stress_target_lines,
        "memStride": rng.randint(1, 7),
        "memStressPct": rng.randint(0, 100),
        "memStressIterations": rng.randint(0, 1024),
        "memStressPattern": rng.randint(0, 3),
        "preStressPct": rng.randint(0, 100),
        "preStressIterations": rng.randint(0, 128),
        "preStressPattern": rng.randint(0, 3),
        "stressAssignmentStrategy": rng.randint(0, 1),
        "permuteThread": 419,
    }
    with open(path, "w") as f:
        for key, value in params.items():
            f.write(f"{key}={value}\n")


def run_test(test, stress_params, output):
    proc = subprocess.run(
        [
            str(binary_path(test)),
            "-s",
            str(stress_params),
            "-t",
            str(PARAMS_DIR / test["params"]),
        ],
        cwd=ROOT,
        check=True,
        text=True,
        capture_output=True,
    )
    weak = total = rate = "0"
    for line in proc.stdout.splitlines():
        if line.startswith("Weak behavior rate:"):
            rate = line.split(":", 1)[1].strip().split()[0]
        elif line.startswith("Total behaviors:"):
            total = line.split(":", 1)[1].strip()
        elif line.startswith("Number of weak behaviors:"):
            weak = line.split(":", 1)[1].strip()
    output.write(
        f"  Test {test_id(test)} weak: {weak}, total: {total}, rate: {rate} per second\n"
    )


def parse_log(path):
    observations = {}
    pattern = re.compile(r"^\s*Test\s+(\S+)\s+weak:\s+(\d+),")
    with open(path) as f:
        for line in f:
            match = pattern.match(line)
            if not match:
                continue
            test = normalize_test_name(match.group(1))
            if int(match.group(2)) > 0:
                observations[test] = "seen"
            elif observations.get(test) != "seen":
                observations[test] = "not seen"
    return observations


def normalize_test_name(name):
    name = name.replace("-", "_").replace("+", "_").replace(".", "_")
    if name.startswith("2_"):
        name = "two_" + name[2:]
    if name.startswith("3_"):
        name = "three_" + name[2:]
    name = name.replace("TB_02_1_SCOPE", "TB_1_02_SCOPE")
    if name.startswith("paper_example") and name.endswith("NO_FENCE_DISALLOWED"):
        name = name.replace("NO_FENCE_DISALLOWED", "FENCE_SCOPE_DEVICE_DISALLOWED")
    return name


def read_official_observations():
    path = ROOT / "expected" / "official-observations.csv"
    with open(path, newline="") as f:
        return list(csv.DictReader(f))
