<#
.SYNOPSIS
  Minecraft Bedrock Unlocker v3.1.12 - diagnostic script.
.DESCRIPTION
  Runs a series of non-destructive checks to help debug common issues with the
  unlocker. Useful when:
    - self-protection failed Error: 4
    - Game shows "Unlock Full Version" after install
    - Game crashes on launch
    - Antivirus keeps deleting installed files
    - PowerShell installer returns "ALL DOWNLOADS FAILED"

  Each check returns Pass/Fail/Warn and prints a remediation hint.

  Usage:
    powershell -ExecutionPolicy Bypass -File diagnose.ps1
    powershell -ExecutionPolicy Bypass -File diagnose.ps1 -Json
#>

[CmdletBinding()]
param(
    [switch]$Json,
    [switch]$Fix
)

$ErrorActionPreference = 'Continue'
# Disable StrictMode: this script is a diagnostic tool that handles missing
# services/files gracefully. StrictMode v2 breaks inline `if` expressions in
# -f format strings, which is overkill for a read-only check script.
Set-StrictMode -Off

$Script:Version = '3.1.12'
$Script:RepoOwner = 'CoelhoFZ'
$Script:RepoName  = 'MinecraftBedrockUnlocker'

$results = New-Object System.Collections.Generic.List[object]

function Add-Result {
    param(
        [Parameter(Mandatory=$true)][string]$Name,
        [ValidateSet('pass','fail','warn','info')][string]$Status,
        [string]$Detail = '',
        [string]$Remediation = ''
    )
    $r = [pscustomobject]@{
        name        = $Name
        status      = $Status
        detail      = $Detail
        remediation = $Remediation
    }
    $results.Add($r)
    $color = switch ($Status) {
        'pass' { 'Green' }
        'fail' { 'Red' }
        'warn' { 'Yellow' }
        default { 'Gray' }
    }
    $tag = "[{0}]" -f $Status.ToUpper()
    if (-not $Json) {
        Write-Host (" {0,-6} {1}" -f $tag, $Name) -ForegroundColor $color
        if ($Detail)       { Write-Host ("        Detail: {0}" -f $Detail) -ForegroundColor DarkGray }
        if ($Remediation)  { Write-Host ("        Fix:    {0}" -f $Remediation) -ForegroundColor Cyan }
    }
}

function Test-Windows {
    Add-Result -Name 'Windows platform' -Status $(if ([Environment]::OSVersion.Platform -eq [PlatformID]::Win32NT) { 'pass' } else { 'fail' }) -Detail ([Environment]::OSVersion.VersionString)
}

function Test-Admin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $pr = New-Object Security.Principal.WindowsPrincipal($id)
    $isAdmin = $pr.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    Add-Result -Name 'Running as Administrator' -Status $(if ($isAdmin) { 'pass' } else { 'fail' }) -Detail ("User: {0}" -f $id.Name) -Remediation 'Re-run PowerShell as Administrator (right-click > Run as administrator).'
}

function Test-PowerShellVersion {
    $v = $PSVersionTable.PSVersion
    Add-Result -Name 'PowerShell 5.1+' -Status $(if ($v.Major -ge 5) { 'pass' } else { 'fail' }) -Detail ("Version: {0}" -f $v.ToString())
}

function Test-Architecture {
    $arch = [System.Environment]::Is64BitOperatingSystem
    Add-Result -Name '64-bit Windows' -Status $(if ($arch) { 'pass' } else { 'fail' }) -Detail ("ProcessArch: {0}" -f $env:PROCESSOR_ARCHITECTURE)
}

function Test-XboxAppMinecraft {
    $paths = @(
        'C:\XboxGames\Minecraft for Windows',
        'C:\XboxGames\Minecraft Launcher',
        'D:\XboxGames\Minecraft for Windows',
        'D:\XboxGames\Minecraft Launcher',
        'E:\XboxGames\Minecraft for Windows',
        'E:\XboxGames\Minecraft Launcher'
    )
    $found = @()
    foreach ($p in $paths) {
        if (Test-Path -LiteralPath $p) { $found += $p }
    }
    $status = if ($found.Count -gt 0) { 'pass' } else { 'fail' }
    Add-Result -Name 'Minecraft Bedrock (Xbox App) installed' -Status $status -Detail ($found -join '; ') -Remediation 'Install Minecraft for Windows from the Xbox App (NOT Microsoft Store).'
}

function Test-XboxGameServices {
    try {
        $svc = Get-Service -Name 'GamingServices' -ErrorAction Stop
        $svcNet = Get-Service -Name 'GamingServicesNet' -ErrorAction Stop
        $bothRunning = ($svc.Status -eq 'Running' -and $svcNet.Status -eq 'Running')
        Add-Result -Name 'Xbox Gaming Services running' -Status $(if ($bothRunning) { 'pass' } else { 'fail' }) -Detail ("GamingServices: {0}; GamingServicesNet: {1}" -f $svc.Status, $svcNet.Status) -Remediation 'Run in PowerShell (admin): Get-Service GamingServices,GamingServicesNet | Restart-Service; if missing, reinstall Xbox Game Services via Settings > Apps > Optional features.'
    } catch {
        Add-Result -Name 'Xbox Gaming Services installed' -Status 'fail' -Detail $_.Exception.Message -Remediation 'Install Xbox Game Services via Settings > Apps > Optional features > Add > "Xbox Game Services".'
    }
}

function Test-ModifiedFilesPresent {
    $contentDir = $null
    foreach ($p in @(
        'C:\XboxGames\Minecraft for Windows\Content',
        'D:\XboxGames\Minecraft for Windows\Content',
        'E:\XboxGames\Minecraft for Windows\Content'
    )) {
        if (Test-Path -LiteralPath $p) { $contentDir = $p; break }
    }
    if (-not $contentDir) {
        Add-Result -Name 'Modified files present' -Status 'warn' -Detail 'Minecraft content directory not found.'
        return
    }
    $dlls = Get-ChildItem -LiteralPath $contentDir -Filter '*.dll' -ErrorAction SilentlyContinue
    $count = $dlls.Count
    $status = if ($count -ge 1) { 'pass' } else { 'warn' }
    Add-Result -Name 'Modified files present' -Status $status -Detail ("Dir: {0}; DLLs found: {1}" -f $contentDir, $count) -Remediation 'Re-run the unlocker (Option 1) to install bypass DLLs.'
}

function Test-AvExclusions {
    $tempPath = Join-Path ([System.IO.Path]::GetTempPath()) 'MinecraftBedrockUnlocker'
    $contentPaths = @(
        'C:\XboxGames\Minecraft for Windows\Content',
        'D:\XboxGames\Minecraft for Windows\Content'
    )
    try {
        $prefs = Get-MpPreference -ErrorAction Stop
        $excl = @($prefs.ExclusionPath)
        $missing = @()
        if ($tempPath -notin $excl) { $missing += $tempPath }
        foreach ($cp in $contentPaths) {
            if ((Test-Path -LiteralPath $cp) -and ($cp -notin $excl)) { $missing += $cp }
        }
        if ($missing.Count -eq 0) {
            Add-Result -Name 'Defender exclusions' -Status 'pass' -Detail ("Excluded paths: {0}" -f ($excl -join ', '))
        } else {
            Add-Result -Name 'Defender exclusions' -Status 'warn' -Detail ("Missing: {0}" -f ($missing -join ', ')) -Remediation ("Run as admin: Add-MpPreference -ExclusionPath '{0}'" -f ($missing -join "','"))
        }
    } catch {
        # Defender may not be installed / disabled
        Add-Result -Name 'Defender exclusions' -Status 'info' -Detail 'Get-MpPreference unavailable (Defender not installed or disabled).'
    }
}

function Test-TempDownloadFolder {
    $tempPath = Join-Path ([System.IO.Path]::GetTempPath()) 'MinecraftBedrockUnlocker'
    $exists = Test-Path -LiteralPath $tempPath
    Add-Result -Name 'Bootstrap temp folder' -Status $(if ($exists) { 'pass' } else { 'info' }) -Detail ("Path: {0}" -f $tempPath)
}

function Test-InternetAndGitHub {
    $urls = @(
        'https://github.com',
        'https://api.github.com',
        ("https://github.com/{0}/{1}/releases/latest" -f $Script:RepoOwner, $Script:RepoName),
        ("https://raw.githubusercontent.com/{0}/{1}/main/install.ps1" -f $Script:RepoOwner, $Script:RepoName)
    )
    $results_ = @()
    foreach ($u in $urls) {
        try {
            $r = Invoke-WebRequest -Uri $u -UseBasicParsing -Method Head -TimeoutSec 10 -MaximumRedirection 5
            $results_ += [pscustomobject]@{ url = $u; code = $r.StatusCode }
        } catch {
            $results_ += [pscustomobject]@{ url = $u; code = ($_.Exception.Response.StatusCode.value__); err = $_.Exception.Message }
        }
    }
    $okCount = ($results_ | Where-Object { $_.code -ge 200 -and $_.code -lt 400 }).Count
    $status = if ($okCount -eq $urls.Count) { 'pass' } elseif ($okCount -gt 0) { 'warn' } else { 'fail' }
    Add-Result -Name 'Internet + GitHub reachable' -Status $status -Detail ("OK: {0}/{1}; details: {2}" -f $okCount, $urls.Count, ($results_ | ForEach-Object { "$($_.url)=$($_.code)" }) -join '; ')
}

function Test-ExistingExeBootstrap {
    $exeUrl = "https://github.com/{0}/{1}/releases/latest/download/MinecraftBedrockUnlocker.exe" -f $Script:RepoOwner, $Script:RepoName
    try {
        $r = Invoke-WebRequest -Uri $exeUrl -UseBasicParsing -Method Head -TimeoutSec 15 -MaximumRedirection 5
        $clHeader = $r.Headers.'Content-Length'
        $size = 0
        if ($clHeader) {
            $size = [int64]($clHeader | Select-Object -First 1)
        }
        $ok = ($r.StatusCode -eq 200) -and ($size -gt 5000000)
        Add-Result -Name 'Release EXE download URL' -Status $(if ($ok) { 'pass' } else { 'fail' }) -Detail ("URL: {0}; Status: {1}; Size: {2} bytes" -f $exeUrl, $r.StatusCode, $size)
    } catch {
        Add-Result -Name 'Release EXE download URL' -Status 'fail' -Detail ("URL: {0}; Error: {1}" -f $exeUrl, $_.Exception.Message) -Remediation 'Re-run the bootstrap later (GitHub release may be rate-limiting).'
    }
}

function Test-SelfProtectionFiles {
    # self-protection Error: 4 is usually caused by:
    #  - Gaming Services missing/broken
    #  - OnlineFix64.dll signature mismatch after MC update
    #  - Minecraft for Windows reinstalled (reset Content folder)
    $candidates = @()
    foreach ($p in @(
        'C:\XboxGames\Minecraft for Windows\Content',
        'D:\XboxGames\Minecraft for Windows\Content',
        'E:\XboxGames\Minecraft for Windows\Content'
    )) {
        if (Test-Path -LiteralPath $p) { $candidates += $p }
    }
    if ($candidates.Count -eq 0) {
        Add-Result -Name 'Self-protection Error: 4 check' -Status 'info' -Detail 'Content folder not found; cannot assess.'
        return
    }
    foreach ($dir in $candidates) {
        $dllList = Join-Path $dir 'dlllist.txt'
        if (Test-Path -LiteralPath $dllList) {
            $entry = Get-Content -LiteralPath $dllList -TotalCount 1 -ErrorAction SilentlyContinue
            $dllExists = $null -ne (Get-ChildItem -LiteralPath $dir -Filter $entry.Trim() -ErrorAction SilentlyContinue)
            Add-Result -Name "self-protection in $dir" -Status (
                $status = if ($dllExists) { 'pass' } else { 'fail' }
            ) -Detail ("dlllist says: {0}; file exists: {1}" -f $entry.Trim(), $dllExists) -Remediation "Re-run the unlocker Option 1 to restore the bypass DLL referenced in dlllist.txt."
        } else {
            Add-Result -Name "self-protection in $dir" -Status 'warn' -Detail 'dlllist.txt missing; unlocker was never run or files were wiped.' -Remediation 'Run the unlocker (Option 1).'
        }
    }
}

# ---------------------------------------------------------------------------
# Run all checks
# ---------------------------------------------------------------------------

if (-not $Json) {
    Write-Host ''
    Write-Host '============================================================' -ForegroundColor Cyan
    Write-Host (" Minecraft Bedrock Unlocker - diagnostic v{0}" -f $Script:Version) -ForegroundColor Cyan
    Write-Host '============================================================' -ForegroundColor Cyan
    Write-Host ''
}

Test-Windows
Test-PowerShellVersion
Test-Architecture
Test-Admin
Test-InternetAndGitHub
Test-ExistingExeBootstrap
Test-TempDownloadFolder
Test-AvExclusions
Test-XboxAppMinecraft
Test-XboxGameServices
Test-ModifiedFilesPresent
Test-SelfProtectionFiles

if ($Json) {
    $results | ConvertTo-Json -Depth 3
} else {
    # Use @(...) to force array context (avoids .Count failing on 0/1 element pipelines).
    $pass = @($results | Where-Object { $_.status -eq 'pass' }).Count
    $fail = @($results | Where-Object { $_.status -eq 'fail' }).Count
    $warn = @($results | Where-Object { $_.status -eq 'warn' }).Count
    $info = @($results | Where-Object { $_.status -eq 'info' }).Count
    Write-Host ''
    $summaryColor = if ($fail -eq 0) { 'Green' } else { 'Yellow' }
    Write-Host ('Summary: {0} pass, {1} fail, {2} warn, {3} info' -f $pass, $fail, $warn, $info) -ForegroundColor $summaryColor
    if ($fail -gt 0) {
        Write-Host ''
        Write-Host 'Failed checks need attention before the unlocker will work.' -ForegroundColor Red
        exit 1
    }
    exit 0
}