#!/usr/bin/env bash
# =============================================================================
# download_dataset.sh — Download RCAEval RE2 dataset (Bash / Git Bash / WSL)
# =============================================================================
#
# Usage:
#   bash data-analysis/download_dataset.sh
#
# Requirements:
#   curl or wget, sha256sum (or shasum on macOS)
#
# What this script does:
#   1. Creates data/raw/ in the repo root (gitignored).
#   2. Downloads the RCAEval RE2 dataset from the official source.
#   3. Verifies the SHA-256 checksum.
#   4. Extracts the archive.
#
# NOTE: Dataset files are NOT committed to git. See .gitignore.
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
DATA_DIR="${REPO_ROOT}/data/raw"

# ── Dataset URL ───────────────────────────────────────────────────────────────
# TODO (Phase 1): Replace with the canonical stable download URL once confirmed
# by inspecting the RCAEval RE2 repository:
#   https://github.com/NetManAIOps/RCAEval
#
# The RE2 dataset is typically hosted on Zenodo or a GitHub release.
# Run `inspect_dataset.py` (Phase 1) after download to confirm schema.
DATASET_URL="https://zenodo.org/records/XXXXXXX/files/RE2.tar.gz"
DATASET_FILE="${DATA_DIR}/RE2.tar.gz"
# SHA256 checksum — update after you have the real file:
EXPECTED_SHA256="PLACEHOLDER_UPDATE_AFTER_DOWNLOAD"

echo "=== RCAEval RE2 Dataset Download ==="
echo "Target directory: ${DATA_DIR}"
echo ""

# Create data directory
mkdir -p "${DATA_DIR}"

# Download
if command -v curl &>/dev/null; then
    echo "[1/3] Downloading with curl..."
    curl -L --progress-bar -o "${DATASET_FILE}" "${DATASET_URL}"
elif command -v wget &>/dev/null; then
    echo "[1/3] Downloading with wget..."
    wget --show-progress -O "${DATASET_FILE}" "${DATASET_URL}"
else
    echo "ERROR: Neither curl nor wget found. Install one and retry."
    exit 1
fi

# Checksum verification
echo "[2/3] Verifying SHA-256 checksum..."
if command -v sha256sum &>/dev/null; then
    ACTUAL_SHA256=$(sha256sum "${DATASET_FILE}" | awk '{print $1}')
elif command -v shasum &>/dev/null; then
    ACTUAL_SHA256=$(shasum -a 256 "${DATASET_FILE}" | awk '{print $1}')
else
    echo "WARNING: sha256sum/shasum not found. Skipping checksum verification."
    ACTUAL_SHA256="${EXPECTED_SHA256}"
fi

if [ "${ACTUAL_SHA256}" != "${EXPECTED_SHA256}" ]; then
    echo "ERROR: Checksum mismatch!"
    echo "  Expected: ${EXPECTED_SHA256}"
    echo "  Actual:   ${ACTUAL_SHA256}"
    echo "Delete ${DATASET_FILE} and retry."
    exit 1
fi
echo "  Checksum OK."

# Extract
echo "[3/3] Extracting archive..."
tar -xzf "${DATASET_FILE}" -C "${DATA_DIR}"
echo ""
echo "=== Done! ==="
echo "Dataset extracted to: ${DATA_DIR}"
echo ""
echo "Next steps:"
echo "  1. Open data-analysis/notebooks/ and run the EDA notebook (Phase 1)."
echo "  2. Inspect RE2-OB cases first (see docs/decisions.md ADR-008)."
