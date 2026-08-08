#!/usr/bin/env python3
import argparse
import csv
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "hw" / "tools"))

from litmus_lib import OFFICIAL_MACHINES, normalize_test_name, parse_log, read_official_observations  # noqa: E402


ALLOWED = {"SAT", "INSTANCE"}
DISALLOWED = {"UNSAT"}


def read_alloy_results(path):
    results = {}
    rows = 0
    with open(path, newline="") as f:
        reader = csv.DictReader(f)
        required = {"test", "result"}
        missing = required - set(reader.fieldnames or [])
        if missing:
            raise SystemExit(f"{path} is missing required columns: {', '.join(sorted(missing))}")

        for row in reader:
            rows += 1
            test = normalize_test_name(Path(row["test"].strip()).stem)
            result = row["result"].strip()
            previous = results.get(test)
            if previous is not None and previous != result:
                raise SystemExit(f"conflicting Alloy results for {test}: {previous} and {result}")
            results[test] = result
    return results, rows


def read_hardware_results(hw_source, official_machine):
    official_rows = read_official_observations()
    hardware_scope = [row["test"] for row in official_rows]

    if hw_source == "official":
        if official_machine is None:
            raise SystemExit("--official-machine is required when --hw-source official")
        hardware = {row["test"]: row[official_machine] for row in official_rows}
        source_label = f"official:{official_machine}"
    else:
        hardware = parse_log(hw_source)
        source_label = str(hw_source)

    return hardware_scope, hardware, source_label


def compare(alloy, hardware):
    if alloy in ALLOWED:
        if hardware == "seen":
            return "true"
        if hardware == "not seen":
            return "false"
        return "untested"
    if alloy in DISALLOWED:
        if hardware == "seen":
            return "false"
        if hardware == "not seen":
            return "true"
        return "untested"
    if alloy == "missing":
        return "missing-alloy"
    return "unknown-alloy"


def write_csv(path, rows):
    path.parent.mkdir(parents=True, exist_ok=True)
    with open(path, "w", newline="") as f:
        writer = csv.DictWriter(
            f,
            fieldnames=["test", "alloy", "hardware", "hardware_source", "matches"],
        )
        writer.writeheader()
        writer.writerows(rows)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--alloy-csv", default=ROOT / "alloy" / "results.csv", type=Path)
    parser.add_argument(
        "--hw-source",
        required=True,
        help="'official' for bundled hardware results, or a CUDA raw log path such as hw/output/key.txt",
    )
    parser.add_argument("--official-machine", choices=sorted(OFFICIAL_MACHINES))
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument(
        "--include-all-alloy",
        action="store_true",
        help="Also include Alloy rows that are outside the hardware artifact scope.",
    )
    args = parser.parse_args()

    alloy, alloy_row_count = read_alloy_results(args.alloy_csv)
    hardware_scope, hardware, source_label = read_hardware_results(args.hw_source, args.official_machine)

    tests = list(hardware_scope)
    if args.include_all_alloy:
        tests.extend(sorted(set(alloy) - set(hardware_scope)))

    rows = []
    for test in tests:
        alloy_result = alloy.get(test, "missing")
        hardware_result = hardware.get(test, "untested")
        rows.append(
            {
                "test": test,
                "alloy": alloy_result,
                "hardware": hardware_result,
                "hardware_source": source_label,
                "matches": compare(alloy_result, hardware_result),
            }
        )

    write_csv(args.output, rows)

    tested = [row for row in rows if row["hardware"] != "untested"]
    matching = [row for row in tested if row["matches"] == "true"]
    seen_disallowed = [
        row for row in tested if row["hardware"] == "seen" and row["alloy"] in DISALLOWED
    ]
    allowed_not_seen = [
        row for row in tested if row["hardware"] == "not seen" and row["alloy"] in ALLOWED
    ]
    untested = [row for row in rows if row["hardware"] == "untested"]
    missing_alloy = [row for row in rows if row["alloy"] == "missing"]
    alloy_outside_scope = sorted(set(alloy) - set(hardware_scope))

    print(f"Alloy rows: {alloy_row_count}")
    print(f"Hardware rows considered: {len(hardware_scope)}")
    print(f"Combined rows written: {len(rows)}")
    print(f"Tested rows: {len(tested)}")
    print(f"Matching tested rows: {len(matching)}")
    print(f"Hardware seen but Alloy UNSAT: {len(seen_disallowed)}")
    print(f"Hardware not seen but Alloy SAT/INSTANCE: {len(allowed_not_seen)}")
    print(f"Untested rows: {len(untested)}")
    print(f"Missing Alloy rows in hardware scope: {len(missing_alloy)}")
    if not args.include_all_alloy:
        print(f"Alloy rows outside hardware scope: {len(alloy_outside_scope)}")

    if seen_disallowed:
        print("\nHardware seen but Alloy UNSAT tests:")
        for row in seen_disallowed[:20]:
            print(f"  {row['test']}")

    return 1 if seen_disallowed else 0


if __name__ == "__main__":
    sys.exit(main())
