<#
.SYNOPSIS
    Minecraft Bedrock Unlocker compatibility bootstrap.

.DESCRIPTION
    Loads the maintained unlocker core and applies a narrow compatibility fix
    before execution. The core still contains the Start-MainLoop entry point.
#>

param(
    [string]$ResourceDir,
    [string]$MinecraftPath
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

function Get-MbuUtf8Text {
    param([Parameter(Mandatory = $true)][byte[]]$Bytes)

    $utf8 = New-Object System.Text.UTF8Encoding -ArgumentList $false, $true
    $text = $utf8.GetString($Bytes)
    return $text.TrimStart([char]0xFEFF, [char]0x200B, [char]0x200C, [char]0x200D)
}

function Get-MbuCoreContent {
    if ($ResourceDir) {
        $embeddedPath = Join-Path $ResourceDir 'unlocker.ps1'
        if (Test-Path -LiteralPath $embeddedPath) {
            try {
                $embedded = Get-Item -LiteralPath $embeddedPath -Force -ErrorAction Stop
                if ($embedded.Length -gt 100000) {
                    return Get-MbuUtf8Text -Bytes ([System.IO.File]::ReadAllBytes($embeddedPath))
                }
            } catch { }
        }
    }

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    try {
        [Net.ServicePointManager]::SecurityProtocol =
            [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls13
    } catch { }

    $headers = @{
        'Cache-Control' = 'no-cache, no-store, max-age=0'
        'Pragma'        = 'no-cache'
        'Expires'       = '0'
        'User-Agent'    = 'MinecraftBedrockUnlocker/compat'
    }

    $urls = @(
        'https://raw.githubusercontent.com/CoelhoFZ/MinecraftBedrockUnlocker/main/runtime/unlocker-core.ps1',
        'https://github.com/CoelhoFZ/MinecraftBedrockUnlocker/releases/latest/download/unlocker.ps1'
    )

    $errors = New-Object System.Collections.Generic.List[string]
    foreach ($url in $urls) {
        for ($attempt = 1; $attempt -le 3; $attempt++) {
            $client = $null
            try {
                $client = New-Object System.Net.WebClient
                foreach ($header in $headers.GetEnumerator()) {
                    $client.Headers[$header.Key] = [string]$header.Value
                }

                $separator = if ($url.Contains('?')) { '&' } else { '?' }
                $downloadUrl = '{0}{1}cb={2}' -f $url, $separator, [guid]::NewGuid().ToString('N')
                $content = Get-MbuUtf8Text -Bytes ($client.DownloadData($downloadUrl))

                if ([string]::IsNullOrWhiteSpace($content) -or
                    $content -notmatch 'Minecraft Bedrock Unlocker' -or
                    $content -notmatch 'Start-MainLoop') {
                    throw 'Downloaded content is not the expected unlocker core.'
                }

                return $content
            } catch {
                $errors.Add("$url attempt $attempt => $($_.Exception.Message)") | Out-Null
                Start-Sleep -Milliseconds (250 * $attempt)
            } finally {
                if ($client) { $client.Dispose() }
            }
        }
    }

    throw "Unable to load unlocker core. $($errors -join ' | ')"
}

function Set-MbuRuntimeStateCompatibility {
    param([Parameter(Mandatory = $true)][string]$Content)

    $text = $Content.Replace("`r`n", "`n")

    $oldProtectedFiles = '    $files = @("winmm.dll", (Get-DiskName -SourceName "OnlineFix64.dll"), "dlllist.txt", "OnlineFix.ini")'
    $newProtectedFiles = @'
    $files = @("winmm.dll", (Get-DiskName -SourceName "OnlineFix64.dll"), "dlllist.txt")

    # OnlineFix.ini stores runtime state. Keep it writable so first-run state
    # and other settings can be persisted normally.
    $iniPath = Join-Path $ContentPath "OnlineFix.ini"
    if (Test-Path $iniPath) {
        try {
            $iniFile = Get-Item $iniPath -Force -ErrorAction Stop
            $iniFile.Attributes = [System.IO.FileAttributes]::Normal
        } catch {
            try { $null = cmd /c "attrib -R -S -H `"$iniPath`"" 2>$null } catch { }
        }
    }
'@

    if ($text.Contains($oldProtectedFiles)) {
        $text = $text.Replace($oldProtectedFiles, $newProtectedFiles.TrimEnd())
    } elseif ($text -notmatch 'OnlineFix\.ini stores runtime state') {
        throw 'The expected installed-file protection block was not found.'
    }

    $oldBackupLoop = @'
    # Save encrypted copies of each file
    $manifest = @()
    foreach ($file in $Script:OnlineFixFiles) {
        $diskName = Get-DiskName -SourceName $file.Name
'@
    $newBackupLoop = @'
    # Save encrypted copies of static runtime files only. OnlineFix.ini is
    # intentionally excluded so runtime state is never rolled back at logon.
    $manifest = @()
    foreach ($file in $Script:OnlineFixFiles) {
        if ($file.Name -eq "OnlineFix.ini") { continue }
        $diskName = Get-DiskName -SourceName $file.Name
'@

    if ($text.Contains($oldBackupLoop.TrimEnd())) {
        $text = $text.Replace($oldBackupLoop.TrimEnd(), $newBackupLoop.TrimEnd())
    } elseif ($text -notmatch 'runtime state is never rolled back at logon') {
        throw 'The expected persistence backup block was not found.'
    }

    return $text
}

$coreContent = Get-MbuCoreContent
$patchedContent = Set-MbuRuntimeStateCompatibility -Content $coreContent

$tokens = $null
$parseErrors = $null
[System.Management.Automation.Language.Parser]::ParseInput(
    $patchedContent,
    [ref]$tokens,
    [ref]$parseErrors
) | Out-Null

if ($parseErrors -and $parseErrors.Count -gt 0) {
    $messages = ($parseErrors | ForEach-Object { $_.Message }) -join ' | '
    throw "Patched unlocker failed PowerShell syntax validation: $messages"
}

$Script:MBUContent = $patchedContent
$scriptBlock = [ScriptBlock]::Create($patchedContent)
$parameters = @{}
if ($ResourceDir) { $parameters['ResourceDir'] = $ResourceDir }
if ($MinecraftPath) { $parameters['MinecraftPath'] = $MinecraftPath }

& $scriptBlock @parameters
