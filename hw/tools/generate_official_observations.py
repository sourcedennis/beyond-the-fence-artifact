#!/usr/bin/env python3
import csv

from litmus_lib import ROOT, load_manifest, normalize_test_name, parse_log, test_id


MACHINES = ["a100", "h100", "gh200", "gb10"]


def main():
    tests = []
    seen = set()
    for test in load_manifest("core"):
        name = normalize_test_name(test_id(test))
        if name in seen:
            continue
        seen.add(name)
        tests.append(name)

    observations = {
        machine: parse_log(ROOT / "expected" / "raw" / f"{machine}.txt")
        for machine in MACHINES
    }

    out_path = ROOT / "expected" / "official-observations.csv"
    with open(out_path, "w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=["test", "suite", *MACHINES])
        writer.writeheader()
        for test in tests:
            row = {"test": test, "suite": "core"}
            for machine in MACHINES:
                row[machine] = observations[machine].get(test, "untested")
            writer.writerow(row)


if __name__ == "__main__":
    main()
