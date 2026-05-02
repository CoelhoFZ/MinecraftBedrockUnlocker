<#
.SYNOPSIS
    Minecraft Bedrock Unlocker - PowerShell bootstrap.

.DESCRIPTION
    Small first-stage launcher for the release-hosted PowerShell installer.
    It asks the user to temporarily disable antivirus protection before the
    full payload is downloaded and executed.

    Usage: $u='https://github.com/CoelhoFZ/MinecraftBedrockUnlocker/releases/latest/download/install.ps1'; [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; $s=irm -UseBasicParsing -Headers @{'Cache-Control'='no-cache';'Pragma'='no-cache'} -Uri "${u}?cb=$([guid]::NewGuid())"; if([string]::IsNullOrWhiteSpace($s)){throw 'install.ps1 download returned empty content'}; iex $s

.NOTES
    Author: CoelhoFZ
    Version: 3.1.2
    Repository: https://github.com/CoelhoFZ/MinecraftBedrockUnlocker
#>

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$Script:Version = '3.1.2'
$Script:RepoOwner = 'CoelhoFZ'
$Script:RepoName = 'MinecraftBedrockUnlocker'
$Script:BaseUrl = "https://github.com/$($Script:RepoOwner)/$($Script:RepoName)/releases/latest/download"
$Script:PayloadUrl = "$($Script:BaseUrl)/unlocker.ps1"

function Write-Status {
    param(
        [string]$Message,
        [ConsoleColor]$Color = [ConsoleColor]::White
    )

    try {
        Write-Host $Message -ForegroundColor $Color
    } catch {
        Write-Output $Message
    }
}

function Wait-AnyKey {
    Write-Status ''
    Write-Status 'Desabilite o seu antivirus antes de executar, quando desabilitar, pressione qualquer tecla para continuar' ([ConsoleColor]::Yellow)
    Write-Status ''

    try {
        if ($Host -and $Host.UI -and $Host.UI.RawUI) {
            $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
            return
        }
    } catch { }

    $null = Read-Host 'Pressione ENTER para continuar'
}

function New-CacheBustedUrl {
    param([Parameter(Mandatory=$true)][string]$Url)

    $separator = if ($Url.Contains('?')) { '&' } else { '?' }
    return ('{0}{1}cb={2}' -f $Url, $separator, [guid]::NewGuid().ToString('N'))
}

function Get-NoCacheHeaders {
    return @{
        'Cache-Control' = 'no-cache'
        'Pragma' = 'no-cache'
    }
}

function Get-PowerShellExe {
    $cmd = Get-Command powershell.exe -ErrorAction SilentlyContinue
    if ($cmd -and $cmd.Source) {
        return $cmd.Source
    }

    $windowsPowerShell = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
    if (Test-Path $windowsPowerShell) {
        return $windowsPowerShell
    }

    throw 'powershell.exe not found.'
}

function Download-Payload {
    $tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) 'MinecraftBedrockUnlocker'
    New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null

    $payloadPath = Join-Path $tempRoot "unlocker-$($Script:Version).ps1"

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    try {
        Invoke-WebRequest -Uri (New-CacheBustedUrl $Script:PayloadUrl) -OutFile $payloadPath -UseBasicParsing -Headers (Get-NoCacheHeaders) -ErrorAction Stop
    } catch {
        try {
            $client = New-Object System.Net.WebClient
            $client.Headers.Add('Cache-Control', 'no-cache')
            $client.Headers.Add('Pragma', 'no-cache')
            $client.DownloadFile((New-CacheBustedUrl $Script:PayloadUrl), $payloadPath)
        } finally {
            if ($client) { $client.Dispose() }
        }
    }

    if (-not (Test-Path $payloadPath)) {
        throw "Payload download failed: $($Script:PayloadUrl)"
    }

    $payloadSize = (Get-Item $payloadPath).Length
    if ($payloadSize -lt 100000) {
        throw "Payload download looks incomplete: $payloadSize bytes"
    }

    $payloadHead = Get-Content -Path $payloadPath -TotalCount 30 -ErrorAction Stop | Out-String
    if ($payloadHead -notmatch 'Minecraft Bedrock Unlocker') {
        throw 'Downloaded payload is not the expected installer.'
    }

    return $payloadPath
}

function Start-Bootstrap {
    Clear-Host -ErrorAction SilentlyContinue
    Write-Status '============================================================' ([ConsoleColor]::Cyan)
    Write-Status ' Minecraft Bedrock Unlocker' ([ConsoleColor]::Cyan)
    Write-Status " v$($Script:Version) bootstrap" ([ConsoleColor]::DarkGray)
    Write-Status '============================================================' ([ConsoleColor]::Cyan)

    Wait-AnyKey

    Write-Status ''
    Write-Status 'Baixando instalador completo...' ([ConsoleColor]::Cyan)
    $payloadPath = Download-Payload
    Write-Status 'Instalador baixado. Iniciando...' ([ConsoleColor]::Green)
    Write-Status ''

    $powershellExe = Get-PowerShellExe
    & $powershellExe -NoProfile -ExecutionPolicy Bypass -File $payloadPath
    $exitCode = if ($LASTEXITCODE -is [int]) { $LASTEXITCODE } else { 0 }
    exit $exitCode
}

Start-Bootstrap
