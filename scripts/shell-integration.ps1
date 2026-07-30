# VibePerks for Codex - shell integration (PowerShell).
#
# Dot-source this file from your PowerShell profile. It renders the cached VibePerks sponsor
# line above the prompt and in the window title while you work in Codex. It makes ZERO
# network calls - it only reads the local ad cache via `vibeperks-codex render`. The network
# path runs in the background from Codex's prompt hook.
#
# Set $env:VIBEPERKS_CODEX_BIN to the vibeperks-codex binary if it is not on PATH.

function Get-ViberperksCodexBin {
    if ($env:VIBEPERKS_CODEX_BIN) { return $env:VIBEPERKS_CODEX_BIN }
    return 'vibeperks-codex'
}

function Show-VibeperksCodexLine {
    $bin = Get-ViberperksCodexBin
    if (-not (Get-Command $bin -ErrorAction SilentlyContinue)) { return }
    $line = (& $bin render 2>$null | Out-String).Trim()
    if (-not $line) { return }
    Write-Host $line
    $Host.UI.RawUI.WindowTitle = $line
}

if (-not (Test-Path Function:\__VibeperksCodexOrigPrompt)) {
    Copy-Item Function:\prompt Function:\__VibeperksCodexOrigPrompt -ErrorAction SilentlyContinue
}

function prompt {
    Show-VibeperksCodexLine
    if (Test-Path Function:\__VibeperksCodexOrigPrompt) { & __VibeperksCodexOrigPrompt } else { "PS $($executionContext.SessionState.Path.CurrentLocation)> " }
}
