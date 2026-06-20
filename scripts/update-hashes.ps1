#Requires -Version 5.1
<#
.SYNOPSIS
    Recalcula SHA256SUMS.txt e atualiza $PayloadSha256 em install.ps1.
    Execute antes de cada release.
#>

$root = Split-Path $PSScriptRoot -Parent
Push-Location $root

$files = @('unlocker.ps1','install.ps1','e.ps1','i.ps1','bootstrap-v3.2.0.ps1','diagnose.ps1')

# Recalcula hashes
$lines = @()

$exeLine = (Get-Content SHA256SUMS.txt | Where-Object { $_ -match '\.exe\s*$' } | Select-Object -First 1)
if ($exeLine) { $lines += $exeLine }

foreach ($f in $files) {
    if (Test-Path $f) {
        $hash = (Get-FileHash -Algorithm SHA256 $f).Hash.ToLowerInvariant()
        $lines += "$hash  $f"
    }
}

$lines | Set-Content SHA256SUMS.txt -Encoding UTF8

# Atualiza $PayloadSha256 em install.ps1
$unlockerHash = (Get-FileHash -Algorithm SHA256 unlocker.ps1).Hash.ToLowerInvariant()
$version = (Get-Content VERSION).Trim()

(Get-Content install.ps1 -Raw) `
    -replace '(?m)^# unlocker\.ps1 hash post-BOM-strip \(.*\)', "# unlocker.ps1 hash post-BOM-strip (v$version)" `
    -replace "(?m)^\`$Script:PayloadSha256 = '.*'", "`$Script:PayloadSha256 = '$unlockerHash'" |
    Set-Content install.ps1 -Encoding UTF8 -NoNewline

Write-Host "SHA256SUMS.txt e install.ps1 atualizados para v$version" -ForegroundColor Green

Pop-Location
