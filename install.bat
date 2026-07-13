@echo off
setlocal

title Minecraft Bedrock Unlocker

echo ============================================================
echo  Minecraft Bedrock Unlocker by CoelhoFZ
echo  Downloading and validating the installer bootstrap...
echo  Baixando e validando o bootstrap do instalador...
echo ============================================================
echo.

set "BOOTSTRAP_URL=https://raw.githubusercontent.com/CoelhoFZ/MinecraftBedrockUnlocker/main/install.ps1"

powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ErrorActionPreference = 'Stop';" ^
  "$ProgressPreference = 'SilentlyContinue';" ^
  "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12;" ^
  "try { [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls13 } catch { };" ^
  "$url = '%BOOTSTRAP_URL%';" ^
  "$cacheBust = $url + '?cb=' + [guid]::NewGuid().ToString('N');" ^
  "$path = Join-Path $env:TEMP ('MinecraftBedrockUnlocker-bootstrap-' + [guid]::NewGuid().ToString('N') + '.ps1');" ^
  "try {" ^
  "  Invoke-WebRequest -UseBasicParsing -Uri $cacheBust -OutFile $path -Headers @{'Cache-Control'='no-cache, no-store, max-age=0'; 'Pragma'='no-cache'; 'User-Agent'='MinecraftBedrockUnlocker'};" ^
  "  $tokens = $null; $errors = $null;" ^
  "  [System.ManagementAutomation.Language.Parser]::ParseFile($path, [ref]$tokens, [ref]$errors) | Out-Null;" ^
  "  if ($errors.Count -gt 0) {" ^
  "    Write-Host 'The downloaded bootstrap contains syntax errors.' -ForegroundColor Red;" ^
  "    Write-Host 'O bootstrap baixado contem erros de sintaxe.' -ForegroundColor Red;" ^
  "    $errors | ForEach-Object { Write-Host ('Line/Linha ' + $_.Extent.StartLineNumber + ': ' + $_.Message) -ForegroundColor Red };" ^
  "    exit 2" ^
  "  };" ^
  "  Write-Host 'PowerShell syntax validation passed.' -ForegroundColor Green;" ^
  "  Write-Host 'Validacao de sintaxe concluida.' -ForegroundColor Green;" ^
  "  if ($env:MBU_VALIDATE_ONLY -eq '1') {" ^
  "    Write-Host 'Validation-only mode: execution skipped.' -ForegroundColor Yellow;" ^
  "    exit 0" ^
  "  };" ^
  "  & $path %*" ^
  "} catch {" ^
  "  Write-Host $_.Exception.Message -ForegroundColor Red;" ^
  "  exit 1" ^
  "} finally {" ^
  "  Remove-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue" ^
  "}"

set "EXIT_CODE=%ERRORLEVEL%"

echo.
if not "%EXIT_CODE%"=="0" (
    echo Installer failed with exit code %EXIT_CODE%.
    echo O instalador falhou com o codigo %EXIT_CODE%.
)

pause
exit /b %EXIT_CODE%