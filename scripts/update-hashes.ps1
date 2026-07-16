#Requires -Version 5.1
<#
.SYNOPSIS
    Recalcula SHA256SUMS.txt, atualiza versao e hashes em todos os scripts.
    Execute antes de cada release. VERSION e a unica fonte de verdade.
#>

$root = Split-Path $PSScriptRoot -Parent
Push-Location $root

# Ler versao da fonte unica
$version = (Get-Content VERSION).Trim()
Write-Host "Versao fonte: $version" -ForegroundColor Cyan

# Atualizar versao em diagnose.ps1
$diagContent = Get-Content diagnose.ps1 -Raw
$diagContent = $diagContent -replace "(?m)^\`$Script:Version = '.*'", "`$Script:Version = '$version'"
$diagContent = $diagContent -replace "Minecraft Bedrock Unlocker - diagnostic v[\d\.]+", "Minecraft Bedrock Unlocker - diagnostic v$version"
$diagContent = $diagContent -replace "Minecraft Bedrock Unlocker - diagn.stico v[\d\.]+", "Minecraft Bedrock Unlocker - diagnostico v$version"
$diagContent = $diagContent -replace "Minecraft Bedrock Unlocker - .?diagnostic v[\d\.]+", "Minecraft Bedrock Unlocker - diagnostic v$version"
$diagContent | Set-Content diagnose.ps1 -Encoding UTF8 -NoNewline
Write-Host "  diagnose.ps1: versao atualizada para $version" -ForegroundColor Green

# Atualizar versao em bootstrap-v3.2.0.ps1
$bsContent = Get-Content bootstrap-v3.2.0.ps1 -Raw
$bsContent = $bsContent -replace "(?m)^\`$Script:Version = '.*'", "`$Script:Version = '$version'"
$bsContent = $bsContent -replace "bootstrap v[\d\.]+", "bootstrap v$version"
$bsContent = $bsContent -replace "Version:\s+[\d\.]+", "Version:        $version"
$bsContent | Set-Content bootstrap-v3.2.0.ps1 -Encoding UTF8 -NoNewline
Write-Host "  bootstrap-v3.2.0.ps1: versao atualizada para $version" -ForegroundColor Green

# Atualizar versao em app.manifest (para quando nao usa build.sh)
$manifestContent = Get-Content build/app.manifest -Raw
$manifestContent = $manifestContent -replace "\d+\.\d+\.\d+\.0", "$version.0"
$manifestContent | Set-Content build/app.manifest -Encoding UTF8 -NoNewline
Write-Host "  build/app.manifest: versao atualizada para $version.0" -ForegroundColor Green

# Recalcula hashes
$files = @('unlocker.ps1','install.ps1','i.ps1','bootstrap-v3.2.0.ps1','diagnose.ps1')
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

(Get-Content install.ps1 -Raw) `
    -replace '(?m)^# unlocker\.ps1 hash post-BOM-strip \(.*\)', "# unlocker.ps1 hash post-BOM-strip (v$version)" `
    -replace "(?m)^\`$Script:PayloadSha256 = '.*'", "`$Script:PayloadSha256 = '$unlockerHash'" |
    Set-Content install.ps1 -Encoding UTF8 -NoNewline

Write-Host "SHA256SUMS.txt e install.ps1 atualizados para v$version" -ForegroundColor Green
Write-Host "Fonte unica: VERSION ($version)" -ForegroundColor Cyan

Pop-Location
