$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

$ReleaseBase = 'https://github.com/CoelhoFZ/MinecraftBedrockUnlocker/releases/latest/download'
$Headers = @{
    'Cache-Control' = 'no-cache, no-store, max-age=0'
    'Pragma' = 'no-cache'
    'Expires' = '0'
    'User-Agent' = 'MinecraftBedrockUnlockerShortInstall'
}

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function New-WorkDir {
    $path = Join-Path $env:TEMP ('mbu-install-' + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Force -Path $path | Out-Null
    return $path
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
            if ($Name.EndsWith('.ps1') -or $Name.EndsWith('.txt')) {
                $fullText = Get-Content -LiteralPath $OutFile -Raw
                if (Test-InvalidText $fullText) { throw "$Name returned invalid content" }
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
    $sumsPath = Join-Path $workDir 'SHA256SUMS.txt'
    $installPath = Join-Path $workDir 'install.ps1'

    Write-Host '[MBU] Downloading latest installer manifest...'
    Invoke-DownloadFile -Name 'SHA256SUMS.txt' -OutFile $sumsPath -MinBytes 100

    Write-Host '[MBU] Downloading latest installer...'
    Invoke-DownloadFile -Name 'install.ps1' -OutFile $installPath -MinBytes 1000

    $expectedHash = Get-ExpectedHash -SumsPath $sumsPath -FileName 'install.ps1'
    Assert-Sha256 -Path $installPath -Expected $expectedHash

    $script = Get-Content -LiteralPath $installPath -Raw
    if (Test-InvalidText $script) { throw 'install.ps1 download returned invalid content' }

    Write-Host '[MBU] Installer verified. Starting...'
    Invoke-Expression $script
} finally {
    Remove-Item -LiteralPath $workDir -Recurse -Force -ErrorAction SilentlyContinue
}
