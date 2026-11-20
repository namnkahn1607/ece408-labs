#!/usr/bin/env bash
# Fetch template.cu and dataset resources (data/, imgs/) for an ECE408 lab,
# and open its README in the browser.
#
# Usage: bash pull.sh <MP0..MP8>
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
cd "$REPO_ROOT"

log()  { echo "[INFO] $*" >&2; }
warn() { echo "[WARN] $*" >&2; }
die()  { echo "[ERROR] $*" >&2; exit 1; }

if [[ $# -ne 1 ]]; then
    die "Usage: bash pull.sh MP<0-8> (exactly one lab argument is required)"
fi

LAB="$1"
if [[ ! "$LAB" =~ ^MP[0-8]$ ]]; then
    die "Invalid lab '$LAB'. Expected one of: MP0..MP8"
fi

UPSTREAM_REPO="https://github.com/aschuh703/ECE408"
UPSTREAM_GIT="${ECE408_UPSTREAM_GIT:-${UPSTREAM_REPO}.git}"
CACHE_DIR="${ECE408_CACHE_DIR:-${REPO_ROOT}/.cache/ece408-upstream}"

# 1. Populate or update the sparse git cache in .cache/ece408-upstream
if [[ ! -d "${CACHE_DIR}/.git" ]]; then
    log "Initializing sparse upstream cache at ${CACHE_DIR}..."
    mkdir -p "$(dirname "$CACHE_DIR")"
    rm -rf "$CACHE_DIR"
    git clone --filter=blob:none --no-checkout --depth 1 --sparse "$UPSTREAM_GIT" "$CACHE_DIR"
    git -C "$CACHE_DIR" sparse-checkout set "$LAB"
    git -C "$CACHE_DIR" checkout -q
elif [[ ! -d "${CACHE_DIR}/${LAB}" ]]; then
    log "Fetching ${LAB} into sparse cache..."
    git -C "$CACHE_DIR" sparse-checkout add "$LAB"
    if [[ ! -d "${CACHE_DIR}/${LAB}" ]]; then
        git -C "$CACHE_DIR" checkout -q
    fi
else
    log "Using cached upstream resources for ${LAB} (${CACHE_DIR}/${LAB})"
fi

SRC_DIR="${CACHE_DIR}/${LAB}"
[[ -d "$SRC_DIR" ]] || die "Upstream directory '${LAB}' not found in ${UPSTREAM_GIT}"

DST_DIR="${REPO_ROOT}/code/${LAB}"
mkdir -p "$DST_DIR"

# 2. Ensure code/MP<id>/CMakeLists.txt exists
if [[ ! -f "${DST_DIR}/CMakeLists.txt" ]]; then
    printf 'add_lab()\n' > "${DST_DIR}/CMakeLists.txt"
    log "Created code/${LAB}/CMakeLists.txt"
fi

# Helper: copy src -> dst only if missing or content differs
sync_file() {
    local src="$1"
    local dst="$2"
    if [[ -f "$dst" ]] && cmp -s "$src" "$dst"; then
        return 1
    fi
    mkdir -p "$(dirname "$dst")"
    cp -f "$src" "$dst"
    return 0
}

# 3. Sync template.cu
if [[ -f "${SRC_DIR}/template.cu" ]]; then
    if sync_file "${SRC_DIR}/template.cu" "${DST_DIR}/template.cu"; then
        log "Synced code/${LAB}/template.cu"
    else
        log "Up-to-date: code/${LAB}/template.cu"
    fi
fi

# 4. Sync directory resources (data/, imgs/) if present upstream
for subdir in data imgs; do
    if [[ -d "${SRC_DIR}/${subdir}" ]]; then
        synced_count=0
        uptodate_count=0
        while IFS= read -r -d '' src_file; do
            rel_path="${src_file#"${SRC_DIR}/"}"
            dst_file="${DST_DIR}/${rel_path}"
            if sync_file "$src_file" "$dst_file"; then
                synced_count=$((synced_count + 1))
            else
                uptodate_count=$((uptodate_count + 1))
            fi
        done < <(find "${SRC_DIR}/${subdir}" -type f -print0)
        log "code/${LAB}/${subdir}/: ${synced_count} synced, ${uptodate_count} already up-to-date"
    fi
done

# 5. Provide and open the Readme URL
BRANCH="$(git -C "$CACHE_DIR" symbolic-ref --short HEAD 2>/dev/null || echo master)"
README_NAME="Readme.md"
for candidate in Readme.md README.md readme.md; do
    if [[ -f "${SRC_DIR}/${candidate}" ]]; then
        README_NAME="$candidate"
        break
    fi
done
README_URL="${UPSTREAM_REPO}/blob/${BRANCH}/${LAB}/${README_NAME}"
log "Lab specification: ${README_URL}"

if [[ "${ECE408_NO_BROWSER:-0}" != "1" ]] && command -v wslview >/dev/null 2>&1; then
    wslview "$README_URL" >/dev/null 2>&1 || warn "wslview failed to open browser; open the URL above manually."
fi
