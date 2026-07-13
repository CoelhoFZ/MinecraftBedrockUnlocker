@echo off
setlocal EnableExtensions

title Minecraft Bedrock Utility v3.3.3

set "VERSION=v3.3.3"
set "PAYLOAD_COMMIT=9f3be23abe78cc0faf1c6b78e78f57a608716e2f"
set "PAYLOAD_SHA256=b4d8b07df3e5f1c60bf06778ccd70ad6b03d191e71f436f1f95052bb1c669884"

echo ============================================================
echo  Minecraft Bedrock Utility by CoelhoFZ
echo  Versao: %VERSION%
echo  Baixando e validando o iniciador...
echo ============================================================
echo.

powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ErrorActionPreference = 'Stop';" ^
  "$stage = 'inicializacao';" ^
  "$url = 'https://raw.githubusercontent.com/CoelhoFZ/MinecraftBedrockUnlocker/%PAYLOAD_COMMIT%/launcher.ps1';" ^
  "$expectedSha256 = '%PAYLOAD_SHA256%';" ^
  "try {" ^
  "  $stage = 'download';" ^
  "  $client = New-Object System.Net.WebClient;" ^
  "  $client.Headers['User-Agent'] = 'MinecraftBedrockUtility/%VERSION%';" ^
  "  $bytes = $client.DownloadData($url);" ^
  "  $stage = 'sha256';" ^
  "  $sha256 = [System.Security.Cryptography.SHA256]::Create();" ^
  "  try {" ^
  "    $actualSha256 = -join ($sha256.ComputeHash($bytes) | ForEach-Object { $_.ToString('x2') });" ^
  "  } finally {" ^
  "    $sha256.Dispose();" ^
  "  };" ^
  "  if ($actualSha256 -ne $expectedSha256) {" ^
  "    throw ('SHA-256 incorreto. Esperado ' + $expectedSha256 + ', recebido ' + $actualSha256);" ^
  "  };" ^
  "  $stage = 'utf8';" ^
  "  $utf8 = New-Object System.Text.UTF8Encoding($false, $true);" ^
  "  $content = $utf8.GetString($bytes);" ^
  "  if ($content.Length -gt 0 -and [int]$content[0] -eq 0xFEFF) { $content = $content.Substring(1) };" ^
  "  $stage = 'validacao';" ^
  "  $tokens = $null;" ^
  "  $errors = $null;" ^
  "  [System.Management.Automation.Language.Parser]::ParseInput($content, [ref]$tokens, [ref]$errors) | Out-Null;" ^
  "  if ($errors.Count -gt 0) {" ^
  "    $errors | Select-Object -First 20 | ForEach-Object { Write-Host ('Linha ' + $_.Extent.StartLineNumber + ': ' + $_.Message) -ForegroundColor Red };" ^
  "    throw 'O iniciador baixado possui erros de sintaxe.';" ^
  "  };" ^
  "  Write-Host 'Validacao concluida. Abrindo o menu...' -ForegroundColor Green;" ^
  "  $stage = 'execucao';" ^
  "  . ([ScriptBlock]::Create($content));" ^
  "} catch {" ^
  "  Write-Host ('Falha durante a etapa: ' + $stage) -ForegroundColor Red;" ^
  "  Write-Host $_.Exception.Message -ForegroundColor Red;" ^
  "  exit 1;" ^
  "}"

set "EXIT_CODE=%ERRORLEVEL%"

if not "%EXIT_CODE%"=="0" (
    echo.
    echo O iniciador falhou com o codigo %EXIT_CODE%.
    pause
)

exit /b %EXIT_CODE%
