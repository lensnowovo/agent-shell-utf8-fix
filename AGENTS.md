# Agent Instructions

This repository teaches coding agents how to diagnose and fix Windows PowerShell UTF-8 / Chinese encoding problems.

Use these instructions when a user says:

- PowerShell shows garbled Chinese.
- `Get-Content` returns mojibake.
- Chinese text becomes `??` when piped to Node.js, Python, Git, ripgrep, or another native command.
- Codex / Claude Code / Cursor / GLM keeps working around Chinese by using Unicode escapes.

## Goal

Make the user's Windows coding-agent shell safe for UTF-8 project files, especially Chinese text.

Prefer minimal, reversible changes.

## Diagnose first

Run these commands in PowerShell:

```powershell
$PSVersionTable.PSVersion
chcp
[Console]::InputEncoding
[Console]::OutputEncoding
$OutputEncoding
```

Then test file reading:

```powershell
Get-Content README.md -TotalCount 5
Get-Content -Encoding UTF8 README.md -TotalCount 5
```

If the first command is garbled and the second is correct, `Get-Content` is using the wrong default encoding.

Then test native command piping:

```powershell
$s = [string]::Concat([char]0x4E2D, [char]0x6587)
$s | node -e "process.stdin.on('data', b => console.log(b.toString('hex') + ' ' + b.toString('utf8')))"
```

Expected UTF-8 hex:

```text
e4b8ade69687
```

If it prints `3f3f`, Chinese text is being converted to `??` before it reaches Node.js.

## Fix

Add the following marked block to the user's PowerShell profile.

Get the profile path:

```powershell
$PROFILE
```

Back it up first:

```powershell
Copy-Item -LiteralPath $PROFILE -Destination "$PROFILE.bak-$(Get-Date -Format yyyyMMdd-HHmmss)"
```

Then add:

```powershell
# >>> agent shell UTF-8 fix >>>
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
# <<< agent shell UTF-8 fix <<<
```

Open a new PowerShell session and re-run the tests.

## Important agent rules

- Do not overwrite the whole profile.
- Always create a backup before editing.
- Do not remove unrelated profile content.
- Prefer marked blocks so the change can be removed later.
- In Windows PowerShell 5.1, use `Get-Content -Encoding UTF8` when reading UTF-8 files before the fix is installed.
- Avoid Bash heredocs such as `node <<'NODE'` in PowerShell. Use PowerShell here-strings carefully, or write a temporary script file.
- For patching repository files, prefer the agent's file-editing tool rather than `Set-Content` or `Out-File`.

## Verify

After installation, a new PowerShell process should show:

```text
[Console]::InputEncoding.WebName  -> utf-8
[Console]::OutputEncoding.WebName -> utf-8
$OutputEncoding.WebName           -> utf-8
```

`Get-Content README.md` should show Chinese correctly for UTF-8 project files.

Piping Chinese to Node.js should output UTF-8 bytes:

```text
e4b8ade696870d0a 中文
```

## Recommend PowerShell 7

If the user wants the best long-term fix, recommend:

```powershell
winget install --id Microsoft.PowerShell --source winget
```

Then configure the coding agent to use `pwsh` instead of Windows PowerShell 5.1 when possible.
