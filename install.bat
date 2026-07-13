@echo off
setlocal EnableExtensions

title Minecraft Bedrock Unlocker

echo ============================================================
echo  Minecraft Bedrock Unlocker by CoelhoFZ
echo  Baixando e executando o Unlocker...
echo ============================================================
echo.

powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ErrorActionPreference = 'Stop';" ^
  "$url = 'https://raw.githubusercontent.com/CoelhoFZ/MinecraftBedrockUnlocker/main/install.ps1';" ^
  "$headers = @{ 'Cache-Control' = 'no-cache, no-store, max-age=0'; 'Pragma' = 'no-cache'; 'User-Agent' = 'MinecraftBedrockUnlocker' };" ^
  "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12;" ^
  "$content = $null;" ^
  "1..3 | ForEach-Object {" ^
  "  if (-not $content) {" ^
  "    try {" ^
  "      $content = (Invoke-RestMethod -UseBasicParsing -Headers $headers -Uri ($url + '?cb=' + [guid]::NewGuid().ToString('N')) -MaximumRedirection 5 | Out-String);" ^
  "    } catch { Start-Sleep -Seconds 1 }" ^
  "  }" ^
  "};" ^
  "if (-not $content -or $content.TrimStart().StartsWith('<')) { throw 'Falha ao baixar o install.ps1' };" ^
  "Invoke-Expression $content"

set "EXIT_CODE=%ERRORLEVEL%"

if not "%EXIT_CODE%"=="0" (
    echo.
    echo Falha ao executar o Unlocker. Codigo: %EXIT_CODE%
    pause
)

exit /b %EXIT_CODE%
