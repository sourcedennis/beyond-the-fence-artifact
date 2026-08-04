#!/usr/bin/env python3
import argparse
import csv
import sys

from litmus_lib import OFFICIAL_MACHINES, normalize_test_name, parse_log, read_official_observations


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--log", required=True)
    parser.add_argument("--official-machine", required=True, choices=sorted(OFFICIAL_MACHINES))
    parser.add_argument("--output-csv")
    args = parser.parse_args()

    observed = parse_log(args.log)
    official_rows = read_official_observations()

    rows = []
    for row in official_rows:
        test = row["test"]
        reviewer = observed.get(test, "untested")
        official = row[args.official_machine]
        rows.append(
            {
                "test": test,
                "suite": row["suite"],
                "official_machine": args.official_machine,
                "official": official,
                "reviewer": reviewer,
                "matches": str(reviewer == official).lower() if reviewer != "untested" else "untested",
            }
        )

    tested = [row for row in rows if row["reviewer"] != "untested"]
    matched = [row for row in tested if row["reviewer"] == row["official"]]
    official_seen_missed = [
        row for row in tested if row["official"] == "seen" and row["reviewer"] == "not seen"
    ]
    unexpected_seen = [
        row for row in tested if row["official"] == "not seen" and row["reviewer"] == "seen"
    ]

    print(f"Official machine: {args.official_machine}")
    print(f"Tests in official table: {len(rows)}")
    print(f"Reviewer-tested rows: {len(tested)}")
    print(f"Matching tested rows: {len(matched)}")
    print(f"Official seen but not seen in reviewer log: {len(official_seen_missed)}")
    print(f"Unexpected reviewer seen: {len(unexpected_seen)}")

    if unexpected_seen:
        print("\nUnexpected reviewer seen tests:")
        for row in unexpected_seen[:20]:
            print(f"  {row['test']}")

    if args.output_csv:
        with open(args.output_csv, "w", newline="") as f:
            writer = csv.DictWriter(
                f,
                fieldnames=[
                    "test",
                    "suite",
                    "official_machine",
                    "official",
                    "reviewer",
                    "matches",
                ],
            )
            writer.writeheader()
            writer.writerows(rows)

    return 1 if unexpected_seen else 0


if __name__ == "__main__":
    sys.exit(main())
