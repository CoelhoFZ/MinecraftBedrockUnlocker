@echo off
setlocal

title Minecraft Bedrock Unlocker

echo ============================================================
echo  Minecraft Bedrock Unlocker by CoelhoFZ
echo  Downloading and validating the installer...
echo  Baixando e validando o instalador...
echo ============================================================
echo.

set "PAYLOAD_COMMIT=7effaeb8874e601da27f6459640059a3fb28fe29"

powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ErrorActionPreference = 'Stop';" ^
  "$url = 'https://raw.githubusercontent.com/CoelhoFZ/MinecraftBedrockUnlocker/%PAYLOAD_COMMIT%/unlocker.ps1';" ^
  "$path = Join-Path $env:TEMP ('MinecraftBedrockUnlocker-' + [guid]::NewGuid().ToString('N') + '.ps1');" ^
  "try {" ^
  "  Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile $path;" ^
  "  $tokens = $null;" ^
  "  $errors = $null;" ^
  "  [System.Management.Automation.Language.Parser]::ParseFile($path, [ref]$tokens, [ref]$errors) | Out-Null;" ^
  "  if ($errors.Count -gt 0) {" ^
  "    Write-Host 'The downloaded script contains syntax errors.' -ForegroundColor Red;" ^
  "    Write-Host 'O script baixado contem erros de sintaxe.' -ForegroundColor Red;" ^
  "    $errors | ForEach-Object {" ^
  "      Write-Host ('Line/Linha ' + $_.Extent.StartLineNumber + ': ' + $_.Message) -ForegroundColor Red;" ^
  "    };" ^
  "    exit 2;" ^
  "  };" ^
  "  Write-Host 'PowerShell syntax validation passed.' -ForegroundColor Green;" ^
  "  Write-Host 'Validacao de sintaxe concluida.' -ForegroundColor Green;" ^
  "  if ($env:MBU_VALIDATE_ONLY -eq '1') {" ^
  "    Write-Host 'Validation-only mode: execution skipped.' -ForegroundColor Yellow;" ^
  "    exit 0;" ^
  "  };" ^
  "  & $path;" ^
  "} catch {" ^
  "  Write-Host $_.Exception.Message -ForegroundColor Red;" ^
  "  exit 1;" ^
  "} finally {" ^
  "  Remove-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue;" ^
  "}"

set "EXIT_CODE=%ERRORLEVEL%"

echo.
if not "%EXIT_CODE%"=="0" (
    echo Installer failed with exit code %EXIT_CODE%.
    echo O instalador falhou com o codigo %EXIT_CODE%.
)

pause
exit /b %EXIT_CODE%
