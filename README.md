# Agent Shell UTF-8 Fix

Fix Chinese / UTF-8 encoding issues and common Windows PowerShell command traps when using Codex, Claude Code, Cursor, GLM or other coding agents.

If your agent keeps saying things like:

- “PowerShell here-string encoding issue”
- “I switched to Unicode escapes”
- “Get-Content shows garbled Chinese”
- “Chinese text becomes `??` when piped to Node or Python”
- “PowerShell split my remote `grep` pipeline and ran part of it locally”

this repo is probably for you.

## What breaks

Windows PowerShell 5.1 often starts with legacy defaults:

```text
chcp: 936
[Console]::InputEncoding: gb2312
$OutputEncoding: us-ascii
```

That creates common failures:

1. `Get-Content` may read UTF-8 files without BOM as ANSI / GBK.
2. Piping Chinese text to native programs such as `node`, `python`, `rg`, or `git` may turn it into `??` before the program receives it.
3. PowerShell may parse remote SSH pipes and operators locally if commands are not quoted safely.

Coding agents hit this often because they read files, search text, pipe scripts, and patch code through the shell all day.

## Quick test

Run:

```powershell
.\test-encoding.ps1
```

It checks:

- PowerShell version
- active code page
- console input/output encoding
- `$OutputEncoding`
- UTF-8 file reading
- piping Chinese text to Node.js

## Quick fix

Run:

```powershell
.\install.ps1
```

It will:

- back up your PowerShell profile;
- add a clearly marked UTF-8 initialization block;
- set console input/output encoding to UTF-8;
- set `$OutputEncoding` to UTF-8;
- make common file commands default to UTF-8 in Windows PowerShell 5.1:
  - `Get-Content`
  - `Set-Content`
  - `Add-Content`
  - `Out-File`
  - `Select-String`
- add a safe SSH helper for remote Bash commands:
  - `Invoke-RemoteBash`
  - `rbash`

Open a new PowerShell window after installation.

## Remote command helper

PowerShell may parse pipes and operators before `ssh` receives them.

Avoid:

```powershell
ssh user@server ps aux | grep node
ssh user@server cd /app && git pull
```

After installing, use:

```powershell
rbash user@server 'ps aux | grep node'
rbash user@server 'cd /app && git status && git pull'
```

`rbash` sends the command to remote Bash safely, so `|`, `&&`, `||`, `$`, quotes and redirects do not get eaten by local PowerShell.

## Recommended long-term fix

Install PowerShell 7:

```powershell
winget install --id Microsoft.PowerShell --source winget
```

PowerShell 7 is UTF-8 by default and avoids most of the Windows PowerShell 5.1 encoding traps.

## For coding agents

Tell your agent:

```text
Read https://github.com/lensnowovo/agent-shell-utf8-fix and follow AGENTS.md to diagnose and fix my Windows PowerShell UTF-8 / Chinese encoding and remote command quoting issues.
```

The agent should read `AGENTS.md` first.

## Uninstall

Run:

```powershell
.\uninstall.ps1
```

It removes only the marked block:

```text
# >>> agent shell UTF-8 fix >>>
...
# <<< agent shell UTF-8 fix <<<
```

Your other profile content is left untouched.

## 中文说明

这个项目解决的是 Windows PowerShell 5.1 下，AI Coding Agent 操作中文项目时常见的乱码问题。

它也顺手解决一个常见的远程命令坑：在 PowerShell 里执行 SSH 命令时，本地 PowerShell 把远端命令里的 `|`、`&&`、`$()` 等符号提前解析，导致 `grep` 等命令在本地执行。

典型表现：

- `Get-Content README.md` 读出乱码；
- 中文通过管道传给 `node` / `python` 后变成 `??`；
- agent 经常说 PowerShell 编码有问题；
- agent 不得不用 Unicode 转义绕过中文。

根因通常不是项目文件坏了，而是 Windows PowerShell 5.1 的默认编码和 native command pipe 行为太旧。

先运行：

```powershell
.\test-encoding.ps1
```

确认问题后运行：

```powershell
.\install.ps1
```

然后重新打开 PowerShell。

远端命令建议用：

```powershell
rbash user@server 'ps aux | grep node'
rbash user@server 'cd /app && git pull'
```
