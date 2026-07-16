# Legacy compatibility wrapper — e.ps1 was renamed to i.ps1.
# This file exists so old links and tutorials still work.

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
try { [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls13 } catch { }
$ProgressPreference = 'SilentlyContinue'

$url = 'https://raw.githubusercontent.com/CoelhoFZ/MinecraftBedrockUnlocker/main/i.ps1'
$client = New-Object System.Net.WebClient
$client.Encoding = [System.Text.Encoding]::UTF8
$content = $client.DownloadString($url)
& ([scriptblock]::Create($content))
