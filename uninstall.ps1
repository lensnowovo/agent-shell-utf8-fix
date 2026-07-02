$ErrorActionPreference = 'Stop'

$startMarker = '# >>> agent shell UTF-8 fix >>>'
$endMarker = '# <<< agent shell UTF-8 fix <<<'
$profilePath = $PROFILE

if (-not (Test-Path -LiteralPath $profilePath)) {
  Write-Host "Profile does not exist: $profilePath"
  exit 0
}

$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$backupPath = "$profilePath.bak-$timestamp"
Copy-Item -LiteralPath $profilePath -Destination $backupPath

$content = Get-Content -LiteralPath $profilePath -Raw -Encoding UTF8

if (-not ($content.Contains($startMarker) -and $content.Contains($endMarker))) {
  Write-Host "No agent shell UTF-8 fix block found."
  Write-Host "Backup: $backupPath"
  exit 0
}

$pattern = '\r?\n?' + [regex]::Escape($startMarker) + '(?s).*?' + [regex]::Escape($endMarker) + '\r?\n?'
$content = [regex]::Replace($content, $pattern, "`r`n")
Set-Content -LiteralPath $profilePath -Value $content -Encoding UTF8

Write-Host "Removed agent shell UTF-8 fix block."
Write-Host "Profile: $profilePath"
Write-Host "Backup:  $backupPath"
