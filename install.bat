@echo off
setlocal EnableExtensions

title Minecraft Bedrock Unlocker

set "BOOTSTRAP_VERSION=v3.3.5-memory-exec"
set "PAYLOAD_COMMIT=7effaeb8874e601da27f6459640059a3fb28fe29"
set "PAYLOAD_SHA256=326d60cb244ac9d0618e75b6f2683960acd7e35e4cc113f5de1410eaeac328d4"
set "MBU_BOOTSTRAP_PATH=%~f0"

if not "%MBU_VALIDATE_ONLY%"=="1" (
    powershell.exe -NoLogo -NoProfile -Command "$p=[Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent()); if ($p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { exit 0 } else { exit 1 }"
    if errorlevel 1 (
        echo Requesting Administrator privileges...
        echo Solicitando privilegios de Administrador...
        powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "try { Start-Process -FilePath $env:MBU_BOOTSTRAP_PATH -Verb RunAs -ErrorAction Stop; exit 0 } catch { Write-Host $_.Exception.Message -ForegroundColor Red; exit 1 }"
        if errorlevel 1 (
            echo.
            echo Administrator elevation was denied or failed.
            echo A elevacao para Administrador foi negada ou falhou.
            pause
            exit /b 5
        )
        exit /b 0
    )
)

echo ============================================================
echo  Minecraft Bedrock Unlocker by CoelhoFZ
echo  Downloading and validating the installer...
echo  Baixando e validando o instalador...
echo  Bootstrap: %BOOTSTRAP_VERSION%
echo ============================================================
echo.

powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ErrorActionPreference = 'Stop';" ^
  "$stage = 'initialization';" ^
  "$url = 'https://raw.githubusercontent.com/CoelhoFZ/MinecraftBedrockUnlocker/%PAYLOAD_COMMIT%/unlocker.ps1';" ^
  "$expectedSha256 = '%PAYLOAD_SHA256%';" ^
  "try {" ^
  "  $stage = 'download';" ^
  "  $client = New-Object System.Net.WebClient;" ^
  "  $client.Headers['User-Agent'] = 'MinecraftBedrockUnlocker-Bootstrap/%BOOTSTRAP_VERSION%';" ^
  "  $bytes = $client.DownloadData($url);" ^
  "  $stage = 'sha256';" ^
  "  $sha256 = [System.Security.Cryptography.SHA256]::Create();" ^
  "  try {" ^
  "    $actualSha256 = -join ($sha256.ComputeHash($bytes) | ForEach-Object { $_.ToString('x2') });" ^
  "  } finally {" ^
  "    $sha256.Dispose();" ^
  "  };" ^
  "  if ($actualSha256 -ne $expectedSha256) {" ^
  "    throw ('Payload SHA-256 mismatch. Expected ' + $expectedSha256 + ', got ' + $actualSha256);" ^
  "  };" ^
  "  $stage = 'utf8-decode';" ^
  "  $utf8Strict = [System.Text.UTF8Encoding]::new($false, $true);" ^
  "  $content = $utf8Strict.GetString($bytes);" ^
  "  if ($content.Length -gt 0 -and [int]$content[0] -eq 0xFEFF) {" ^
  "    $content = $content.Substring(1);" ^
  "  };" ^
  "  $stage = 'syntax-validation';" ^
  "  $tokens = $null;" ^
  "  $errors = $null;" ^
  "  [System.Management.Automation.Language.Parser]::ParseInput($content, [ref]$tokens, [ref]$errors) | Out-Null;" ^
  "  if ($errors.Count -gt 0) {" ^
  "    Write-Host 'The downloaded UTF-8 script contains syntax errors.' -ForegroundColor Red;" ^
  "    Write-Host 'O script UTF-8 baixado contem erros de sintaxe.' -ForegroundColor Red;" ^
  "    $errors | Select-Object -First 20 | ForEach-Object {" ^
  "      Write-Host ('Line/Linha ' + $_.Extent.StartLineNumber + ': ' + $_.Message) -ForegroundColor Red;" ^
  "    };" ^
  "    if ($errors.Count -gt 20) { Write-Host ('Additional errors omitted: ' + ($errors.Count - 20)) -ForegroundColor DarkYellow; };" ^
  "    exit 2;" ^
  "  };" ^
  "  Write-Host 'PowerShell syntax and UTF-8 validation passed.' -ForegroundColor Green;" ^
  "  Write-Host 'Validacao de sintaxe e UTF-8 concluida.' -ForegroundColor Green;" ^
  "  if ($env:MBU_VALIDATE_ONLY -eq '1') {" ^
  "    Write-Host 'Validation-only mode: execution skipped.' -ForegroundColor Yellow;" ^
  "    exit 0;" ^
  "  };" ^
  "  $stage = 'in-memory-execution';" ^
  "  $Script:MBUContent = $content;" ^
  "  $scriptBlock = [ScriptBlock]::Create($content);" ^
  "  . $scriptBlock;" ^
  "} catch {" ^
  "  Write-Host ('Bootstrap failed during stage: ' + $stage) -ForegroundColor Red;" ^
  "  Write-Host ('Falha do bootstrap durante a etapa: ' + $stage) -ForegroundColor Red;" ^
  "  Write-Host $_.Exception.Message -ForegroundColor Red;" ^
  "  Write-Host ('Exception type: ' + $_.Exception.GetType().FullName) -ForegroundColor DarkRed;" ^
  "  exit 1;" ^
  "}"

set "EXIT_CODE=%ERRORLEVEL%"

echo.
if not "%EXIT_CODE%"=="0" (
    echo Installer failed with exit code %EXIT_CODE%.
    echo O instalador falhou com o codigo %EXIT_CODE%.
)

pause
exit /b %EXIT_CODE%
