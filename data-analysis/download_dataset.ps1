# =============================================================================
# download_dataset.ps1 — Download RCAEval RE2 dataset (PowerShell / Windows)
# =============================================================================
#
# Usage (from repo root):
#   .\data-analysis\download_dataset.ps1
#
# Requirements:
#   PowerShell 5.1+ or PowerShell 7+ (both work)
#   Internet access
#
# NOTE: Dataset files are NOT committed to git. See .gitignore.
# =============================================================================

$ErrorActionPreference = "Stop"

$RepoRoot   = Split-Path -Parent $PSScriptRoot
$DataDir    = Join-Path $RepoRoot "data\raw"

# ── Dataset URL ───────────────────────────────────────────────────────────────
# TODO (Phase 1): Replace with the canonical stable download URL once confirmed
# by inspecting the RCAEval RE2 repository:
#   https://github.com/NetManAIOps/RCAEval
#
$DatasetUrl  = "https://zenodo.org/records/XXXXXXX/files/RE2.tar.gz"
$DatasetFile = Join-Path $DataDir "RE2.tar.gz"
# SHA-256 checksum — update after you have the real file:
$ExpectedSha256 = "PLACEHOLDER_UPDATE_AFTER_DOWNLOAD"

Write-Host "=== RCAEval RE2 Dataset Download ===" -ForegroundColor Cyan
Write-Host "Target directory: $DataDir"
Write-Host ""

# Create data directory
New-Item -ItemType Directory -Force -Path $DataDir | Out-Null

# ── Download ──────────────────────────────────────────────────────────────────
Write-Host "[1/3] Downloading dataset..." -ForegroundColor Yellow
$ProgressPreference = "SilentlyContinue"   # speeds up Invoke-WebRequest significantly
Invoke-WebRequest -Uri $DatasetUrl -OutFile $DatasetFile
$ProgressPreference = "Continue"
Write-Host "  Saved to: $DatasetFile"

# ── Checksum verification ─────────────────────────────────────────────────────
Write-Host "[2/3] Verifying SHA-256 checksum..." -ForegroundColor Yellow
$ActualSha256 = (Get-FileHash -Path $DatasetFile -Algorithm SHA256).Hash.ToLower()
$ExpectedSha256Lower = $ExpectedSha256.ToLower()

if ($ActualSha256 -ne $ExpectedSha256Lower) {
    Write-Host "ERROR: Checksum mismatch!" -ForegroundColor Red
    Write-Host "  Expected: $ExpectedSha256Lower"
    Write-Host "  Actual:   $ActualSha256"
    Write-Host "Delete '$DatasetFile' and retry."
    exit 1
}
Write-Host "  Checksum OK." -ForegroundColor Green

# ── Extract ───────────────────────────────────────────────────────────────────
Write-Host "[3/3] Extracting archive..." -ForegroundColor Yellow
# tar is available on Windows 10 1803+ and PowerShell 7+
tar -xzf $DatasetFile -C $DataDir

Write-Host ""
Write-Host "=== Done! ===" -ForegroundColor Green
Write-Host "Dataset extracted to: $DataDir"
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. Open data-analysis/notebooks/ and run the EDA notebook (Phase 1)."
Write-Host "  2. Inspect RE2-OB cases first (see docs/decisions.md ADR-008)."
