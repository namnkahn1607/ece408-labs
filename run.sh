#!/usr/bin/env bash
# Run an ECE408 lab's <MP>_main executable against its fetched datasets
# and report a PASS / FAIL summary.
#
# Usage:
#   bash run.sh <MP0..MP8> [debug|release]
#   (If invoked from inside code/MP<N>/, <MP0..MP8> can be omitted.)
set -euo pipefail

CALLER_PWD="$(pwd)"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"

log() { echo "[INFO] $*" >&2; }
die() { echo "[ERROR] $*" >&2; exit 1; }

LAB=""
PRESET="debug"

# Parse arguments: allow `bash run.sh MP1 [debug|release]` or (from code/MP1/) `bash ../../run.sh [debug|release]`
if [[ $# -eq 0 ]]; then
    if [[ "$(basename "$CALLER_PWD")" =~ ^MP[0-8]$ ]]; then
        LAB="$(basename "$CALLER_PWD")"
    else
        die "Usage: bash run.sh <MP0..MP8> [debug|release]"
    fi
elif [[ $# -eq 1 ]]; then
    if [[ "$1" =~ ^MP[0-8]$ ]]; then
        LAB="$1"
    elif [[ "$1" =~ ^(debug|release)$ ]] && [[ "$(basename "$CALLER_PWD")" =~ ^MP[0-8]$ ]]; then
        LAB="$(basename "$CALLER_PWD")"
        PRESET="$1"
    else
        die "Usage: bash run.sh <MP0..MP8> [debug|release]"
    fi
elif [[ $# -eq 2 ]]; then
    LAB="$1"
    PRESET="$2"
else
    die "Usage: bash run.sh <MP0..MP8> [debug|release]"
fi

[[ "$LAB" =~ ^MP[0-8]$ ]] || die "Invalid lab '$LAB'. Expected MP0..MP8"
[[ "$PRESET" =~ ^(debug|release)$ ]] || die "Invalid preset '$PRESET'. Expected 'debug' or 'release'"

BIN="${REPO_ROOT}/build/${PRESET}/bin/${LAB}_main"
if [[ ! -x "$BIN" ]]; then
    die "Executable not found at ${BIN}. Build it first with: cmake --build --preset ${PRESET}"
fi

# MP0 has no datasets
if [[ "$LAB" == "MP0" ]]; then
    log "Running ${BIN}..."
    exec "$BIN"
fi

DATA_ROOT="${REPO_ROOT}/code/${LAB}/data"
if [[ ! -d "$DATA_ROOT" ]]; then
    die "Dataset directory not found at ${DATA_ROOT}. Fetch it first with: bash pull.sh ${LAB}"
fi

mapfile -t DATASET_DIRS < <(find "$DATA_ROOT" -mindepth 1 -maxdepth 1 -type d | sort -V)
[[ ${#DATASET_DIRS[@]} -gt 0 ]] || die "No dataset folders found inside ${DATA_ROOT}"

passed=0
failed=0
failed_ids=()

for d in "${DATASET_DIRS[@]}"; do
    ds_id="$(basename "$d")"
    case "$LAB" in
        MP1)
            args=(-e "$d/output.raw" -i "$d/input0.raw,$d/input1.raw" -t vector)
            ;;
        MP2|MP3)
            args=(-e "$d/output.raw" -i "$d/input0.raw,$d/input1.raw" -t matrix)
            ;;
        MP4)
            args=(-e "$d/output.dat" -i "$d/input.dat,$d/kernel.dat" -t vector)
            ;;
        MP5)
            args=(-e "$d/output.raw" -i "$d/input0.raw" -t vector)
            ;;
        MP6)
            args=(-e "$d/output.raw" -i "$d/input.raw" -t vector)
            ;;
        MP7)
            args=(-e "$d/output.ppm" -i "$d/input.ppm" -t image)
            ;;
            MP8)
            args=(-e "$d/output.raw" -i "$d/data.raw,$d/col.raw,$d/row.raw,$d/vec.raw" -t vector)
            ;;
    esac

    printf '============== %s Dataset %s ==============\n' "$LAB" "$ds_id"
    set +e
    output="$("$BIN" "${args[@]}" 2>&1)"
    rc=$?
    set -e
    printf '%s\n' "$output"

    if [[ $rc -eq 0 ]] && grep -Eq 'The solution is correct|"correctq":[[:space:]]*true' <<< "$output" \
        && ! grep -Eq 'NOT correct|"correctq":[[:space:]]*false' <<< "$output"; then
        printf '[PASS] Dataset %s\n\n' "$ds_id"
        passed=$((passed + 1))
    else
        printf '[FAIL] Dataset %s (exit=%d)\n\n' "$ds_id" "$rc"
        failed=$((failed + 1))
        failed_ids+=("$ds_id")
    fi
done

total=$((passed + failed))
printf '==========================================\n'
if [[ $failed -eq 0 ]]; then
    printf '[SUMMARY] %s (%s): PASS (%d/%d datasets)\n' "$LAB" "$PRESET" "$passed" "$total"
    exit 0
else
    printf '[SUMMARY] %s (%s): FAIL (%d/%d passed; failed datasets: %s)\n' \
        "$LAB" "$PRESET" "$passed" "$total" "${failed_ids[*]}"
    exit 1
fi
