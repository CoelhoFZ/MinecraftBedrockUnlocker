$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

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
    $profile = [Environment]::GetFolderPath('UserProfile')
    if (-not [string]::IsNullOrWhiteSpace($profile)) {
        $downloads = Join-Path $profile 'Downloads'
        if (Test-Path -LiteralPath $downloads) { return $downloads }
    }
    return $env:TEMP
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
throw $lastError
