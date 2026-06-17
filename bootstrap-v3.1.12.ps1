<#
.SYNOPSIS
  Minecraft Bedrock Unlocker v3.1.12 - Unified bootstrap (PowerShell).

.DESCRIPTION
  v3.1.12 consolidates install.ps1 + e.ps1 + i.ps1 into a single bootstrap.
  Why this exists: v3.1.11 on GitHub release ships only MinecraftBedrockUnlocker.exe
  as a release asset. The PowerShell installers (install.ps1, unlocker.ps1) reference
  multiple release-hosted assets (winmm.dll, OnlineFix64.dll, dlllist.txt, etc.) that
  return HTTP 404. This bootstrap:

    1. Detects Windows + PowerShell 5.1+ (WinPS) or PowerShell 7+ (Core).
    2. Downloads MinecraftBedrockUnlocker.exe from the latest CoelhoFZ release.
    3. Verifies the EXE is a valid PE32+ binary (size + MZ header + .NET assembly).
    4. Optionally verifies SHA256 against SHA256SUMS.txt when reachable.
    5. Launches the EXE as Administrator (UAC prompt).
    6. Falls back to running unlocker.ps1 from raw/main if the EXE fails to launch.

  This bootstrap is NOT a replacement for the CoelhoFZ/Gustavo upstream installer.
  It only fixes the broken PowerShell bootstrap path. The EXE wrapper
  (Online-Fix GDK Client, ProductVersion 1.0.4.0) is unchanged.

.PARAMETER SkipExe
  Skip the EXE download and use the unlocker.ps1 fallback path only.

.PARAMETER UseRawMain
  Fetch unlocker.ps1 from raw/main instead of the release. Useful for testing.

.PARAMETER Lang
  Force UI language: 'en' or 'pt'. Defaults to OS culture detection.

.EXAMPLE
  iex (irm 'https://raw.githubusercontent.com/CoelhoFZ/MinecraftBedrockUnlocker/main/bootstrap-v3.1.12.ps1')

.EXAMPLE
  .\bootstrap-v3.1.12.ps1 -SkipExe

.NOTES
  Version: 3.1.12
  Author: CoelhoFZ + Gustavo (CoelhoFZ Community)
  License: GPLv3 (this script only; bundled Online-Fix binaries retain their own license).
#>

[CmdletBinding()]
param(
    [switch]$SkipExe,
    [switch]$UseRawMain,
    [ValidateSet('auto','en','pt')]
    [string]$Lang = 'auto'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

$Script:Version = '3.1.12'
$Script:RepoOwner = 'CoelhoFZ'
$Script:RepoName  = 'MinecraftBedrockUnlocker'
$Script:ExeName   = 'MinecraftBedrockUnlocker.exe'

$Script:ReleaseExeUrl  = "https://github.com/$($Script:RepoOwner)/$($Script:RepoName)/releases/latest/download/$($Script:ExeName)"
$Script:RawMainExeUrl  = "https://raw.githubusercontent.com/$($Script:RepoOwner)/$($Script:RepoName)/main/$($Script:ExeName)"
$Script:ReleaseFallbackUrl = "https://github.com/$($Script:RepoOwner)/$($Script:RepoName)/releases/latest/download"
$Script:RawMainUrl     = "https://raw.githubusercontent.com/$($Script:RepoOwner)/$($Script:RepoName)/main"
$Script:Sha256SumsUrl  = "$($Script:RawMainUrl)/SHA256SUMS.txt"

# ---------------------------------------------------------------------------
# i18n
# ---------------------------------------------------------------------------

function Detect-Lang {
    if ($Lang -ne 'auto') { return $Lang }
    try {
        $c = (Get-Culture).Name
        if ($c -like 'pt-*') { return 'pt' }
    } catch { }
    return 'en'
}

function T {
    param([string]$Key)
    $lang = Detect-Lang
    $table = @{
        en = @{
            'banner'           = 'Minecraft Bedrock Unlocker - bootstrap v3.1.12'
            'detecting_os'     = 'Detecting platform...'
            'os_unsupported'   = 'This bootstrap requires Windows.'
            'ps_unsupported'   = 'PowerShell 5.1 or newer is required (you have {0}).'
            'downloading_exe'  = 'Downloading {0} from {1}...'
            'verify_pe'        = 'Verifying EXE signature (PE32+ MZ header)...'
            'verify_sha'       = 'Verifying SHA256 against SHA256SUMS.txt...'
            'sha_match'        = 'SHA256 OK.'
            'sha_mismatch'     = 'SHA256 mismatch. Expected {0}, got {1}.'
            'sha_skip'         = 'SHA256SUMS.txt unavailable; skipping hash check.'
            'launching_admin'  = 'Launching {0} as Administrator (UAC prompt)...'
            'fallback_header'  = 'EXE failed to launch. Falling back to unlocker.ps1 from raw/main...'
            'downloading_ps1'  = 'Downloading unlocker.ps1 from {0}...'
            'verify_ps1'       = 'Verifying unlocker.ps1 (size + content-type)...'
            'running_ps1'      = 'Running unlocker.ps1 with PowerShell...'
            'all_failed'       = 'All attempts failed. Possible causes:'
            'cause_internet'   = '  1. No internet connection or GitHub is unreachable'
            'cause_av'         = '  2. Antivirus blocked the download'
            'cause_release'    = '  3. GitHub release assets are temporarily unavailable'
            'cause_local'      = '  4. Local PowerShell cannot elevate to Administrator'
            'suggestion'       = 'Suggestions:'
            'suggest_disable_av' = '  - Temporarily disable real-time antivirus protection'
            'suggest_wait'     = '  - Wait a few minutes and retry (GitHub may be rate-limiting)'
            'suggest_release'  = '  - Open https://github.com/{0}/{1}/releases and download the EXE manually'
            'enter_to_exit'    = 'Press ENTER to exit'
            'press_enter_pt'   = 'Pressione ENTER para sair'
        }
        pt = @{
            'banner'           = 'Minecraft Bedrock Unlocker - bootstrap v3.1.12'
            'detecting_os'     = 'Detectando plataforma...'
            'os_unsupported'   = 'Este bootstrap requer Windows.'
            'ps_unsupported'   = 'PowerShell 5.1 ou superior e necessario (voce tem {0}).'
            'downloading_exe'  = 'Baixando {0} de {1}...'
            'verify_pe'        = 'Verificando assinatura do EXE (PE32+ MZ header)...'
            'verify_sha'       = 'Verificando SHA256 contra SHA256SUMS.txt...'
            'sha_match'        = 'SHA256 OK.'
            'sha_mismatch'     = 'SHA256 nao confere. Esperado {0}, obtido {1}.'
            'sha_skip'         = 'SHA256SUMS.txt indisponivel; pulando verificacao.'
            'launching_admin'  = 'Iniciando {0} como Administrador (prompt UAC)...'
            'fallback_header'  = 'EXE falhou ao iniciar. Caindo pro unlocker.ps1 via raw/main...'
            'downloading_ps1'  = 'Baixando unlocker.ps1 de {0}...'
            'verify_ps1'       = 'Verificando unlocker.ps1 (tamanho + content-type)...'
            'running_ps1'      = 'Rodando unlocker.ps1 com PowerShell...'
            'all_failed'       = 'Todas as tentativas falharam. Causas possiveis:'
            'cause_internet'   = '  1. Sem conexao de internet ou GitHub inacessivel'
            'cause_av'         = '  2. Antivírus bloqueou o download'
            'cause_release'    = '  3. Assets do release estao temporariamente indisponiveis'
            'cause_local'      = '  4. PowerShell local nao consegue elevar pra Administrador'
            'suggestion'       = 'Sugestoes:'
            'suggest_disable_av' = '  - Desative temporariamente a protecao em tempo real do antivírus'
            'suggest_wait'     = '  - Aguarde alguns minutos e tente de novo (GitHub pode estar limitando)'
            'suggest_release'  = '  - Abra https://github.com/{0}/{1}/releases e baixe o EXE manualmente'
            'enter_to_exit'    = 'Press ENTER to exit'
            'press_enter_pt'   = 'Pressione ENTER para sair'
        }
    }
    $fmt = $table[$lang][$Key]
    if (-not $fmt) { return $Key }
    return $fmt
}

function Write-Banner {
    Write-Host ''
    Write-Host '============================================================' -ForegroundColor Cyan
    Write-Host (' ' + (T 'banner')) -ForegroundColor Cyan
    Write-Host '============================================================' -ForegroundColor Cyan
    Write-Host ''
}

function Write-Info {
    param([string]$Msg)
    Write-Host "[v3.1.12] $Msg"
}

function Write-Err {
    param([string]$Msg)
    Write-Host "[v3.1.12][ERROR] $Msg" -ForegroundColor Red
}

function Write-Warn {
    param([string]$Msg)
    Write-Host "[v3.1.12][WARN] $Msg" -ForegroundColor Yellow
}

function Write-OK {
    param([string]$Msg)
    Write-Host "[v3.1.12][OK] $Msg" -ForegroundColor Green
}

# ---------------------------------------------------------------------------
# Network helpers
# ---------------------------------------------------------------------------

function Get-DownloadFolder {
    # Use TEMP: Windows Defender is less aggressive there, and we add it to exclusions below.
    $tempParent = Join-Path ([System.IO.Path]::GetTempPath()) 'MinecraftBedrockUnlocker'
    if (-not (Test-Path -LiteralPath $tempParent)) {
        New-Item -ItemType Directory -Path $tempParent -Force | Out-Null
    }
    try { Add-MpPreference -ExclusionPath $tempParent -ErrorAction SilentlyContinue } catch { }
    return $tempParent
}

function Get-NoCacheHeaders {
    return @{
        'Cache-Control' = 'no-cache, no-store, max-age=0'
        'Pragma'        = 'no-cache'
        'Expires'       = '0'
        'User-Agent'    = "MinecraftBedrockUnlockerBootstrap/$($Script:Version)"
        'Accept'        = '*/*'
    }
}

function New-CacheBustedUrl {
    param([Parameter(Mandatory=$true)][string]$Url)
    $sep = if ($Url.Contains('?')) { '&' } else { '?' }
    return ('{0}{1}cb={2}' -f $Url, $sep, [guid]::NewGuid().ToString('N'))
}

function Invoke-HttpGet {
    param(
        [Parameter(Mandatory=$true)][string]$Url,
        [string]$OutFile,
        [int]$TimeoutSec = 180,
        [int]$MaxRedirection = 5
    )
    $h = Get-NoCacheHeaders
    $u = New-CacheBustedUrl $Url
    $args = @{
        Uri         = $u
        Headers     = $h
        UseBasicParsing = $true
        MaximumRedirection = $MaxRedirection
        TimeoutSec  = $TimeoutSec
    }
    if ($OutFile) { $args.OutFile = $OutFile }
    return Invoke-WebRequest @args
}

function Test-UrlReachable {
    param([Parameter(Mandatory=$true)][string]$Url)
    try {
        $r = Invoke-HttpGet -Url $Url -TimeoutSec 15 -MaximumRedirection 5
        return ($r.StatusCode -ge 200 -and $r.StatusCode -lt 400)
    } catch {
        return $false
    }
}

# ---------------------------------------------------------------------------
# Verification helpers
# ---------------------------------------------------------------------------

function Test-PeSignature {
    param([Parameter(Mandatory=$true)][string]$Path)
    $stream = [System.IO.File]::Open($Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
    try {
        if ($stream.Length -lt 2) { return $false }
        $header = New-Object byte[] 2
        $read = $stream.Read($header, 0, $header.Length)
        return ($read -eq 2 -and $header[0] -eq 0x4d -and $header[1] -eq 0x5a)
    } finally {
        $stream.Dispose()
    }
}

function Get-FileSha256Hex {
    param([Parameter(Mandatory=$true)][string]$Path)
    try {
        $sha = [System.Security.Cryptography.SHA256]::Create()
        $stream = [System.IO.File]::OpenRead($Path)
        try {
            $hashBytes = $sha.ComputeHash($stream)
            return -join ($hashBytes | ForEach-Object { $_.ToString('x2') })
        } finally {
            $stream.Dispose()
            $sha.Dispose()
        }
    } catch {
        return $null
    }
}

function Get-Sha256FromSumsFile {
    param(
        [Parameter(Mandatory=$true)][string]$Path,
        [Parameter(Mandatory=$true)][string]$FileName
    )
    if (-not (Test-Path -LiteralPath $Path)) { return $null }
    $line = Get-Content -LiteralPath $Path | Where-Object { $_ -match ("\s{0}$" -f [regex]::Escape($FileName)) } | Select-Object -First 1
    if (-not $line) { return $null }
    $parts = $line.Trim() -split '\s+', 2
    if ($parts.Count -lt 2) { return $null }
    return $parts[0].ToLowerInvariant()
}

function Test-PsScriptHeader {
    param([Parameter(Mandatory=$true)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return $false }
    $size = (Get-Item -LiteralPath $Path).Length
    if ($size -lt 10000) { return $false }   # unlocker.ps1 is ~190KB
    try {
        $head = Get-Content -LiteralPath $Path -TotalCount 5 -ErrorAction Stop | Out-String
        $trim = $head.TrimStart()
        return ($trim.StartsWith('<#') -or $trim.StartsWith('#') -or $trim.StartsWith('param('))
    } catch {
        return $false
    }
}

# ---------------------------------------------------------------------------
# Main flow
# ---------------------------------------------------------------------------

function Start-Bootstrap {
    Write-Banner

    # 1. OS check
    Write-Info (T 'detecting_os')
    if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) {
        Write-Err (T 'os_unsupported')
        exit 2
    }

    # 2. PowerShell version check
    $psv = $PSVersionTable.PSVersion
    if ($psv.Major -lt 5) {
        Write-Err ((T 'ps_unsupported') -f $psv.ToString())
        exit 2
    }
    Write-OK "PowerShell $($psv.ToString()) on Windows."

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls13
    } catch { }
    [Net.ServicePointManager]::Expect100Continue = $false

    $tempParent = Get-DownloadFolder
    $runFolder = Join-Path $tempParent ([guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $runFolder -Force | Out-Null

    $exePath = Join-Path $runFolder $Script:ExeName

    # 3. Download EXE (skip if -SkipExe)
    if (-not $SkipExe) {
        $urlsToTry = @($Script:ReleaseExeUrl, $Script:RawMainExeUrl)
        $downloaded = $false
        $lastError = $null

        foreach ($url in $urlsToTry) {
            try {
                Write-Info ((T 'downloading_exe') -f $Script:ExeName, $url)
                if (Test-Path -LiteralPath $exePath) {
                    Remove-Item -LiteralPath $exePath -Force -ErrorAction SilentlyContinue
                }
                Invoke-HttpGet -Url $url -OutFile $exePath -TimeoutSec 240 | Out-Null
                $item = Get-Item -LiteralPath $exePath
                if ($item.Length -lt 5000000) {
                    throw "Download is too small ($($item.Length) bytes). Expected >= 5MB."
                }
                Write-Info (T 'verify_pe')
                if (-not (Test-PeSignature -Path $exePath)) {
                    throw 'Downloaded file is not a valid Windows executable (MZ header missing).'
                }
                Write-OK "EXE downloaded ($([math]::Round($item.Length/1MB,2)) MB) and PE signature OK."

                # 4. SHA256 verify (best-effort)
                Write-Info (T 'verify_sha')
                try {
                    $sumsTmp = Join-Path $runFolder 'SHA256SUMS.txt'
                    Invoke-HttpGet -Url $Script:Sha256SumsUrl -OutFile $sumsTmp -TimeoutSec 30 | Out-Null
                    $expected = Get-Sha256FromSumsFile -Path $sumsTmp -FileName $Script:ExeName
                    if ($expected) {
                        $actual = Get-FileSha256Hex -Path $exePath
                        if ($actual -eq $expected) {
                            Write-OK (T 'sha_match')
                        } else {
                            Write-Warn ((T 'sha_mismatch') -f $expected, $actual)
                        }
                    } else {
                        Write-Warn (T 'sha_skip')
                    }
                } catch {
                    Write-Warn (T 'sha_skip')
                }

                # 5. Launch as Administrator
                Write-Info ((T 'launching_admin') -f $Script:ExeName)
                try {
                    $proc = Start-Process -FilePath $exePath -Verb RunAs -PassThru
                    if ($proc) {
                        Write-OK "EXE launched (PID $($proc.Id)). Bootstrap exiting successfully."
                        exit 0
                    } else {
                        throw 'Start-Process returned no process.'
                    }
                } catch {
                    $lastError = $_
                    Write-Warn "EXE launch failed: $($_.Exception.Message)"
                }
            } catch {
                $lastError = $_
                Write-Warn "Download from $url failed: $($_.Exception.Message)"
                continue
            }
        }

        # If we reach here, EXE path failed entirely.
        Write-Err (T 'fallback_header')
    }

    # 6. Fallback: run unlocker.ps1
    # v3.1.12: try release first, then raw/main automatically. The CoelhoFZ
    # release often ships only the EXE, so raw/main is the reliable source.
    $ps1Candidates = @(
        "$($Script:ReleaseFallbackUrl)/unlocker.ps1",
        "$($Script:RawMainUrl)/unlocker.ps1"
    )
    if ($UseRawMain) {
        $ps1Candidates = @("$($Script:RawMainUrl)/unlocker.ps1")
    }
    $ps1Downloaded = $false
    $ps1LastError = $null
    foreach ($ps1Url in $ps1Candidates) {
        try {
            Write-Info ((T 'downloading_ps1') -f $ps1Url)
            $ps1Path = Join-Path $runFolder 'unlocker.ps1'
            if (Test-Path -LiteralPath $ps1Path) {
                Remove-Item -LiteralPath $ps1Path -Force -ErrorAction SilentlyContinue
            }
            Invoke-HttpGet -Url $ps1Url -OutFile $ps1Path -TimeoutSec 120 | Out-Null
            Write-Info (T 'verify_ps1')
            if (-not (Test-PsScriptHeader -Path $ps1Path)) {
                throw "Downloaded unlocker.ps1 looks invalid (size=$(if (Test-Path -LiteralPath $ps1Path) { (Get-Item -LiteralPath $ps1Path).Length } else { 0 }))."
            }
            Write-OK "unlocker.ps1 downloaded from $ps1Url and looks valid."
            $ps1Downloaded = $true
            $finalPs1Path = $ps1Path
            break
        } catch {
            $ps1LastError = $_
            Write-Warn "Download from $ps1Url failed: $($_.Exception.Message)"
            continue
        }
    }

    if ($ps1Downloaded) {
        Write-Info (T 'running_ps1')
        try {
            # Use Start-Process without -Wait so the bootstrap can return immediately
            # (the unlocker.ps1 is interactive and needs its own console).
            Start-Process -FilePath $finalPs1Path -Verb RunAs
            Write-OK "unlocker.ps1 launched (it will run in its own Administrator window)."
            exit 0
        } catch {
            Write-Err "Failed to launch unlocker.ps1: $($_.Exception.Message)"
        }
    } else {
        Write-Err "All unlocker.ps1 download attempts failed."
        if ($ps1LastError) { Write-Err "Last error: $($ps1LastError.Exception.Message)" }
    }

    # 7. Final error message with troubleshooting hints
    Write-Host ''
    Write-Host '============================================================' -ForegroundColor Red
    Write-Host '[v3.1.12] ' (T 'all_failed') -ForegroundColor Red
    Write-Host (T 'cause_internet')  -ForegroundColor Yellow
    Write-Host (T 'cause_av')        -ForegroundColor Yellow
    Write-Host (T 'cause_release')   -ForegroundColor Yellow
    Write-Host (T 'cause_local')     -ForegroundColor Yellow
    Write-Host ''
    Write-Host (T 'suggestion') -ForegroundColor Cyan
    Write-Host (T 'suggest_disable_av') -ForegroundColor White
    Write-Host (T 'suggest_wait')       -ForegroundColor White
    Write-Host ((T 'suggest_release') -f $Script:RepoOwner, $Script:RepoName) -ForegroundColor White
    Write-Host '============================================================' -ForegroundColor Red
    Write-Host ''
    # Skip Read-Host in non-interactive contexts (SSH, scheduled tasks, CI).
    if ($Host.Name -ne 'ServerHost' -and $Host.UI.RawUI) {
        if ((Detect-Lang) -eq 'pt') {
            Read-Host (T 'press_enter_pt')
        } else {
            Read-Host (T 'enter_to_exit')
        }
    }
    exit 1
}

# ---------------------------------------------------------------------------
# Entry
# ---------------------------------------------------------------------------

try {
    Start-Bootstrap
} catch {
    Write-Host ''
    Write-Host '============================================================' -ForegroundColor Red
    Write-Host '[v3.1.12] FATAL: ' $_.Exception.Message -ForegroundColor Red
    Write-Host '============================================================' -ForegroundColor Red
    Write-Host ''
    if ($Host.Name -ne 'ServerHost' -and $Host.UI.RawUI) {
        if ((Detect-Lang) -eq 'pt') {
            Read-Host (T 'press_enter_pt')
        } else {
            Read-Host (T 'enter_to_exit')
        }
    }
    exit 1
}