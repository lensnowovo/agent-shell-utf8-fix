$ErrorActionPreference = 'Stop'

$startMarker = '# >>> agent shell UTF-8 fix >>>'
$endMarker = '# <<< agent shell UTF-8 fix <<<'

$block = @'
# >>> agent shell UTF-8 fix >>>
# Windows PowerShell 5.1 defaults to legacy encodings:
# - Get-Content may read UTF-8 files without BOM as ANSI/GBK.
# - $OutputEncoding defaults to US-ASCII, so piping Chinese text to node/python
#   turns it into ?? before the receiving process can decode it.
#
# Keep the shell, native command pipes, and console output on UTF-8 so coding
# agents can safely read/search/pipe Chinese project files.
$AgentShellUtf8NoBom = New-Object System.Text.UTF8Encoding $false
[Console]::InputEncoding = $AgentShellUtf8NoBom
[Console]::OutputEncoding = $AgentShellUtf8NoBom
$OutputEncoding = $AgentShellUtf8NoBom
$PSDefaultParameterValues['Get-Content:Encoding'] = 'UTF8'
$PSDefaultParameterValues['Set-Content:Encoding'] = 'UTF8'
$PSDefaultParameterValues['Add-Content:Encoding'] = 'UTF8'
$PSDefaultParameterValues['Out-File:Encoding'] = 'UTF8'
$PSDefaultParameterValues['Select-String:Encoding'] = 'UTF8'
try { chcp 65001 > $null } catch {}

# Safe SSH helper for coding agents on Windows PowerShell.
# Problem: PowerShell parses pipes/redirection/operators before ssh if the
# remote command is not quoted perfectly, so commands like grep may accidentally
# run locally. Use:
#   rbash user@host 'ps aux | grep node'
#   Invoke-RemoteBash user@host 'cd /app && git status'
function Invoke-RemoteBash {
  param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Target,

    [Parameter(Mandatory = $true, Position = 1)]
    [string]$Command
  )

  $encoded = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($Command))
  ssh $Target "bash -lc 'eval `"`$(printf %s $encoded | base64 -d)`"'"
}

function rbash {
  param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Target,

    [Parameter(Mandatory = $true, Position = 1)]
    [string]$Command
  )

  Invoke-RemoteBash -Target $Target -Command $Command
}
# <<< agent shell UTF-8 fix <<<
'@

$profilePath = $PROFILE
$profileDir = Split-Path -Parent $profilePath
if (-not (Test-Path -LiteralPath $profileDir)) {
  New-Item -ItemType Directory -Path $profileDir | Out-Null
}

if (-not (Test-Path -LiteralPath $profilePath)) {
  New-Item -ItemType File -Path $profilePath | Out-Null
}

$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$backupPath = "$profilePath.bak-$timestamp"
Copy-Item -LiteralPath $profilePath -Destination $backupPath

$content = Get-Content -LiteralPath $profilePath -Raw -Encoding UTF8

if ($content.Contains($startMarker) -and $content.Contains($endMarker)) {
  $pattern = [regex]::Escape($startMarker) + '(?s).*?' + [regex]::Escape($endMarker)
  $content = [regex]::Replace($content, $pattern, $block)
} else {
  if ($content.Length -gt 0 -and -not $content.EndsWith("`n")) {
    $content += "`r`n"
  }
  $content += "`r`n$block`r`n"
}

Set-Content -LiteralPath $profilePath -Value $content -Encoding UTF8

Write-Host "Installed agent shell UTF-8 fix."
Write-Host "Profile: $profilePath"
Write-Host "Backup:  $backupPath"
Write-Host ""
Write-Host "Open a new PowerShell window, then run:"
Write-Host "  .\test-encoding.ps1"
