# Nile for Windows (beta) — one-line install:  irm https://haozhuang479.github.io/get-nile/install.ps1 | iex
$ErrorActionPreference = 'Stop'
$repo = if ($env:NILE_REPO) { $env:NILE_REPO } else { 'Haozhuang479/get-nile' }
$root = Join-Path $env:LOCALAPPDATA 'Programs'
$dest = Join-Path $root 'Nile'
Write-Host "`nNile for Windows (beta)" -ForegroundColor Cyan
$codex  = Get-Command codex  -ErrorAction SilentlyContinue
$claude = Get-Command claude -ErrorAction SilentlyContinue
$node   = Get-Command node   -ErrorAction SilentlyContinue
Write-Host ("  Codex        " + $(if ($codex)  { $codex.Source }  else { 'not found' }))
Write-Host ("  Claude Code  " + $(if ($claude) { $claude.Source } else { 'not found' }))
Write-Host ("  Node         " + $(if ($node)   { $node.Source }   else { 'not found - install from https://nodejs.org (Nile needs it to talk to your agent)' }))
if (-not $codex -and -not $claude) { Write-Host "  No agent found. Install Codex (npm i -g @openai/codex) or Claude Code (https://claude.ai/code), then run this again." }

Write-Host "`nDownloading Nile..."
$zip = Join-Path $env:TEMP 'Nile-win-x64.zip'
Invoke-WebRequest -Uri "https://github.com/$repo/releases/latest/download/Nile-win-x64.zip" -OutFile $zip
Get-Process Nile -ErrorAction SilentlyContinue | Stop-Process -Force
if (Test-Path $dest) { Remove-Item $dest -Recurse -Force }
New-Item -ItemType Directory -Force $root | Out-Null
Expand-Archive -Path $zip -DestinationPath $root -Force
Get-ChildItem $dest -Recurse | Unblock-File -ErrorAction SilentlyContinue

$sm = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\Nile.lnk'
$sc = (New-Object -ComObject WScript.Shell).CreateShortcut($sm); $sc.TargetPath = Join-Path $dest 'Nile.exe'; $sc.WorkingDirectory = $dest; $sc.Save()

$mcp = Join-Path $dest 'resources\app\mcp\server.mjs'
if ($node) {
  if ($codex)  { & codex mcp remove nile-pro 2>$null; & codex mcp add nile-pro -- node $mcp | Out-Null; Write-Host "  Codex: Nile window control registered" }
  if ($claude) { & claude mcp remove -s user nile-pro 2>$null; & claude mcp add -s user nile-pro -- node $mcp | Out-Null; Write-Host "  Claude Code: Nile window control registered" }
}
Start-Process (Join-Path $dest 'Nile.exe')
Write-Host "`nDone. Nile is in $dest (Start Menu > Nile). Setup inside the app: Agent > Data > Test drive > Payment > Tour." -ForegroundColor Green
