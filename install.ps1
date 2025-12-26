<#
.SYNOPSIS
    Minecraft Bedrock Unlocker - One-Line Installer
    
.DESCRIPTION
    Downloads and runs the Minecraft Bedrock Unlocker with auto-elevation.
    Usage: irm https://raw.githubusercontent.com/CoelhoFZ/MinecraftBedrockUnlocker/main/install.ps1 | iex
    
.NOTES
    Author: CoelhoFZ
    Repository: https://github.com/CoelhoFZ/MinecraftBedrockUnlocker
#>

$ErrorActionPreference = 'Stop'

# Configuration
$RepoOwner = "CoelhoFZ"
$RepoName = "MinecraftBedrockUnlocker"
$ExeName = "mc_unlocker.exe"

# Colors
function Write-Color {
    param([string]$Text, [ConsoleColor]$Color = 'White')
    Write-Host $Text -ForegroundColor $Color
}

# Banner
function Show-Banner {
    Clear-Host
    Write-Color ""
    Write-Color "  ╔══════════════════════════════════════════════════════════════════╗" Cyan
    Write-Color "  ║     MINECRAFT BEDROCK UNLOCKER - One-Line Installer              ║" Cyan
    Write-Color "  ║                        by CoelhoFZ                               ║" Cyan
    Write-Color "  ╚══════════════════════════════════════════════════════════════════╝" Cyan
    Write-Color ""
}

# Check if running as admin
function Test-Admin {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Request elevation
function Request-Elevation {
    Write-Color "[!] Administrator privileges required. Requesting elevation..." Yellow
    
    # Build the command to re-run this script elevated
    $scriptBlock = {
        irm https://raw.githubusercontent.com/CoelhoFZ/MinecraftBedrockUnlocker/main/install.ps1 | iex
    }
    
    try {
        Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"irm https://raw.githubusercontent.com/CoelhoFZ/MinecraftBedrockUnlocker/main/install.ps1 | iex`"" -Verb RunAs
        Write-Color "[OK] Elevated window opened. You can close this window." Green
    }
    catch {
        Write-Color "[ERROR] Failed to elevate. Please run PowerShell as Administrator." Red
        Write-Color "        Right-click PowerShell -> Run as administrator" Yellow
    }
    
    return
}

# Get latest release info from GitHub
function Get-LatestRelease {
    Write-Color "[*] Fetching latest release from GitHub..." Cyan
    
    $apiUrl = "https://api.github.com/repos/$RepoOwner/$RepoName/releases/latest"
    
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $release = Invoke-RestMethod -Uri $apiUrl -Headers @{'User-Agent'='MinecraftUnlocker-Installer'} -TimeoutSec 30
        
        $asset = $release.assets | Where-Object { $_.name -like "*.exe" } | Select-Object -First 1
        
        if (-not $asset) {
            throw "No executable found in the latest release"
        }
        
        return @{
            Version = $release.tag_name -replace '^v', ''
            DownloadUrl = $asset.browser_download_url
            FileName = $asset.name
            ReleaseUrl = $release.html_url
        }
    }
    catch {
        Write-Color "[ERROR] Failed to fetch release info: $_" Red
        return $null
    }
}

# Download the executable
function Get-Executable {
    param([hashtable]$ReleaseInfo)
    
    $tempPath = Join-Path $env:TEMP $ReleaseInfo.FileName
    
    Write-Color "[*] Downloading $($ReleaseInfo.FileName) v$($ReleaseInfo.Version)..." Cyan
    
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri $ReleaseInfo.DownloadUrl -OutFile $tempPath -UseBasicParsing -TimeoutSec 120
        
        if (Test-Path $tempPath) {
            Write-Color "[OK] Download complete!" Green
            return $tempPath
        }
        else {
            throw "Downloaded file not found"
        }
    }
    catch {
        Write-Color "[ERROR] Download failed: $_" Red
        return $null
    }
}

# Main execution
function Start-Installation {
    Show-Banner
    
    # Check if admin
    if (-not (Test-Admin)) {
        Request-Elevation
        return
    }
    
    Write-Color "[OK] Running with Administrator privileges" Green
    Write-Color ""
    
    # Get latest release
    $release = Get-LatestRelease
    if (-not $release) {
        Write-Color ""
        Write-Color "Press any key to exit..." Gray
        $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
        return
    }
    
    Write-Color "[OK] Found version: $($release.Version)" Green
    
    # Download
    $exePath = Get-Executable -ReleaseInfo $release
    if (-not $exePath) {
        Write-Color ""
        Write-Color "Press any key to exit..." Gray
        $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
        return
    }
    
    Write-Color ""
    Write-Color "[*] Starting Minecraft Bedrock Unlocker..." Cyan
    Write-Color ""
    
    # Run the executable
    try {
        Start-Process -FilePath $exePath -Wait
        
        # Cleanup
        Write-Color ""
        Write-Color "[*] Cleaning up temporary files..." Cyan
        Remove-Item -Path $exePath -Force -ErrorAction SilentlyContinue
        Write-Color "[OK] Done!" Green
    }
    catch {
        Write-Color "[ERROR] Failed to run executable: $_" Red
    }
    
    Write-Color ""
    Write-Color "Press any key to exit..." Gray
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
}

# Run
Start-Installation
