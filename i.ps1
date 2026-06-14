$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

trap {
    Write-Host ''
    Write-Host '============================================================' -ForegroundColor Red
    Write-Host '[MBU] ERROR:' $_.Exception.Message -ForegroundColor Red
    Write-Host '============================================================' -ForegroundColor Red
    Write-Host ''
    Write-Host 'The bootstrap failed. Possible causes:' -ForegroundColor Yellow
    Write-Host '  1. No internet connection or GitHub is unreachable' -ForegroundColor Yellow
    Write-Host '  2. Antivirus blocked the download' -ForegroundColor Yellow
    Write-Host '  3. The release asset was not found (try again later)' -ForegroundColor Yellow
    Write-Host ''
    Read-Host 'Press ENTER to exit'
    break
}

if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) {
    throw 'MinecraftBedrockUnlocker.exe must be run on Windows.'
}

$ReleaseBase = 'https://github.com/CoelhoFZ/MinecraftBedrockUnlocker/releases/latest/download'
$Headers = @{
    'Cache-Control' = 'no-cache, no-store, max-age=0'
    'Pragma' = 'no-cache'
    'Expires' = '0'
    'User-Agent' = 'MinecraftBedrockUnlockerShortExe'
}

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function Get-DownloadFolder {
    # Use TEMP instead of Downloads: Windows Defender is less aggressive scanning temp files,
    # and the EXE already adds %TEMP%\MinecraftBedrockUnlocker to Defender exclusions.
    $tempParent = Join-Path ([System.IO.Path]::GetTempPath()) 'MinecraftBedrockUnlocker'
    if (-not (Test-Path -LiteralPath $tempParent)) {
        New-Item -ItemType Directory -Path $tempParent -Force | Out-Null
    }
    # Best-effort: try to add Defender exclusion (may fail if not admin - that's OK)
    try { Add-MpPreference -ExclusionPath $tempParent -ErrorAction SilentlyContinue } catch { }
    return $tempParent
}

$lastError = $null
$downloadFolder = Get-DownloadFolder
$exePath = Join-Path $downloadFolder 'MinecraftBedrockUnlocker.exe'

for ($attempt = 1; $attempt -le 3; $attempt++) {
    try {
        $url = "$ReleaseBase/MinecraftBedrockUnlocker.exe`?cb=$([guid]::NewGuid().ToString('N'))"
        Write-Host "[MBU] Downloading MinecraftBedrockUnlocker.exe to $exePath..."
        Invoke-WebRequest -UseBasicParsing -Headers $Headers -Uri $url -MaximumRedirection 5 -OutFile $exePath
        if (-not (Test-Path -LiteralPath $exePath)) { throw 'EXE was not saved' }
        $item = Get-Item -LiteralPath $exePath
        if ($item.Length -lt 5000000) { throw "Download is too small ($($item.Length) bytes)" }
        $headBytes = [System.IO.File]::ReadAllBytes($exePath)
        if ($headBytes.Length -ge 2 -and $headBytes[0] -eq 0x4d -and $headBytes[1] -eq 0x5a) {
            Write-Host '[MBU] EXE verified (PE signature OK). Starting as Administrator...'
            Start-Process -FilePath $exePath -Verb RunAs
            exit 0
        }
        throw 'Downloaded file is not a valid Windows executable'
    } catch {
        $lastError = $_
        Start-Sleep -Seconds $attempt
    }
}
Write-Host ''
Write-Host '============================================================' -ForegroundColor Red
Write-Host '[MBU] All download attempts failed.' -ForegroundColor Red
if ($lastError) {
    $errMsg = $lastError.Exception.Message
    Write-Host "[MBU] Last error: $errMsg" -ForegroundColor Red
}
Write-Host '============================================================' -ForegroundColor Red
Write-Host ''
if ($lastError -and $errMsg -match 'v.rus|software.*indesej|unwanted|potentially|acesso negado|access.*denied|opera..o.*v.lida') {
    Write-Host 'WINDOWS DEFENDER IS BLOCKING THE FILE!' -ForegroundColor Red
    Write-Host 'The file was downloaded but Windows Defender blocked access to it.' -ForegroundColor Yellow
    Write-Host ''
    Write-Host 'QUICK FIX - Run this command as Administrator, then try again:' -ForegroundColor Cyan
    Write-Host '  Add-MpPreference -ExclusionPath "$downloadFolder"' -ForegroundColor White
    Write-Host ''
    Write-Host 'OR: Temporarily disable Real-time protection in Windows Security,' -ForegroundColor Yellow
    Write-Host '     run this script, then re-enable it after.' -ForegroundColor Yellow
} else {
    Write-Host 'Check your internet connection and try again.' -ForegroundColor Yellow
    Write-Host 'If the problem persists, the GitHub release may be unavailable.' -ForegroundColor Yellow
}
Write-Host ''
Read-Host 'Press ENTER to exit'
exit 1
