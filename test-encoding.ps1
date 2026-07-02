$ErrorActionPreference = 'Continue'

function Write-Result {
  param(
    [string]$Name,
    [bool]$Ok,
    [string]$Detail
  )
  $status = if ($Ok) { 'PASS' } else { 'FAIL' }
  Write-Host ("[{0}] {1} - {2}" -f $status, $Name, $Detail)
}

Write-Host "Agent Shell UTF-8 Diagnostic"
Write-Host "============================="
Write-Host ""

$psVersion = $PSVersionTable.PSVersion.ToString()
$codePage = (& chcp) -join ''
$inputEncoding = [Console]::InputEncoding.WebName
$consoleOutputEncoding = [Console]::OutputEncoding.WebName
$pipeEncoding = $OutputEncoding.WebName

Write-Host "PowerShell version: $psVersion"
Write-Host "Code page:          $codePage"
Write-Host "InputEncoding:      $inputEncoding"
Write-Host "OutputEncoding:     $consoleOutputEncoding"
Write-Host "Pipe Encoding:      $pipeEncoding"
Write-Host ""

Write-Result "Console input encoding" ($inputEncoding -eq 'utf-8') $inputEncoding
Write-Result "Console output encoding" ($consoleOutputEncoding -eq 'utf-8') $consoleOutputEncoding
Write-Result "Native pipe encoding" ($pipeEncoding -eq 'utf-8') $pipeEncoding

$tmp = Join-Path $env:TEMP ("agent-shell-utf8-test-" + [guid]::NewGuid().ToString('N') + ".txt")
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
$expectedChinese = [string]::Concat([char]0x4E2D, [char]0x6587)
[System.IO.File]::WriteAllText($tmp, $expectedChinese, $utf8NoBom)

try {
  $readDefault = Get-Content -LiteralPath $tmp -Raw
  Write-Result "Get-Content UTF-8 read" ($readDefault.Trim() -eq $expectedChinese) ("read: " + $readDefault.Trim())
} finally {
  Remove-Item -LiteralPath $tmp -ErrorAction SilentlyContinue
}

$node = Get-Command node -ErrorAction SilentlyContinue
if ($node) {
  $script = @'
const chunks = [];
process.stdin.on('data', b => chunks.push(b));
process.stdin.on('end', () => {
  const b = Buffer.concat(chunks);
  console.log(b.toString('hex') + ' ' + b.toString('utf8').trim());
});
'@
  $result = $expectedChinese | node -e $script
  Write-Result "Pipe Chinese to Node.js" ($result -match '^e4b8ade69687') $result
} else {
  Write-Host "[SKIP] Pipe Chinese to Node.js - node not found"
}

$remoteHelper = Get-Command rbash -ErrorAction SilentlyContinue
Write-Result "Remote Bash helper" ($null -ne $remoteHelper) $(if ($remoteHelper) { "rbash available" } else { "rbash not found; run .\install.ps1 and open a new shell" })

Write-Host ""
Write-Host "If any item failed, run .\install.ps1 and open a new PowerShell window."
