<#
.SYNOPSIS
    Minecraft Bedrock Unlocker - PowerShell bootstrap.

.DESCRIPTION
    Small first-stage launcher for the release-hosted PowerShell installer.
    It asks the user to temporarily disable antivirus protection before the
    full payload is downloaded and executed.

    Usage: $u='https://github.com/CoelhoFZ/MinecraftBedrockUnlocker/releases/latest/download/install.ps1'; $h=@{'Cache-Control'='no-cache, no-store, max-age=0';'Pragma'='no-cache';'Expires'='0';'User-Agent'='MinecraftBedrockUnlocker'}; [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; $s=$null; 1..3|%{if([string]::IsNullOrWhiteSpace($s)){try{$r=irm -UseBasicParsing -Headers $h -Uri "${u}?cb=$([guid]::NewGuid())" -MaximumRedirection 5; $s=($r | Out-String)}catch{Start-Sleep -Seconds 1}}}; $t=if($s){$s.TrimStart()}else{''}; if([string]::IsNullOrWhiteSpace($s) -or $t.StartsWith('<!DOCTYPE',[StringComparison]::OrdinalIgnoreCase) -or $t.StartsWith('<html',[StringComparison]::OrdinalIgnoreCase)){throw 'install.ps1 download failed or returned invalid content'}; iex $s

.NOTES
    Author: CoelhoFZ
    Version: 3.1.4
    Repository: https://github.com/CoelhoFZ/MinecraftBedrockUnlocker
#>

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$Script:Version = '3.1.4'
$Script:RepoOwner = 'CoelhoFZ'
$Script:RepoName = 'MinecraftBedrockUnlocker'
$Script:BaseUrl = "https://github.com/$($Script:RepoOwner)/$($Script:RepoName)/releases/latest/download"
$Script:PayloadUrl = "$($Script:BaseUrl)/unlocker.ps1"
$Script:RawPayloadUrl = "https://raw.githubusercontent.com/$($Script:RepoOwner)/$($Script:RepoName)/v$($Script:Version)/unlocker.ps1"
$Script:PayloadSha256 = '1cca3a01fe7e07ac659f53f77870596a24c8b456407bb39eb5ad06a48f3d58f7'

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

function Set-NetworkDefaults {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls13
    } catch { }
    [Net.ServicePointManager]::Expect100Continue = $false
}

function Get-NoCacheHeaders {
    return @{
        'Cache-Control' = 'no-cache, no-store, max-age=0'
        'Pragma' = 'no-cache'
        'Expires' = '0'
        'User-Agent' = "MinecraftBedrockUnlocker/$($Script:Version)"
        'Accept' = 'text/plain,*/*'
    }
}

function Get-PayloadCandidateUrls {
    return @(
        $Script:PayloadUrl,
        $Script:RawPayloadUrl
    )
}

function Test-PayloadFile {
    param([Parameter(Mandatory=$true)][string]$Path)

    if (-not (Test-Path $Path)) {
        throw 'Payload file was not created.'
    }

    $payloadSize = (Get-Item $Path).Length
    if ($payloadSize -lt 100000) {
        throw "Payload download looks incomplete: $payloadSize bytes"
    }

    $payloadHead = Get-Content -Path $Path -TotalCount 40 -ErrorAction Stop | Out-String
    $payloadHeadTrimmed = $payloadHead.TrimStart()
    if ($payloadHeadTrimmed.StartsWith('<!DOCTYPE', [StringComparison]::OrdinalIgnoreCase) -or $payloadHeadTrimmed.StartsWith('<html', [StringComparison]::OrdinalIgnoreCase)) {
        throw 'Downloaded payload is an HTML error page.'
    }
    if ($payloadHead -notmatch 'Minecraft Bedrock Unlocker') {
        throw 'Downloaded payload is not the expected installer.'
    }

    if ($Script:PayloadSha256) {
        $actualHash = (Get-FileHash -Algorithm SHA256 -Path $Path -ErrorAction Stop).Hash.ToLowerInvariant()
        if ($actualHash -ne $Script:PayloadSha256.ToLowerInvariant()) {
            throw "Downloaded payload hash mismatch: $actualHash"
        }
    }

    return $true
}

function Invoke-FileDownload {
    param(
        [Parameter(Mandatory=$true)][string]$Url,
        [Parameter(Mandatory=$true)][string]$Destination
    )

    Set-NetworkDefaults
    $tmpPath = "$Destination.tmp"
    Remove-Item -Path $tmpPath -Force -ErrorAction SilentlyContinue
    $headers = Get-NoCacheHeaders
    $attemptErrors = New-Object System.Collections.Generic.List[string]

    for ($attempt = 1; $attempt -le 3; $attempt++) {
        try {
            Invoke-WebRequest -Uri (New-CacheBustedUrl $Url) -OutFile $tmpPath -UseBasicParsing -Headers $headers -MaximumRedirection 5 -DisableKeepAlive -ErrorAction Stop
            Test-PayloadFile -Path $tmpPath | Out-Null
            Move-Item -Path $tmpPath -Destination $Destination -Force
            return $true
        } catch {
            $attemptErrors.Add("Invoke-WebRequest#${attempt}: $($_.Exception.Message)") | Out-Null
            Remove-Item -Path $tmpPath -Force -ErrorAction SilentlyContinue
            Start-Sleep -Milliseconds (250 * $attempt)
        }
    }

    $client = $null
    try {
        $client = New-Object System.Net.WebClient
        foreach ($header in $headers.GetEnumerator()) { $client.Headers[$header.Key] = $header.Value }
        $client.DownloadFile((New-CacheBustedUrl $Url), $tmpPath)
        Test-PayloadFile -Path $tmpPath | Out-Null
        Move-Item -Path $tmpPath -Destination $Destination -Force
        return $true
    } catch {
        $attemptErrors.Add("WebClient: $($_.Exception.Message)") | Out-Null
        Remove-Item -Path $tmpPath -Force -ErrorAction SilentlyContinue
    } finally {
        if ($client) { $client.Dispose() }
    }

    $curl = Get-Command curl.exe -ErrorAction SilentlyContinue
    if ($curl -and $curl.Source) {
        try {
            & $curl.Source -fL -sS --retry 4 --retry-delay 2 --connect-timeout 15 --max-time 180 `
                -H 'Cache-Control: no-cache, no-store, max-age=0' `
                -H 'Pragma: no-cache' `
                -H "User-Agent: MinecraftBedrockUnlocker/$($Script:Version)" `
                -o $tmpPath (New-CacheBustedUrl $Url)
            if ($LASTEXITCODE -ne 0) { throw "curl.exe exited with code $LASTEXITCODE" }
            Test-PayloadFile -Path $tmpPath | Out-Null
            Move-Item -Path $tmpPath -Destination $Destination -Force
            return $true
        } catch {
            $attemptErrors.Add("curl.exe: $($_.Exception.Message)") | Out-Null
            Remove-Item -Path $tmpPath -Force -ErrorAction SilentlyContinue
        }
    } else {
        $attemptErrors.Add('curl.exe: not found') | Out-Null
    }

    throw ($attemptErrors -join ' | ')
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
    $tempRoot = Join-Path (Join-Path ([System.IO.Path]::GetTempPath()) 'MinecraftBedrockUnlocker') ([guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null

    $payloadPath = Join-Path $tempRoot "unlocker-$($Script:Version).ps1"
    $errors = New-Object System.Collections.Generic.List[string]

    foreach ($url in (Get-PayloadCandidateUrls)) {
        try {
            Invoke-FileDownload -Url $url -Destination $payloadPath | Out-Null
            return $payloadPath
        } catch {
            $errors.Add("$url => $($_.Exception.Message)") | Out-Null
            Remove-Item -Path $payloadPath -Force -ErrorAction SilentlyContinue
        }
    }

    throw "Payload download failed. $($errors -join ' || ')"
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
    $exitCode = 1
    try {
        & $powershellExe -NoProfile -ExecutionPolicy Bypass -File $payloadPath
        $exitCode = if ($LASTEXITCODE -is [int]) { $LASTEXITCODE } else { 0 }
    } finally {
        $payloadDir = Split-Path -Parent $payloadPath
        Remove-Item -Path $payloadDir -Recurse -Force -ErrorAction SilentlyContinue
    }
    exit $exitCode
}

Start-Bootstrap
