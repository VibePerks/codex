# VibePerks for Codex installer (local/dev, PowerShell).
#
# Builds the adapter binary and adds a managed block to your PowerShell profile that
# dot-sources the VibePerks shell integration. Re-running is safe: the managed block is
# replaced, not duplicated.
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$begin = '# >>> vibeperks-codex >>>'
$end = '# <<< vibeperks-codex <<<'

$bin = Join-Path $root 'bin\vibeperks-codex.exe'

# Resolve a runnable binary without requiring Go:
#   1) a prebuilt binary downloaded from the GitHub Release (no Go toolchain needed)
#   2) build from src/ when the Go toolchain is available
$channel = if ($env:VIBEPERKS_RELEASE_CHANNEL) { $env:VIBEPERKS_RELEASE_CHANNEL } else { 'latest' }
$url = if ($channel -eq 'latest') {
    'https://github.com/VibePerks/codex/releases/latest/download/vibeperks-codex-windows-amd64.exe'
} else {
    "https://github.com/VibePerks/codex/releases/download/$channel/vibeperks-codex-windows-amd64.exe"
}
$ready = $false
try {
    Write-Host "Downloading the prebuilt adapter binary ($channel)..."
    Invoke-WebRequest -UseBasicParsing $url -OutFile $bin
    $ready = (Test-Path -LiteralPath $bin)
} catch {
    $ready = $false
}
if (-not $ready) {
    if (Get-Command go -ErrorAction SilentlyContinue) {
        Write-Host 'Download unavailable; building the adapter binary...'
        & go build -C (Join-Path $root 'src') -trimpath -o $bin .
    } else {
        Write-Error 'Could not download a prebuilt binary and Go is not installed. Install Go (https://go.dev/dl) and re-run, or check your network and retry.'
    }
}

$integration = Join-Path $root 'scripts\shell-integration.ps1'
$block = @"
$begin
`$env:VIBEPERKS_CODEX_BIN = '$bin'
. '$integration'
$end
"@

$profilePath = $PROFILE.CurrentUserAllHosts
New-Item -ItemType File -Path $profilePath -Force | Out-Null
$content = Get-Content -LiteralPath $profilePath -Raw -ErrorAction SilentlyContinue
if ($null -eq $content) { $content = '' }
# Remove any previous managed block, then append the current one.
$pattern = [regex]::Escape($begin) + '.*?' + [regex]::Escape($end)
$content = [regex]::Replace($content, $pattern, '', 'Singleline').TrimEnd()
Set-Content -LiteralPath $profilePath -Value ($content + "`n" + $block + "`n")

Write-Host 'Installed. Open a new PowerShell, then run: vibeperks-codex login <device-token>'
