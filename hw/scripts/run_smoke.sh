#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

official_machine=""
args=()
while [ "$#" -gt 0 ]; do
  case "$1" in
    -h|--help)
      python3 tools/run_campaign.py --mode smoke --help
      exit 0
      ;;
    --official-machine)
      official_machine="$2"
      args+=("$1" "$2")
      shift 2
      ;;
    *)
      args+=("$1")
      shift
      ;;
  esac
done

case "$official_machine" in
  a100|gb10|gh200|h100)
    ;;
  *)
    echo "Usage: $0 --official-machine {a100|gb10|gh200|h100} [run options]" >&2
    exit 2
    ;;
esac

python3 tools/run_campaign.py --mode smoke "${args[@]}"
echo
echo "Smoke comparison summary:"
python3 tools/compare_results.py \
  --log "output/smoke.txt" \
  --official-machine "$official_machine"
