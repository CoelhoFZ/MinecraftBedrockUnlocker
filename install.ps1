<#
.SYNOPSIS
    Minecraft Bedrock Unlocker PowerShell bootstrap.

.DESCRIPTION
    Downloads and executes the current compatibility bootstrap used by both
    install.bat and the direct PowerShell installation command.
#>

param(
    [string]$ResourceDir,
    [string]$MinecraftPath
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
try {
    [Net.ServicePointManager]::SecurityProtocol =
        [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls13
} catch { }

$headers = @{
    'Cache-Control' = 'no-cache, no-store, max-age=0'
    'Pragma'        = 'no-cache'
    'Expires'       = '0'
    'User-Agent'    = 'MinecraftBedrockUnlocker/install'
}

$urls = @(
    'https://raw.githubusercontent.com/CoelhoFZ/MinecraftBedrockUnlocker/main/unlocker.ps1',
    'https://github.com/CoelhoFZ/MinecraftBedrockUnlocker/releases/latest/download/unlocker.ps1'
)

$errors = New-Object System.Collections.Generic.List[string]
$content = $null

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
            $bytes = $client.DownloadData($downloadUrl)
            $utf8 = New-Object System.Text.UTF8Encoding -ArgumentList $false, $true
            $candidate = $utf8.GetString($bytes)
            $candidate = $candidate.TrimStart([char]0xFEFF, [char]0x200B, [char]0x200C, [char]0x200D)

            if ([string]::IsNullOrWhiteSpace($candidate) -or
                $candidate -notmatch 'Minecraft Bedrock Unlocker' -or
                $candidate -notmatch 'Start-MainLoop') {
                throw 'Downloaded content is not the expected installer.'
            }

            $content = $candidate
            break
        } catch {
            $errors.Add("$url attempt $attempt => $($_.Exception.Message)") | Out-Null
            Start-Sleep -Milliseconds (250 * $attempt)
        } finally {
            if ($client) { $client.Dispose() }
        }
    }

    if (-not [string]::IsNullOrWhiteSpace($content)) { break }
}

if ([string]::IsNullOrWhiteSpace($content)) {
    throw "Installer download failed. $($errors -join ' | ')"
}

$tokens = $null
$parseErrors = $null
[System.Management.Automation.Language.Parser]::ParseInput(
    $content,
    [ref]$tokens,
    [ref]$parseErrors
) | Out-Null

if ($parseErrors -and $parseErrors.Count -gt 0) {
    $messages = ($parseErrors | ForEach-Object { $_.Message }) -join ' | '
    throw "Downloaded installer contains PowerShell syntax errors: $messages"
}

$scriptBlock = [ScriptBlock]::Create($content)
$parameters = @{}
if ($ResourceDir) { $parameters['ResourceDir'] = $ResourceDir }
if ($MinecraftPath) { $parameters['MinecraftPath'] = $MinecraftPath }

& $scriptBlock @parameters
