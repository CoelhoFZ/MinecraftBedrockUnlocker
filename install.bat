@echo off
setlocal

title Minecraft Bedrock Unlocker

echo ============================================================
echo  Minecraft Bedrock Unlocker by CoelhoFZ
echo  Downloading and validating the installer...
echo  Baixando e validando o instalador...
echo  Bootstrap: v3.3.4-utf8-fix2
echo ============================================================
echo.

set "PAYLOAD_COMMIT=7effaeb8874e601da27f6459640059a3fb28fe29"
set "PAYLOAD_SHA256=326d60cb244ac9d0618e75b6f2683960acd7e35e4cc113f5de1410eaeac328d4"

powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ErrorActionPreference = 'Stop';" ^
  "$url = 'https://raw.githubusercontent.com/CoelhoFZ/MinecraftBedrockUnlocker/%PAYLOAD_COMMIT%/unlocker.ps1';" ^
  "$expectedSha256 = '%PAYLOAD_SHA256%';" ^
  "$path = Join-Path $env:TEMP ('MinecraftBedrockUnlocker-' + [guid]::NewGuid().ToString('N') + '.ps1');" ^
  "try {" ^
  "  $client = New-Object System.Net.WebClient;" ^
  "  $bytes = $client.DownloadData($url);" ^
  "  $sha256 = [System.Security.Cryptography.SHA256]::Create();" ^
  "  try {" ^
  "    $actualSha256 = -join ($sha256.ComputeHash($bytes) | ForEach-Object { $_.ToString('x2') });" ^
  "  } finally {" ^
  "    $sha256.Dispose();" ^
  "  };" ^
  "  if ($actualSha256 -ne $expectedSha256) {" ^
  "    throw ('Payload SHA-256 mismatch. Expected ' + $expectedSha256 + ', got ' + $actualSha256);" ^
  "  };" ^
  "  $utf8Strict = [System.Text.UTF8Encoding]::new($false, $true);" ^
  "  $content = $utf8Strict.GetString($bytes);" ^
  "  if ($content.Length -gt 0 -and [int]$content[0] -eq 0xFEFF) {" ^
  "    $content = $content.Substring(1);" ^
  "  };" ^
  "  $tokens = $null;" ^
  "  $errors = $null;" ^
  "  [System.Management.Automation.Language.Parser]::ParseInput($content, [ref]$tokens, [ref]$errors) | Out-Null;" ^
  "  if ($errors.Count -gt 0) {" ^
  "    Write-Host 'The downloaded UTF-8 script contains syntax errors.' -ForegroundColor Red;" ^
  "    Write-Host 'O script UTF-8 baixado contem erros de sintaxe.' -ForegroundColor Red;" ^
  "    $errors | ForEach-Object {" ^
  "      Write-Host ('Line/Linha ' + $_.Extent.StartLineNumber + ': ' + $_.Message) -ForegroundColor Red;" ^
  "    };" ^
  "    exit 2;" ^
  "  };" ^
  "  $utf8WithBom = [System.Text.UTF8Encoding]::new($true);" ^
  "  [System.IO.File]::WriteAllText($path, $content, $utf8WithBom);" ^
  "  $fileTokens = $null;" ^
  "  $fileErrors = $null;" ^
  "  [System.Management.Automation.Language.Parser]::ParseFile($path, [ref]$fileTokens, [ref]$fileErrors) | Out-Null;" ^
  "  if ($fileErrors.Count -gt 0) {" ^
  "    Write-Host 'Windows PowerShell could not read the UTF-8 file correctly.' -ForegroundColor Red;" ^
  "    Write-Host 'O Windows PowerShell nao conseguiu ler o arquivo UTF-8 corretamente.' -ForegroundColor Red;" ^
  "    $fileErrors | ForEach-Object {" ^
  "      Write-Host ('Line/Linha ' + $_.Extent.StartLineNumber + ': ' + $_.Message) -ForegroundColor Red;" ^
  "    };" ^
  "    exit 3;" ^
  "  };" ^
  "  Write-Host 'PowerShell syntax and UTF-8 validation passed.' -ForegroundColor Green;" ^
  "  Write-Host 'Validacao de sintaxe e UTF-8 concluida.' -ForegroundColor Green;" ^
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
