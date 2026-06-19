@echo off
title Minecraft Bedrock Unlocker
echo ============================================================
echo  Minecraft Bedrock Unlocker by CoelhoFZ
echo  Downloading and starting the installer... / Baixando e iniciando o instalador...
echo ============================================================
echo.
powershell -NoProfile -ExecutionPolicy Bypass -Command "[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; try{[Net.ServicePointManager]::SecurityProtocol=[Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls13}catch{}; irm https://raw.githubusercontent.com/CoelhoFZ/MinecraftBedrockUnlocker/main/unlocker.ps1 | iex"
pause
