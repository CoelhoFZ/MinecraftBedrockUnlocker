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

function New-WorkDir {
    $path = Join-Path $env:TEMP ('mbu-exe-' + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Force -Path $path | Out-Null
    return $path
}

function Get-DownloadFolder {
    $profile = [Environment]::GetFolderPath('UserProfile')
    if (-not [string]::IsNullOrWhiteSpace($profile)) {
        $downloads = Join-Path $profile 'Downloads'
        if (Test-Path -LiteralPath $downloads) { return $downloads }
    }
    return $env:TEMP
}

function Test-InvalidText {
    param([string]$Text)

    if ([string]::IsNullOrWhiteSpace($Text)) { return $true }
    $trimmed = $Text.TrimStart()
    return $trimmed.StartsWith('<!DOCTYPE', [StringComparison]::OrdinalIgnoreCase) -or
        $trimmed.StartsWith('<html', [StringComparison]::OrdinalIgnoreCase)
}

function Invoke-DownloadFile {
    param(
        [string]$Name,
        [string]$OutFile,
        [int64]$MinBytes
    )

    $lastError = $null
    for ($attempt = 1; $attempt -le 3; $attempt++) {
        try {
            $url = "$ReleaseBase/$Name`?cb=$([guid]::NewGuid().ToString('N'))"
            Invoke-WebRequest -UseBasicParsing -Headers $Headers -Uri $url -MaximumRedirection 5 -OutFile $OutFile
            if (-not (Test-Path -LiteralPath $OutFile)) { throw "$Name was not saved" }
            $item = Get-Item -LiteralPath $OutFile
            if ($item.Length -lt $MinBytes) { throw "$Name download is too small ($($item.Length) bytes)" }
            if ($Name.EndsWith('.txt')) {
                $text = Get-Content -LiteralPath $OutFile -Raw
                if (Test-InvalidText $text) { throw "$Name returned invalid content" }
            } else {
                $headBytes = [System.IO.File]::ReadAllBytes($OutFile)
                if ($headBytes.Length -ge 2 -and $headBytes[0] -eq 0x4d -and $headBytes[1] -eq 0x5a) { return }
                $probeLength = [Math]::Min(256, $headBytes.Length)
                $probe = [Text.Encoding]::ASCII.GetString($headBytes, 0, $probeLength)
                if (Test-InvalidText $probe) { throw "$Name returned HTML instead of a file" }
                throw "$Name does not look like a Windows executable"
            }
            return
        } catch {
            $lastError = $_
            Start-Sleep -Seconds $attempt
        }
    }
    throw $lastError
}

function Get-ExpectedHash {
    param(
        [string]$SumsPath,
        [string]$FileName
    )

    foreach ($line in Get-Content -LiteralPath $SumsPath) {
        if ($line -match '^([a-fA-F0-9]{64})\s+\*?(.+)$') {
            $hash = $Matches[1].ToLowerInvariant()
            $name = Split-Path -Leaf $Matches[2].Trim()
            if ($name -eq $FileName) { return $hash }
        }
    }
    throw "Hash for $FileName not found in SHA256SUMS.txt"
}

function Assert-Sha256 {
    param(
        [string]$Path,
        [string]$Expected
    )

    $actual = (Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash.ToLowerInvariant()
    if ($actual -ne $Expected.ToLowerInvariant()) {
        throw "SHA256 mismatch for $(Split-Path -Leaf $Path). Expected $Expected, got $actual"
    }
}

$workDir = New-WorkDir
try {
    $downloadFolder = Get-DownloadFolder
    $exePath = Join-Path $downloadFolder 'MinecraftBedrockUnlocker.exe'
    $sumsPath = Join-Path $workDir 'SHA256SUMS.txt'

    Write-Host '[MBU] Downloading latest EXE manifest...'
    Invoke-DownloadFile -Name 'SHA256SUMS.txt' -OutFile $sumsPath -MinBytes 100

    Write-Host "[MBU] Downloading MinecraftBedrockUnlocker.exe to $exePath..."
    Invoke-DownloadFile -Name 'MinecraftBedrockUnlocker.exe' -OutFile $exePath -MinBytes 100000

    $expectedHash = Get-ExpectedHash -SumsPath $sumsPath -FileName 'MinecraftBedrockUnlocker.exe'
    Assert-Sha256 -Path $exePath -Expected $expectedHash

    Write-Host '[MBU] EXE verified. Starting as Administrator...'
    Start-Process -FilePath $exePath -Verb RunAs
} finally {
    Remove-Item -LiteralPath $workDir -Recurse -Force -ErrorAction SilentlyContinue
}
