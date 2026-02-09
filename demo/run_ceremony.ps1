# =========================
# DEMO: run_ceremony.ps1
# One-command Proof-of-Existence ceremony runner
# =========================
# Usage (from repo root):
#   pwsh .\demo\run_ceremony.ps1 -CeremonyId "VATA-POE-002"
#
# Requires:
#   - Python in PATH
#   - Foundry (cast) installed
#   - $env:PK set (private key) OR use --account mode (see note below)
#
param(
  [string]$CeremonyId = "VATA-POE-002",
  [string]$RpcUrl = "https://ethereum-sepolia-rpc.publicnode.com",
  [string]$Contract = "0xe0C202DF9D1d0187d84f4b94c8966cA6CD9c4d8e"
)

$ErrorActionPreference = "Stop"

# Ensure we are at repo root (has pipeline\make_manifest.py)
if (!(Test-Path ".\pipeline\make_manifest.py")) {
  throw "Run this from the repo root (vata-verifiable). Missing .\pipeline\make_manifest.py"
}

# Create demo folder
$demoDir = Join-Path -Path ".\ceremony" -ChildPath $CeremonyId
New-Item -ItemType Directory -Force -Path $demoDir | Out-Null

# Create deterministic input/output (edit text if you want)
@"
AI Proof of Existence Ceremony $CeremonyId
Repo: https://github.com/LHMisme420/vata-verifiable
Purpose: Create a public, verifiable chain-of-custody record for an AI artifact.
"@ | Set-Content -Encoding UTF8 (Join-Path $demoDir "input.txt")

@"
This text is the ceremony output for $CeremonyId.
Integrity is proven by deterministic hashing + Merkle batching + Ethereum anchoring.
"@ | Set-Content -Encoding UTF8 (Join-Path $demoDir "output.txt")

Push-Location $demoDir

# Generate manifest + hash
python ..\..\pipeline\make_manifest.py input.txt output.txt | Out-Host
$manifestPath = ".\manifest.json"
if (!(Test-Path $manifestPath)) { throw "manifest.json not created." }

$manifestHash = (python ..\..\pipeline\hash_manifest.py manifest.json).Trim()
$manifestHash | Set-Content -Encoding ASCII ".\manifest_hash.txt"

# Build batch + merkle root (single leaf => root == leaf, still valid)
$manifestHash | Set-Content -Encoding ASCII ".\batch_hashes.txt"
$merkleRoot = (python ..\..\batch\build_merkle.py batch_hashes.txt).Trim()
$merkleRoot | Set-Content -Encoding ASCII ".\merkle_root.txt"

# Anchor on-chain
if ([string]::IsNullOrWhiteSpace($env:PK)) {
  throw "Missing env var PK. Set it first: `$env:PK=""YOUR_PRIVATE_KEY_NO_0x""`"
}

Write-Host "`nAnchoring root on-chain..."
$tx = (cast send $Contract `
  "anchor(bytes32)" `
  $merkleRoot `
  --rpc-url $RpcUrl `
  --private-key $env:PK).Trim()

# cast send prints a receipt block; extract tx hash if present
# If receipt already printed, also try to read it from the output using regex
$txHash = $null
if ($tx -match "0x[a-fA-F0-9]{64}") { $txHash = $Matches[0] }

# Safer: query the latest tx hash from receipt by re-sending isn't possible; so we store full output too.
$tx | Set-Content -Encoding UTF8 ".\anchor_receipt.txt"

# Build ceremony record
$record = [ordered]@{
  ceremony_id      = $CeremonyId
  created_utc      = (Get-Date).ToUniversalTime().ToString("o")
  manifest_hash    = $manifestHash
  merkle_root      = $merkleRoot
  anchor_contract  = $Contract
  rpc_url          = $RpcUrl
  anchor_tx        = $txHash
  notes            = "If anchor_tx is null, open anchor_receipt.txt and copy the transactionHash value."
}
($record | ConvertTo-Json -Depth 4) | Set-Content -Encoding UTF8 ".\ceremony_record.json"

Pop-Location

Write-Host "`n=== CEREMONY COMPLETE ==="
Write-Host "Folder: $demoDir"
Write-Host "Manifest hash: $manifestHash"
Write-Host "Merkle root:   $merkleRoot"
Write-Host "Contract:      $Contract"
Write-Host "RPC:           $RpcUrl"
if ($txHash) { Write-Host "TX:            $txHash" } else { Write-Host "TX:            (see $demoDir\anchor_receipt.txt)" }

Write-Host "`nVerify on-chain (event decode):"
Write-Host "cast logs $txHash --rpc-url $RpcUrl --abi-event `"Anchored(bytes32,uint256)`""
