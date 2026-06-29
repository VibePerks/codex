# VibePerks for Codex installer (local/dev, PowerShell).
#
# Builds the adapter binary and adds a managed block to your PowerShell profile that
# dot-sources the VibePerks shell integration. Re-running is safe: the managed block is
# replaced, not duplicated.
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$begin = '# >>> vibeperks-codex >>>'
$end = '# <<< vibeperks-codex <<<'

Write-Host 'Building the adapter binary...'
& go build -C (Join-Path $root 'src') -trimpath -o (Join-Path $root 'bin\vibeperks-codex.exe') .

$bin = Join-Path $root 'bin\vibeperks-codex.exe'
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
