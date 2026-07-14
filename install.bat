@echo off
setlocal EnableExtensions

title Minecraft Bedrock Unlocker

set "BOOTSTRAP_URL=https://raw.githubusercontent.com/CoelhoFZ/MinecraftBedrockUnlocker/main/install.ps1"

for /f "usebackq delims=" %%L in (`powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "try { $c = [System.Globalization.CultureInfo]::CurrentUICulture.TwoLetterISOLanguageName; if ([string]::IsNullOrWhiteSpace($c)) { $c = (Get-Culture).TwoLetterISOLanguageName }; if ($c -eq 'pt') { 'pt' } else { 'en' } } catch { 'en' }" 2^>nul`) do set "MBU_LANG=%%L"
if not defined MBU_LANG set "MBU_LANG=en"

if /I "%MBU_LANG%"=="pt" (
    echo ============================================================
    echo  Minecraft Bedrock Unlocker by CoelhoFZ
    echo  Baixando e validando o instalador...
    echo ============================================================
) else (
    echo ============================================================
    echo  Minecraft Bedrock Unlocker by CoelhoFZ
    echo  Downloading and validating the installer...
    echo ============================================================
)
echo.

powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ErrorActionPreference = 'Stop';" ^
  "$ProgressPreference = 'SilentlyContinue';" ^
  "$lang = if ($env:MBU_LANG -eq 'pt') { 'pt' } else { 'en' };" ^
  "function Say { param([string]$Pt, [string]$En, [ConsoleColor]$Color = [ConsoleColor]::White) if ($lang -eq 'pt') { Write-Host $Pt -ForegroundColor $Color } else { Write-Host $En -ForegroundColor $Color } };" ^
  "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12;" ^
  "try { [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls13 } catch { };" ^
  "$url = '%BOOTSTRAP_URL%';" ^
  "$cacheBust = $url + '?cb=' + [guid]::NewGuid().ToString('N');" ^
  "$path = Join-Path $env:TEMP ('MinecraftBedrockUnlocker-bootstrap-' + [guid]::NewGuid().ToString('N') + '.ps1');" ^
  "try {" ^
  "  $client = New-Object System.Net.WebClient;" ^
  "  $client.Headers['Cache-Control'] = 'no-cache, no-store, max-age=0';" ^
  "  $client.Headers['Pragma'] = 'no-cache';" ^
  "  $client.Headers['User-Agent'] = 'MinecraftBedrockUnlocker';" ^
  "  $bytes = $client.DownloadData($cacheBust);" ^
  "  $utf8Strict = New-Object System.Text.UTF8Encoding -ArgumentList $false, $true;" ^
  "  $content = $utf8Strict.GetString($bytes);" ^
  "  if ($content.Length -gt 0 -and [int][char]$content[0] -eq 65279) { $content = $content.Substring(1) };" ^
  "  $tokens = $null; $errors = $null;" ^
  "  [System.Management.Automation.Language.Parser]::ParseInput($content, [ref]$tokens, [ref]$errors) | Out-Null;" ^
  "  if ($errors.Count -gt 0) {" ^
  "    Say 'O instalador baixado contem erros de sintaxe.' 'The downloaded installer contains syntax errors.' Red;" ^
  "    $errors | Select-Object -First 20 | ForEach-Object { Write-Host ('Line/Linha ' + $_.Extent.StartLineNumber + ': ' + $_.Message) -ForegroundColor Red };" ^
  "    exit 2;" ^
  "  };" ^
  "  $utf8WithBom = New-Object System.Text.UTF8Encoding -ArgumentList $true;" ^
  "  [System.IO.File]::WriteAllText($path, $content, $utf8WithBom);" ^
  "  $fileTokens = $null; $fileErrors = $null;" ^
  "  [System.Management.Automation.Language.Parser]::ParseFile($path, [ref]$fileTokens, [ref]$fileErrors) | Out-Null;" ^
  "  if ($fileErrors.Count -gt 0) {" ^
  "    Say 'O Windows PowerShell nao conseguiu ler o arquivo UTF-8 corretamente.' 'Windows PowerShell could not read the UTF-8 file correctly.' Red;" ^
  "    $fileErrors | Select-Object -First 20 | ForEach-Object { Write-Host ('Line/Linha ' + $_.Extent.StartLineNumber + ': ' + $_.Message) -ForegroundColor Red };" ^
  "    exit 3;" ^
  "  };" ^
  "  Say 'Validacao de sintaxe e UTF-8 concluida.' 'PowerShell syntax and UTF-8 validation passed.' Green;" ^
  "  if ($env:MBU_VALIDATE_ONLY -eq '1') {" ^
  "    Say 'Modo somente validacao: execucao ignorada.' 'Validation-only mode: execution skipped.' Yellow;" ^
  "    exit 0;" ^
  "  };" ^
  "  & $path %*" ^
  "} catch {" ^
  "  Write-Host $_.Exception.Message -ForegroundColor Red;" ^
  "  exit 1;" ^
  "} finally {" ^
  "  if ($client) { $client.Dispose() };" ^
  "  Remove-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue;" ^
  "}"

set "EXIT_CODE=%ERRORLEVEL%"

echo.
if not "%EXIT_CODE%"=="0" (
    if /I "%MBU_LANG%"=="pt" (
        echo O instalador falhou com o codigo %EXIT_CODE%.
    ) else (
        echo Installer failed with exit code %EXIT_CODE%.
    )
)

pause
exit /b %EXIT_CODE%
