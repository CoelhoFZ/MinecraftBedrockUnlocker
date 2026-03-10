<#
.SYNOPSIS
    Minecraft Bedrock Unlocker - PowerShell Script
    
.DESCRIPTION
    Complete PowerShell-based Minecraft Bedrock Unlocker.
    Downloads OnlineFix DLLs directly from GitHub and installs them.
    No EXE needed - runs entirely in PowerShell.
    
    Usage: irm https://github.com/CoelhoFZ/MinecraftBedrockUnlocker/releases/latest/download/install.ps1 | iex
    
.NOTES
    Author: CoelhoFZ
    Version: 3.1.0
    Repository: https://github.com/CoelhoFZ/MinecraftBedrockUnlocker
#>

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'  # Speed up downloads

# ============================================================================
# Configuration
# ============================================================================
$Script:Version = "3.1.0"
$Script:RepoOwner = "CoelhoFZ"
$Script:RepoName = "MinecraftBedrockUnlocker"
$Script:RepoBranch = "main"
$Script:BaseUrl = "https://github.com/$RepoOwner/$RepoName/releases/latest/download"
$Script:DiscordUrl = "https://discord.gg/bfFdyJ3gEj"

# DLL files info (SHA256 hashes for integrity verification)
# DiskName: when set, the file is written to disk with this name instead of Name.
# This prevents AV from matching well-known filenames like OnlineFix64.dll.
$Script:OnlineFixFiles = @(
    @{ Name = "winmm.dll";        Hash = "cb8baaa2054a11628b96e474e1428a430c95321f8ac3b89764255cbd6628a9d6"; DiskName = $null },
    @{ Name = "OnlineFix64.dll";  Hash = "52cb3902999034e01bae63c6a06612d1798b0e0addc1bd4ce7680891b0229953"; DiskName = $null },
    @{ Name = "dlllist.txt";      Hash = "fc0befb4aae4b7f0eeb1c398fccea03cc795590e09db6628974520091fcfc516"; DiskName = $null },
    @{ Name = "OnlineFix.ini";    Hash = "d13a4c53389c6a35616ccbe2c09912a43369d904a52b461d734f4ebec212ddfc"; DiskName = $null }
)

function Initialize-SafeDllNames {
    <#
    .DESCRIPTION
        Generates a random innocuous-looking DLL filename to replace OnlineFix64.dll
        on disk. Also updates the OnlineFixFiles entries so all functions use
        the safe name. If a previous installation exists, reads the existing
        dlllist.txt to reuse the same name (avoids orphan files).
    #>
    param([string]$ContentPath)
    
    $safeName = $null
    
    # Check if previous install exists with a custom name
    if ($ContentPath) {
        $existingDllList = Join-Path $ContentPath "dlllist.txt"
        if (Test-Path $existingDllList) {
            $content = (Get-Content $existingDllList -ErrorAction SilentlyContinue | Where-Object { $_.Trim() }) | Select-Object -First 1
            if ($content -and $content -ne "OnlineFix64.dll" -and $content -match '\.dll$') {
                $safeName = $content.Trim()
            }
        }
    }
    
    # Generate new random name if no existing custom name found
    if (-not $safeName) {
        $prefixes = @("mcruntime", "xgbridge", "gxcore", "mcsvc", "dxhelper", "xblcore", "wgihost", "gameinput")
        $prefix = $prefixes[(Get-Random -Maximum $prefixes.Count)]
        $suffix = -join ((0..3) | ForEach-Object { [char](Get-Random -Minimum 97 -Maximum 123) })
        $safeName = "${prefix}_${suffix}64.dll"
    }
    
    $Script:SafeDllName = $safeName
    
    # Update OnlineFixFiles entries with disk names
    foreach ($f in $Script:OnlineFixFiles) {
        if ($f.Name -eq "OnlineFix64.dll") {
            $f.DiskName = $Script:SafeDllName
        }
    }
}

# ============================================================================
# Language Detection
# ============================================================================
$Script:Lang = "en"

function Detect-Language {
    try {
        $culture = (Get-Culture).Name
        switch -Wildcard ($culture) {
            "pt-BR" { $Script:Lang = "pt" }
            "pt-*"  { $Script:Lang = "pt" }
            "es-*"  { $Script:Lang = "es" }
            "fr-*"  { $Script:Lang = "fr" }
            "de-*"  { $Script:Lang = "de" }
            "zh-*"  { $Script:Lang = "zh" }
            "ru-*"  { $Script:Lang = "ru" }
            default  { $Script:Lang = "en" }
        }
    } catch {
        $Script:Lang = "en"
    }
}

function T {
    param([string]$Key)
    
    $translations = @{
        "admin_required" = @{
            en = "Administrator privileges required!"
            pt = "Privilegios de Administrador necessarios!"
            es = "Se requieren privilegios de Administrador!"
        }
        "admin_elevating" = @{
            en = "Requesting elevation..."
            pt = "Solicitando elevacao..."
            es = "Solicitando elevacion..."
        }
        "admin_ok" = @{
            en = "Running with Administrator privileges"
            pt = "Executando com privilegios de Administrador"
            es = "Ejecutando con privilegios de Administrador"
        }
        "menu_title" = @{
            en = "Available Options"
            pt = "Opcoes Disponiveis"
            es = "Opciones Disponibles"
        }
        "menu_1" = @{
            en = "Install Mod (Unlock Game)"
            pt = "Instalar Mod (Desbloquear Jogo)"
            es = "Instalar Mod (Desbloquear Juego)"
        }
        "menu_2" = @{
            en = "Restore Original (Back to Trial)"
            pt = "Restaurar Original (Voltar ao Trial)"
            es = "Restaurar Original (Volver a Trial)"
        }
        "menu_3" = @{
            en = "Open Minecraft"
            pt = "Abrir Minecraft"
            es = "Abrir Minecraft"
        }
        "menu_4" = @{
            en = "Install Minecraft (Xbox App)"
            pt = "Instalar Minecraft (Xbox App)"
            es = "Instalar Minecraft (Xbox App)"
        }
        "menu_5" = @{
            en = "Check Status"
            pt = "Verificar Status"
            es = "Verificar Estado"
        }
        "menu_6" = @{
            en = "System Diagnostics"
            pt = "Diagnostico do Sistema"
            es = "Diagnostico del Sistema"
        }
        "menu_0" = @{
            en = "Exit"
            pt = "Sair"
            es = "Salir"
        }
        "choose" = @{
            en = "Choose an option"
            pt = "Escolha uma opcao"
            es = "Elija una opcion"
        }
        "invalid" = @{
            en = "Invalid option!"
            pt = "Opcao invalida!"
            es = "Opcion invalida!"
        }
        "mc_not_found" = @{
            en = "Minecraft NOT FOUND!"
            pt = "Minecraft NAO ENCONTRADO!"
            es = "Minecraft NO ENCONTRADO!"
        }
        "mc_found" = @{
            en = "Minecraft found"
            pt = "Minecraft encontrado"
            es = "Minecraft encontrado"
        }
        "mc_path" = @{
            en = "Path"
            pt = "Caminho"
            es = "Ruta"
        }
        "installing" = @{
            en = "Installing bypass..."
            pt = "Instalando bypass..."
            es = "Instalando bypass..."
        }
        "adding_exclusions" = @{
            en = "Adding antivirus exclusions..."
            pt = "Adicionando exclusoes de antivirus..."
            es = "Agregando exclusiones de antivirus..."
        }
        "exclusion_added" = @{
            en = "Windows Defender exclusion added"
            pt = "Exclusao do Windows Defender adicionada"
            es = "Exclusion de Windows Defender agregada"
        }
        "exclusion_failed" = @{
            en = "Could not add exclusion (may need manual setup)"
            pt = "Nao foi possivel adicionar exclusao (pode precisar configurar manualmente)"
            es = "No se pudo agregar exclusion (puede necesitar configuracion manual)"
        }
        "downloading" = @{
            en = "Downloading"
            pt = "Baixando"
            es = "Descargando"
        }
        "download_ok" = @{
            en = "Downloaded successfully"
            pt = "Baixado com sucesso"
            es = "Descargado exitosamente"
        }
        "download_fail" = @{
            en = "Download FAILED"
            pt = "Download FALHOU"
            es = "Descarga FALLO"
        }
        "hash_ok" = @{
            en = "Integrity verified"
            pt = "Integridade verificada"
            es = "Integridad verificada"
        }
        "hash_fail" = @{
            en = "INTEGRITY CHECK FAILED! File may be corrupted."
            pt = "VERIFICACAO DE INTEGRIDADE FALHOU! Arquivo pode estar corrompido."
            es = "VERIFICACION DE INTEGRIDAD FALLO! Archivo puede estar corrupto."
        }
        "install_ok" = @{
            en = "Bypass installed successfully!"
            pt = "Bypass instalado com sucesso!"
            es = "Bypass instalado exitosamente!"
        }
        "install_fail" = @{
            en = "Installation failed"
            pt = "Instalacao falhou"
            es = "Instalacion fallo"
        }
        "verifying" = @{
            en = "Verifying installation..."
            pt = "Verificando instalacao..."
            es = "Verificando instalacion..."
        }
        "files_ok" = @{
            en = "All files present and verified!"
            pt = "Todos os arquivos presentes e verificados!"
            es = "Todos los archivos presentes y verificados!"
        }
        "files_missing" = @{
            en = "FILES WERE DELETED BY ANTIVIRUS!"
            pt = "ARQUIVOS FORAM DELETADOS PELO ANTIVIRUS!"
            es = "ARCHIVOS FUERON ELIMINADOS POR EL ANTIVIRUS!"
        }
        "retry_install" = @{
            en = "Retrying installation..."
            pt = "Tentando novamente..."
            es = "Reintentando instalacion..."
        }
        "av_disable" = @{
            en = "PLEASE DISABLE YOUR ANTIVIRUS TEMPORARILY:"
            pt = "POR FAVOR DESATIVE SEU ANTIVIRUS TEMPORARIAMENTE:"
            es = "POR FAVOR DESACTIVE SU ANTIVIRUS TEMPORALMENTE:"
        }
        "av_step1" = @{
            en = "1. Open Windows Security"
            pt = "1. Abra Seguranca do Windows"
            es = "1. Abra Seguridad de Windows"
        }
        "av_step2" = @{
            en = "2. Go to Virus & threat protection"
            pt = "2. Va em Protecao contra virus e ameacas"
            es = "2. Vaya a Proteccion contra virus y amenazas"
        }
        "av_step3" = @{
            en = "3. Click 'Manage settings'"
            pt = "3. Clique em 'Gerenciar configuracoes'"
            es = "3. Haga clic en 'Administrar configuracion'"
        }
        "av_step4" = @{
            en = "4. Turn OFF Real-time protection"
            pt = "4. Desative a Protecao em tempo real"
            es = "4. Desactive la Proteccion en tiempo real"
        }
        "av_step5" = @{
            en = "5. Run this script again"
            pt = "5. Execute este script novamente"
            es = "5. Ejecute este script nuevamente"
        }
        "av_folder" = @{
            en = "OR add this folder to exclusions:"
            pt = "OU adicione esta pasta as exclusoes:"
            es = "O agregue esta carpeta a las exclusiones:"
        }
        "av_detected_blocking" = @{
            en = "Your antivirus DELETED the file after download!"
            pt = "Seu antivirus DELETOU o arquivo apos o download!"
            es = "Su antivirus ELIMINO el archivo despues de la descarga!"
        }
        "av_need_disable" = @{
            en = "You need to TEMPORARILY DISABLE your antivirus protection."
            pt = "Voce precisa DESATIVAR TEMPORARIAMENTE a protecao do seu antivirus."
            es = "Necesita DESACTIVAR TEMPORALMENTE la proteccion de su antivirus."
        }
        "av_press_enter" = @{
            en = "After disabling your antivirus, press ENTER to continue..."
            pt = "Apos desativar seu antivirus, pressione ENTER para continuar..."
            es = "Despues de desactivar su antivirus, presione ENTER para continuar..."
        }
        "av_retrying_after_disable" = @{
            en = "Retrying download (antivirus should be disabled now)..."
            pt = "Tentando download novamente (antivirus deve estar desativado)..."
            es = "Reintentando descarga (antivirus deberia estar desactivado)..."
        }
        "av_still_blocking" = @{
            en = "Files are STILL being blocked! Make sure your antivirus is fully disabled."
            pt = "Arquivos AINDA estao sendo bloqueados! Certifique-se que seu antivirus esta completamente desativado."
            es = "Los archivos SIGUEN siendo bloqueados! Asegurese que su antivirus esta completamente desactivado."
        }
        "av_reenable" = @{
            en = "You can now re-enable your antivirus protection."
            pt = "Voce ja pode reativar a protecao do seu antivirus."
            es = "Ya puede reactivar la proteccion de su antivirus."
        }
        "removing" = @{
            en = "Removing bypass files..."
            pt = "Removendo arquivos do bypass..."
            es = "Eliminando archivos del bypass..."
        }
        "removed_ok" = @{
            en = "Bypass removed successfully! Game restored to Trial."
            pt = "Bypass removido com sucesso! Jogo restaurado para Trial."
            es = "Bypass eliminado exitosamente! Juego restaurado a Trial."
        }
        "resetting_license" = @{
            en = "Resetting Windows Store / Gaming Services license cache..."
            pt = "Resetando cache de licenca da Windows Store / Gaming Services..."
            es = "Reseteando cache de licencia de Windows Store / Gaming Services..."
        }
        "license_reset_partial" = @{
            en = "Could not fully reset license cache. You may need to restart your PC."
            pt = "Nao foi possivel resetar o cache de licenca completamente. Reinicie o PC se necessario."
            es = "No se pudo resetear el cache de licencia completamente. Reinicie el PC si es necesario."
        }
        "restore_reopen_note" = @{
            en = "IMPORTANT: Open Minecraft again to verify it returned to Trial mode. If still showing as Paid, restart your PC."
            pt = "IMPORTANTE: Abra o Minecraft novamente para verificar se voltou ao modo Trial. Se ainda aparecer como Pago, reinicie seu PC."
            es = "IMPORTANTE: Abra Minecraft nuevamente para verificar si volvio al modo Trial. Si sigue mostrando como Pago, reinicie su PC."
        }
        "resetting_app" = @{
            en = "Resetting Minecraft app data (clearing license cache)..."
            pt = "Resetando dados do app Minecraft (limpando cache de licenca)..."
            es = "Reseteando datos de la app Minecraft (limpiando cache de licencia)..."
        }
        "app_reset_ok" = @{
            en = "Minecraft app data reset successfully! License cache cleared."
            pt = "Dados do app Minecraft resetados! Cache de licenca limpo."
            es = "Datos de la app Minecraft reseteados! Cache de licencia limpiado."
        }
        "app_reset_fallback" = @{
            en = "Reset-AppxPackage not available. Trying manual cleanup..."
            pt = "Reset-AppxPackage nao disponivel. Tentando limpeza manual..."
            es = "Reset-AppxPackage no disponible. Intentando limpieza manual..."
        }
        "app_data_cleared" = @{
            en = "Minecraft app data manually cleared."
            pt = "Dados do app Minecraft limpos manualmente."
            es = "Datos de la app Minecraft limpiados manualmente."
        }
        "reregistering_mc" = @{
            en = "Re-registering Minecraft package (force license re-validation)..."
            pt = "Re-registrando pacote do Minecraft (forcando re-validacao de licenca)..."
            es = "Re-registrando paquete de Minecraft (forzando re-validacion de licencia)..."
        }
        "reregister_ok" = @{
            en = "Minecraft package re-registered successfully."
            pt = "Pacote do Minecraft re-registrado com sucesso."
            es = "Paquete de Minecraft re-registrado exitosamente."
        }
        "clearing_app_cache" = @{
            en = "Clearing Minecraft app cache and settings..."
            pt = "Limpando cache e configuracoes do Minecraft..."
            es = "Limpiando cache y configuraciones de Minecraft..."
        }
        "cache_cleared" = @{
            en = "App cache and settings cleared."
            pt = "Cache e configuracoes do app limpos."
            es = "Cache y configuraciones de la app limpiados."
        }
        "opening_mc" = @{
            en = "Opening Minecraft..."
            pt = "Abrindo Minecraft..."
            es = "Abriendo Minecraft..."
        }
        "mc_opened" = @{
            en = "Minecraft should open shortly"
            pt = "Minecraft deve abrir em breve"
            es = "Minecraft deberia abrirse pronto"
        }
        "opening_xbox" = @{
            en = "Opening Xbox App / Minecraft page..."
            pt = "Abrindo Xbox App / pagina do Minecraft..."
            es = "Abriendo Xbox App / pagina de Minecraft..."
        }
        "status_title" = @{
            en = "SYSTEM STATUS"
            pt = "STATUS DO SISTEMA"
            es = "ESTADO DEL SISTEMA"
        }
        "status_mc" = @{
            en = "Minecraft Installed"
            pt = "Minecraft Instalado"
            es = "Minecraft Instalado"
        }
        "status_type" = @{
            en = "Installation Type"
            pt = "Tipo de Instalacao"
            es = "Tipo de Instalacion"
        }
        "status_xbox" = @{
            en = "Xbox App (GDK) - Compatible"
            pt = "Xbox App (GDK) - Compativel"
            es = "Xbox App (GDK) - Compatible"
        }
        "status_store" = @{
            en = "Microsoft Store (UWP) - NOT COMPATIBLE!"
            pt = "Microsoft Store (UWP) - NAO COMPATIVEL!"
            es = "Microsoft Store (UWP) - NO COMPATIBLE!"
        }
        "status_bypass" = @{
            en = "Bypass Status"
            pt = "Status do Bypass"
            es = "Estado del Bypass"
        }
        "status_installed" = @{
            en = "INSTALLED"
            pt = "INSTALADO"
            es = "INSTALADO"
        }
        "status_not_installed" = @{
            en = "NOT INSTALLED"
            pt = "NAO INSTALADO"
            es = "NO INSTALADO"
        }
        "status_partial" = @{
            en = "PARTIAL (files missing - antivirus deleted them?)"
            pt = "PARCIAL (arquivos faltando - antivirus deletou?)"
            es = "PARCIAL (archivos faltantes - antivirus los elimino?)"
        }
        "status_av" = @{
            en = "Antivirus"
            pt = "Antivirus"
            es = "Antivirus"
        }
        "status_defender_on" = @{
            en = "Active"
            pt = "Ativo"
            es = "Activo"
        }
        "status_defender_off" = @{
            en = "Not detected"
            pt = "Nao detectado"
            es = "No detectado"
        }
        "persistence_ok" = @{
            en = "Reboot protection enabled (files auto-restore after restart)"
            pt = "Protecao contra reboot ativada (arquivos restauram apos reiniciar)"
            es = "Proteccion contra reboot activada (archivos se restauran al reiniciar)"
        }
        "persistence_fail" = @{
            en = "Could not enable reboot protection (Scheduled Task failed)"
            pt = "Nao foi possivel ativar protecao contra reboot (Tarefa Agendada falhou)"
            es = "No se pudo activar proteccion contra reboot (Tarea Programada fallo)"
        }
        "persistence_removed" = @{
            en = "Reboot protection removed"
            pt = "Protecao contra reboot removida"
            es = "Proteccion contra reboot eliminada"
        }
        "status_persistence" = @{
            en = "Reboot Protection"
            pt = "Protecao Reboot"
            es = "Proteccion Reboot"
        }
        "status_gaming" = @{
            en = "Gaming Services"
            pt = "Servicos de Jogos"
            es = "Servicios de Juegos"
        }
        "status_running" = @{
            en = "Running"
            pt = "Rodando"
            es = "Ejecutandose"
        }
        "status_stopped" = @{
            en = "Stopped"
            pt = "Parado"
            es = "Detenido"
        }
        "diag_title" = @{
            en = "SYSTEM DIAGNOSTICS"
            pt = "DIAGNOSTICO DO SISTEMA"
            es = "DIAGNOSTICO DEL SISTEMA"
        }
        "diag_xbox_app" = @{
            en = "Xbox App"
            pt = "Xbox App"
            es = "Xbox App"
        }
        "diag_mc_install" = @{
            en = "Minecraft Installation"
            pt = "Instalacao do Minecraft"
            es = "Instalacion de Minecraft"
        }
        "diag_type" = @{
            en = "Installation Type"
            pt = "Tipo de Instalacao"
            es = "Tipo de Instalacion"
        }
        "diag_permissions" = @{
            en = "Folder Permissions"
            pt = "Permissoes de Pasta"
            es = "Permisos de Carpeta"
        }
        "diag_gaming" = @{
            en = "Gaming Services"
            pt = "Servicos de Jogos"
            es = "Servicios de Juegos"
        }
        "diag_integrity" = @{
            en = "Game Integrity"
            pt = "Integridade do Jogo"
            es = "Integridad del Juego"
        }
        "diag_bypass" = @{
            en = "Bypass Files"
            pt = "Arquivos do Bypass"
            es = "Archivos del Bypass"
        }
        "diag_all_ok" = @{
            en = "All checks passed! System is ready."
            pt = "Todas as verificacoes passaram! Sistema pronto."
            es = "Todas las verificaciones pasaron! Sistema listo."
        }
        "yes" = @{ en = "Yes"; pt = "Sim"; es = "Si" }
        "no" = @{ en = "No"; pt = "Nao"; es = "No" }
        "ok" = @{ en = "OK"; pt = "OK"; es = "OK" }
        "found" = @{ en = "Found"; pt = "Encontrado"; es = "Encontrado" }
        "not_found" = @{ en = "Not Found"; pt = "Nao encontrado"; es = "No encontrado" }
        "writable" = @{ en = "Writable"; pt = "Gravavel"; es = "Escribible" }
        "no_write" = @{ en = "No write access"; pt = "Sem acesso de escrita"; es = "Sin acceso de escritura" }
        "open_now" = @{
            en = "You can now open Minecraft from the Start Menu!"
            pt = "Agora voce pode abrir o Minecraft pelo Menu Iniciar!"
            es = "Ahora puede abrir Minecraft desde el Menu Inicio!"
        }
        "mc_running" = @{
            en = "Minecraft is running. Closing it first..."
            pt = "Minecraft esta rodando. Fechando primeiro..."
            es = "Minecraft esta ejecutandose. Cerrando primero..."
        }
        "press_enter" = @{
            en = "Press Enter to continue..."
            pt = "Pressione Enter para continuar..."
            es = "Presione Enter para continuar..."
        }
        "exiting" = @{
            en = "Exiting... Goodbye!"
            pt = "Saindo... Ate mais!"
            es = "Saliendo... Hasta luego!"
        }
        "start_gaming" = @{
            en = "Starting Gaming Services..."
            pt = "Iniciando Gaming Services..."
            es = "Iniciando Gaming Services..."
        }
        "install_xbox_hint" = @{
            en = "Install Minecraft Trial from Xbox App (NOT Microsoft Store!)"
            pt = "Instale o Minecraft Trial pelo Xbox App (NAO Microsoft Store!)"
            es = "Instale Minecraft Trial desde Xbox App (NO Microsoft Store!)"
        }
        "repair_hint" = @{
            en = "Repair or reinstall Minecraft from Xbox App"
            pt = "Repare ou reinstale o Minecraft pelo Xbox App"
            es = "Repare o reinstale Minecraft desde Xbox App"
        }
        "run_admin_hint" = @{
            en = "Run this script as Administrator"
            pt = "Execute este script como Administrador"
            es = "Ejecute este script como Administrador"
        }
        "restart_gaming_hint" = @{
            en = "Restart Gaming Services or reinstall Xbox App"
            pt = "Reinicie os Servicos de Jogos ou reinstale o Xbox App"
            es = "Reinicie los Servicios de Juegos o reinstale Xbox App"
        }
        "bd_suspending" = @{
            en = "Antivirus detected - trying to pause protection automatically..."
            pt = "Antivirus detectado - tentando pausar protecao automaticamente..."
            es = "Antivirus detectado - intentando pausar proteccion automaticamente..."
        }
        "bd_suspended" = @{
            en = "Antivirus paused! Installing files now..."
            pt = "Antivirus pausado! Instalando arquivos agora..."
            es = "Antivirus pausado! Instalando archivos ahora..."
        }
        "bd_resumed" = @{
            en = "Antivirus protection restored."
            pt = "Protecao do antivirus restaurada."
            es = "Proteccion del antivirus restaurada."
        }
        "bd_suspend_failed" = @{
            en = "Could not pause automatically. Please follow the instructions:"
            pt = "Nao foi possivel pausar automaticamente. Siga as instrucoes:"
            es = "No se pudo pausar automaticamente. Siga las instrucciones:"
        }
        "bd_onaccess_title" = @{
            en = "BITDEFENDER - ACTION REQUIRED: ADD EXCLUSION TO PLAY MINECRAFT"
            pt = "BITDEFENDER - ACAO NECESSARIA: ADICIONE A EXCLUSAO PARA JOGAR MINECRAFT"
            es = "BITDEFENDER - ACCION REQUERIDA: AGREGUE EXCLUSION PARA JUGAR MINECRAFT"
        }
        "bd_onaccess_reason" = @{
            en = "Bitdefender Free blocks the mod when Minecraft LOADS it (not during install)."
            pt = "O Bitdefender Free bloqueia o mod quando o Minecraft CARREGA (nao durante a instalacao)."
            es = "Bitdefender Free bloquea el mod cuando Minecraft lo CARGA (no durante la instalacion)."
        }
        "bd_onaccess_cannot_autofix" = @{
            en = "This CANNOT be fixed automatically - Bitdefender Free has no CLI or API for exclusions."
            pt = "Isso NAO pode ser corrigido automaticamente - o Bitdefender Free nao tem CLI ou API para exclusoes."
            es = "Esto NO puede corregirse automaticamente - Bitdefender Free no tiene CLI ni API para exclusiones."
        }
        "bd_onaccess_clipboard" = @{
            en = ">> Path COPIED to clipboard - just press Ctrl+V in Bitdefender!"
            pt = ">> Caminho COPIADO para a area de transferencia - so pressione Ctrl+V no Bitdefender!"
            es = ">> Ruta COPIADA al portapapeles - solo presione Ctrl+V en Bitdefender!"
        }
        "bd_onaccess_wait" = @{
            en = "After adding the exclusion in Bitdefender, press ENTER here to continue..."
            pt = "Apos adicionar a exclusao no Bitdefender, pressione ENTER aqui para continuar..."
            es = "Despues de agregar la exclusion en Bitdefender, presione ENTER aqui para continuar..."
        }
        "bd_onaccess_verified" = @{
            en = "Exclusion confirmed in Bitdefender! Minecraft will work correctly now."
            pt = "Exclusao confirmada no Bitdefender! O Minecraft vai funcionar corretamente agora."
            es = "Exclusion confirmada en Bitdefender! Minecraft funcionara correctamente ahora."
        }
        "bd_onaccess_not_detected" = @{
            en = "Exclusion NOT detected yet. Please follow the steps again."
            pt = "Exclusao NAO detectada ainda. Por favor siga os passos novamente."
            es = "Exclusion NO detectada aun. Por favor siga los pasos nuevamente."
        }
        "bd_onaccess_skipped" = @{
            en = "WARNING: Skipped exclusion - Minecraft WILL FAIL to load. See TROUBLESHOOTING.md."
            pt = "AVISO: Exclusao ignorada - O Minecraft VAI FALHAR ao carregar. Veja TROUBLESHOOTING.md."
            es = "AVISO: Exclusion omitida - Minecraft FALLARA al cargar. Ver TROUBLESHOOTING.md."
        }
        "bd_onaccess_attempt" = @{
            en = "Attempt"
            pt = "Tentativa"
            es = "Intento"
        }
    }
    
    $entry = $translations[$Key]
    if ($entry -and $entry[$Script:Lang]) {
        return $entry[$Script:Lang]
    } elseif ($entry -and $entry["en"]) {
        return $entry["en"]
    }
    return $Key
}

# ============================================================================
# Console Appearance
# ============================================================================

function Set-ConsoleAppearance {
    try {
        $Host.UI.RawUI.BackgroundColor = 'Black'
        $Host.UI.RawUI.ForegroundColor = 'Gray'
        $Host.UI.RawUI.WindowTitle = "Minecraft Bedrock Unlocker v$Script:Version"

        # Detect screen resolution to size window proportionally
        $screenW = 1920
        $screenH = 1080
        try {
            Add-Type -AssemblyName System.Windows.Forms -ErrorAction SilentlyContinue
            $screen = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
            $screenW = $screen.Width
            $screenH = $screen.Height
        } catch { }

        # Estimate console columns/rows from screen pixels
        # Typical conhost char: ~8x16px. Target ~85% of screen width, ~80% height.
        $targetWidth  = [Math]::Max(80,  [Math]::Min(130, [int]($screenW * 0.85 / 8)))
        $targetHeight = [Math]::Max(28,  [Math]::Min(50,  [int]($screenH * 0.80 / 16)))

        $maxSize = $Host.UI.RawUI.MaxPhysicalWindowSize
        $w = [Math]::Min($targetWidth,  $maxSize.Width)
        $h = [Math]::Min($targetHeight, $maxSize.Height)

        $curBuf = $Host.UI.RawUI.BufferSize
        $newBuf = New-Object System.Management.Automation.Host.Size($w, 1000)
        $newWin = New-Object System.Management.Automation.Host.Size($w, $h)

        if ($curBuf.Width -gt $w) {
            $Host.UI.RawUI.WindowSize = $newWin
            $Host.UI.RawUI.BufferSize = $newBuf
        } else {
            $Host.UI.RawUI.BufferSize = $newBuf
            $Host.UI.RawUI.WindowSize = $newWin
        }

        # Center window on screen
        try {
            Add-Type -AssemblyName System.Windows.Forms -ErrorAction SilentlyContinue
            $charW = 8; $charH = 16
            $winPixW = $w * $charW
            $winPixH = $h * $charH
            $posX = [Math]::Max(0, [int](($screenW - $winPixW) / 2))
            $posY = [Math]::Max(0, [int](($screenH - $winPixH) / 2))
            $Host.UI.RawUI.WindowPosition = New-Object System.Management.Automation.Host.Coordinates($posX / $charW, 0)
        } catch { }

        Clear-Host
    } catch {
        try { Clear-Host } catch { }
    }
}

# ============================================================================
# UI Functions
# ============================================================================

function Write-C {
    param([string]$Text, [ConsoleColor]$Color = 'White', [switch]$NoNewline)
    if ($NoNewline) {
        Write-Host $Text -ForegroundColor $Color -NoNewline
    } else {
        Write-Host $Text -ForegroundColor $Color
    }
}

function Write-OK     { param([string]$Msg)  Write-C "  [OK] $Msg" Green }
function Write-Err    { param([string]$Msg)  Write-C "  [ERROR] $Msg" Red }
function Write-Warn   { param([string]$Msg)  Write-C "  [!] $Msg" Yellow }
function Write-Info   { param([string]$Msg)  Write-C "  [*] $Msg" Cyan }
function Write-Line   { Write-C "  ============================================================" DarkGray }

function Show-Banner {
    Clear-Host
    Write-C ""
    Write-C "  ============================================================" Cyan
    Write-C "   __  __ _                            __ _   " Cyan
    Write-C "  |  \/  (_)_ __   ___  ___ _ __ __ _ / _| |_ " Cyan
    Write-C "  | |\/| | | '_ \ / _ \/ __| '__/ _' | |_| __|" Cyan
    Write-C "  | |  | | | | | |  __/ (__| | | (_| |  _| |_ " Cyan
    Write-C "  |_|  |_|_|_| |_|\___|\___|_|  \__,_|_|  \__|" Cyan
    Write-C "     ____           _                 _        " Cyan
    Write-C "    | __ )  ___  __| |_ __ ___   ___| | __    " Cyan
    Write-C "    |  _ \ / _ \/ _' | '__/ _ \ / __| |/ /    " Cyan
    Write-C "    | |_) |  __/ (_| | | | (_) | (__|   <     " Cyan
    Write-C "    |____/ \___|\__,_|_|  \___/ \___|_|\_\    " Cyan
    Write-C "                     Unlocker by CoelhoFZ      " Cyan
    Write-C "  ============================================================" Cyan
    Write-C "                         v$Script:Version (PowerShell)" DarkGray
    Write-C ""
}

function Show-Menu {
    Write-C ""
    Write-C "    $(T 'menu_title')" Green
    Write-C ""
    Write-C "    " -NoNewline; Write-C "[1]" Green -NoNewline; Write-C " $(T 'menu_1')"
    Write-C "    " -NoNewline; Write-C "[2]" Green -NoNewline; Write-C " $(T 'menu_2')"
    Write-C "    " -NoNewline; Write-C "[3]" Green -NoNewline; Write-C " $(T 'menu_3')"
    Write-C "    " -NoNewline; Write-C "[4]" Yellow -NoNewline; Write-C " $(T 'menu_4')"
    Write-C "    " -NoNewline; Write-C "[5]" Cyan -NoNewline; Write-C " $(T 'menu_5')"
    Write-C "    " -NoNewline; Write-C "[6]" Cyan -NoNewline; Write-C " $(T 'menu_6')"
    Write-C "    " -NoNewline; Write-C "[0]" Red -NoNewline; Write-C " $(T 'menu_0')"
    Write-C ""
    Write-Line
    Write-C ""
}

function Wait-Enter {
    Write-C ""
    Write-C "  $(T 'press_enter')" DarkGray
    $null = Read-Host
}

# ============================================================================
# Core Functions
# ============================================================================

function Test-Admin {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Request-Elevation {
    Write-Warn (T 'admin_required')
    Write-Info (T 'admin_elevating')
    
    try {
        $scriptUrl = "$Script:BaseUrl/install.ps1"
        $cmd = "Set-ExecutionPolicy Bypass -Scope Process -Force; [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; iex (irm '$scriptUrl')"
        Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"$cmd`"" -Verb RunAs
        # Close this (non-admin) window automatically after 2 seconds
        Write-OK "Elevated window opened. This window will close..."
        Start-Sleep -Seconds 2
        exit
    }
    catch {
        Write-Err "Failed to elevate. Please run PowerShell as Administrator."
        Write-Warn "  Right-click PowerShell -> Run as administrator"
        Wait-Enter
    }
}

function Find-MinecraftPath {
    # Priority 1: XboxGames on all drives (GDK install - compatible)
    $drives = @("C") + @((Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Root -match '^[D-Z]:\\$' }).Name)
    foreach ($driveLetter in $drives) {
        $path = "${driveLetter}:\XboxGames\Minecraft for Windows\Content"
        if (Test-Path $path) { return $path }
    }

    # Priority 2: WindowsApps (UWP - not recommended but detect it)
    $programFiles = $env:ProgramFiles
    if (-not $programFiles) { $programFiles = "C:\Program Files" }
    $windowsApps = Join-Path $programFiles "WindowsApps"
    
    if (Test-Path $windowsApps) {
        try {
            $mcFolders = Get-ChildItem $windowsApps -Directory -ErrorAction SilentlyContinue | 
                         Where-Object { $_.Name -like "Microsoft.Minecraft*8wekyb3d8bbwe*" }
            foreach ($folder in $mcFolders) {
                $contentPath = Join-Path $folder.FullName "Content"
                if (Test-Path $contentPath) { return $contentPath }
            }
        } catch { }
    }

    return $null
}

function Test-MinecraftRunning {
    $processes = Get-Process -Name "Minecraft.Windows" -ErrorAction SilentlyContinue
    return ($null -ne $processes)
}

function Stop-Minecraft {
    Write-Warn (T 'mc_running')
    Get-Process -Name "Minecraft.Windows" -ErrorAction SilentlyContinue | Stop-Process -Force
    Start-Sleep -Seconds 3
}

function Test-DefenderActive {
    try {
        $status = Get-MpComputerStatus -ErrorAction SilentlyContinue
        return $status.RealTimeProtectionEnabled
    } catch {
        return $false
    }
}

# ============================================================================
# Antivirus Detection & Management (Multi-AV Support)
# ============================================================================

function Detect-Antivirus {
    <#
    .DESCRIPTION
        Detects ALL installed/active antivirus products on the system.
        Returns an array of hashtables with Name, Type, Active status.
    #>
    $detected = @()
    
    # Method 1: WMI/CIM (works for most registered AV products)
    try {
        $avProducts = Get-CimInstance -Namespace "root/SecurityCenter2" -ClassName "AntiVirusProduct" -ErrorAction SilentlyContinue
        foreach ($av in $avProducts) {
            $name = $av.displayName
            $state = $av.productState
            # Bit 12 (4096) = enabled/active
            $isActive = (($state -band 0x1000) -ne 0)
            
            $type = "unknown"
            if ($name -match "Bitdefender") {
                if ($name -match "Antivirus Free" -or (Test-Path "HKLM:\SOFTWARE\Bitdefender\Bitdefender Antivirus Free")) {
                    $type = "bitdefender_free"
                } else {
                    $type = "bitdefender"
                }
            }
            elseif ($name -match "Kaspersky")  { $type = "kaspersky" }
            elseif ($name -match "Avast")      { $type = "avast" }
            elseif ($name -match "AVG")        { $type = "avg" }
            elseif ($name -match "Norton")     { $type = "norton" }
            elseif ($name -match "McAfee")     { $type = "mcafee" }
            elseif ($name -match "ESET")       { $type = "eset" }
            elseif ($name -match "Malwarebytes") { $type = "malwarebytes" }
            elseif ($name -match "Defender")   { $type = "defender" }
            elseif ($name -match "Trend.?Micro") { $type = "trendmicro" }
            
            $detected += @{ Name = $name; Type = $type; Active = $isActive }
        }
    } catch { }
    
    # Method 2: Fallback path-based detection if WMI returns nothing useful
    if ($detected.Count -eq 0) {
        $bdType = if (Test-Path "HKLM:\SOFTWARE\Bitdefender\Bitdefender Antivirus Free") { "bitdefender_free" } else { "bitdefender" }
        $pathChecks = @(
            @{ Path = "$env:ProgramFiles\Bitdefender*"; Type = $bdType; Name = "Bitdefender" },
            @{ Path = "${env:ProgramFiles(x86)}\Bitdefender*"; Type = $bdType; Name = "Bitdefender" },
            @{ Path = "$env:ProgramFiles\Kaspersky Lab*"; Type = "kaspersky"; Name = "Kaspersky" },
            @{ Path = "$env:ProgramFiles\Avast Software*"; Type = "avast"; Name = "Avast" },
            @{ Path = "$env:ProgramFiles\AVG*"; Type = "avg"; Name = "AVG" },
            @{ Path = "$env:ProgramFiles\Norton*"; Type = "norton"; Name = "Norton" },
            @{ Path = "$env:ProgramFiles\McAfee*"; Type = "mcafee"; Name = "McAfee" },
            @{ Path = "$env:ProgramFiles\ESET*"; Type = "eset"; Name = "ESET" },
            @{ Path = "$env:ProgramFiles\Malwarebytes*"; Type = "malwarebytes"; Name = "Malwarebytes" }
        )
        foreach ($check in $pathChecks) {
            if (Get-Item $check.Path -ErrorAction SilentlyContinue) {
                $detected += @{ Name = $check.Name; Type = $check.Type; Active = $true }
            }
        }
        # Always check Defender separately
        if (Test-DefenderActive) {
            $detected += @{ Name = "Windows Defender"; Type = "defender"; Active = $true }
        }
    }
    
    return $detected
}

function Get-AVExclusionInstructions {
    param([string]$AVType, [string]$AVName, [string]$FolderPath)
    
    $lang = $Script:Lang
    
    switch ($AVType) {
        "bitdefender_free" {
            if ($lang -eq "pt") {
                return @(
                    "=== BITDEFENDER FREE - EXCECAO OBRIGATORIA ==="
                    ""
                    "  ATENCAO: Desativar o Shield NAO resolve o problema!"
                    "  O Bitdefender bloqueia os arquivos ao CARREGAR (durante o jogo)."
                    "  Voce PRECISA adicionar a pasta como EXCECAO permanente."
                    ""
                    "  PASSO A PASSO (o Bitdefender ja esta aberto):"
                    "  1. Na janela do Bitdefender, clique em 'Protecao' (icone de escudo no menu lateral)"
                    "  2. Clique em 'Antivirus'"
                    "  3. Clique na aba 'Configuracoes' (icone de engrenagem)"
                    "  4. Role para baixo e clique em 'Gerenciar Excecoes'"
                    "  5. Clique em '+ Adicionar uma Excecao'"
                    "  6. COLE (Ctrl+V) o caminho - ja foi copiado automaticamente:"
                    "     ===> $FolderPath"
                    "  7. MARQUE TODAS as opcoes (Verificacao em tempo real, Sob demanda, ATD)"
                    "  8. Clique em 'Salvar'"
                    "  9. Volte aqui e pressione ENTER"
                )
            } else {
                return @(
                    "=== BITDEFENDER FREE - MANDATORY EXCLUSION ==="
                    ""
                    "  WARNING: Disabling the Shield does NOT fix this!"
                    "  Bitdefender blocks files at LOAD TIME (while the game runs)."
                    "  You MUST add the folder as a permanent EXCLUSION."
                    ""
                    "  STEP BY STEP (Bitdefender is already open):"
                    "  1. In the Bitdefender window, click 'Protection' (shield icon in left menu)"
                    "  2. Click 'Antivirus'"
                    "  3. Click the 'Settings' tab (gear icon)"
                    "  4. Scroll down and click 'Manage Exceptions'"
                    "  5. Click '+ Add an Exception'"
                    "  6. PASTE (Ctrl+V) the path - already copied automatically:"
                    "     ===> $FolderPath"
                    "  7. CHECK ALL options (On-access scan, On-demand scan, ATC)"
                    "  8. Click 'Save'"
                    "  9. Come back here and press ENTER"
                )
            }
        }
        "bitdefender" {
            if ($lang -eq "pt") {
                return @(
                    "=== SEU ANTIVIRUS - Instrucoes para adicionar exclusao ==="
                    ""
                    "METODO RAPIDO (Recomendado):"
                    "  1. Clique no icone do seu antivirus na bandeja do sistema (ao lado do relogio)"
                    "  2. Clique em 'Protecao' (icone de escudo)"
                    "  3. Em 'Antivirus', clique em 'Configuracoes'"
                    "  4. Va em 'Gerenciar Exclusoes' ou 'Exclusoes'"
                    "  5. Clique em 'Adicionar' > 'Pasta'"
                    "  6. Selecione: $FolderPath"
                    "  7. Marque TODAS as opcoes (On-Access, On-Demand, etc.)"
                    "  8. Clique em 'Salvar' e execute este script novamente"
                    ""
                    "METODO ALTERNATIVO (Desativar temporariamente):"
                    "  1. Clique no icone do seu antivirus na bandeja"
                    "  2. Va em 'Protecao' > 'Antivirus'"
                    "  3. Desative o 'Shield' (protecao em tempo real) por 15 minutos"
                    "  4. Execute este script novamente"
                    "  5. Reative seu antivirus depois"
                )
            } else {
                return @(
                    "=== YOUR ANTIVIRUS - How to add exclusion ==="
                    ""
                    "QUICK METHOD (Recommended):"
                    "  1. Click your antivirus icon in the system tray (near clock)"
                    "  2. Click 'Protection' (shield icon)"
                    "  3. Under 'Antivirus', click 'Settings'"
                    "  4. Go to 'Manage Exclusions' or 'Exclusions'"
                    "  5. Click 'Add' > 'Folder'"
                    "  6. Select: $FolderPath"
                    "  7. Check ALL options (On-Access, On-Demand, etc.)"
                    "  8. Click 'Save' and run this script again"
                    ""
                    "ALTERNATIVE (Temporarily disable):"
                    "  1. Click your antivirus tray icon"
                    "  2. Go to 'Protection' > 'Antivirus'"
                    "  3. Disable 'Shield' (real-time protection) for 15 minutes"
                    "  4. Run this script again"
                    "  5. Re-enable your antivirus afterward"
                )
            }
        }
        "kaspersky" {
            if ($lang -eq "pt") {
                return @(
                    "=== SEU ANTIVIRUS ==="
                    "  1. Abra seu antivirus"
                    "  2. Configuracoes > Ameacas e Exclusoes"
                    "  3. Gerenciar Exclusoes > Adicionar"
                    "  4. Adicione: $FolderPath"
                )
            } else {
                return @(
                    "=== YOUR ANTIVIRUS ==="
                    "  1. Open your antivirus"
                    "  2. Settings > Threats and Exclusions"
                    "  3. Manage Exclusions > Add"
                    "  4. Add: $FolderPath"
                )
            }
        }
        "avast" {
            return @(
                "=== YOUR ANTIVIRUS ==="
                "  Settings > General > Exceptions > Add Exception"
                "  Add: $FolderPath"
            )
        }
        "avg" {
            return @(
                "=== YOUR ANTIVIRUS ==="
                "  Menu > Settings > General > Exceptions > Add Exception"
                "  Add: $FolderPath"
            )
        }
        "norton" {
            return @(
                "=== YOUR ANTIVIRUS ==="
                "  Settings > Antivirus > Scans and Risks > Items to Exclude"
                "  Add: $FolderPath"
            )
        }
        "eset" {
            return @(
                "=== YOUR ANTIVIRUS ==="
                "  Setup > Advanced Setup > Detection Engine > Exclusions"
                "  Add: $FolderPath"
            )
        }
        "mcafee" {
            return @(
                "=== YOUR ANTIVIRUS ==="
                "  PC Security > Real-Time Scanning > Excluded Files"
                "  Add: $FolderPath"
            )
        }
        "defender" {
            if ($lang -eq "pt") {
                return @(
                    "=== SEU ANTIVIRUS ==="
                    "  1. Abra 'Seguranca do Windows'"
                    "  2. Protecao contra virus e ameacas"
                    "  3. Gerenciar configuracoes"
                    "  4. Exclusoes > Adicionar exclusao > Pasta"
                    "  5. Selecione: $FolderPath"
                )
            } else {
                return @(
                    "=== YOUR ANTIVIRUS ==="
                    "  1. Open 'Windows Security'"
                    "  2. Virus & threat protection"
                    "  3. Manage settings"
                    "  4. Exclusions > Add exclusion > Folder"
                    "  5. Select: $FolderPath"
                )
            }
        }
        default {
            if ($lang -eq "pt") {
                return @(
                    "=== SEU ANTIVIRUS ==="
                    "  Procure por 'Exclusoes' ou 'Excecoes' nas configuracoes"
                    "  Adicione esta pasta: $FolderPath"
                )
            } else {
                return @(
                    "=== YOUR ANTIVIRUS ==="
                    "  Look for 'Exclusions' or 'Exceptions' in settings"
                    "  Add this folder: $FolderPath"
                )
            }
        }
    }
}

function Add-AllAVExclusions {
    param([string]$Path)
    
    Write-Info (T 'adding_exclusions')
    $avList = Detect-Antivirus
    $anyAdded = $false
    
    # Show detected antivirus products
    if ($avList.Count -gt 0) {
        foreach ($av in $avList) {
            $statusText = if ($av.Active) { "Ativo" } else { "Inativo" }
            if ($Script:Lang -ne "pt") { $statusText = if ($av.Active) { "Active" } else { "Inactive" } }
            Write-Info "  Antivirus: $($av.Name) ($statusText)"
        }
    } else {
        if ($Script:Lang -eq "pt") {
            Write-Info "  Nenhum antivirus detectado."
        } else {
            Write-Info "  No antivirus detected."
        }
    }
    
    foreach ($av in $avList) {
        switch ($av.Type) {
            "defender" {
                try {
                    Add-MpPreference -ExclusionPath $Path -ErrorAction SilentlyContinue
                    # Individual DLL exclusions
                    foreach ($dll in @("winmm.dll", (Get-DiskName -SourceName "OnlineFix64.dll"))) {
                        Add-MpPreference -ExclusionPath (Join-Path $Path $dll) -ErrorAction SilentlyContinue
                    }
                    Add-MpPreference -ExclusionExtension ".dll" -ErrorAction SilentlyContinue
                    Add-MpPreference -ExclusionProcess "Minecraft.Windows.exe" -ErrorAction SilentlyContinue
                    Write-OK "Windows Defender: $(T 'exclusion_added')"
                    $anyAdded = $true
                } catch {
                    if ($Script:Lang -eq "pt") {
                        Write-Warn "Windows Defender: Nao foi possivel adicionar exclusao automaticamente."
                        Write-Warn "  Adicione manualmente: Seguranca do Windows > Protecao contra virus > Exclusoes > Pasta: $Path"
                    } else {
                        Write-Warn "Windows Defender: Could not add exclusion automatically."
                        Write-Warn "  Add manually: Windows Security > Virus protection > Exclusions > Folder: $Path"
                    }
                }
            }
            "bitdefender_free" {
                # BD Free has no CLI exclusion tool - handled later in the flow
                if ($Script:Lang -eq "pt") {
                    Write-Info "  Bitdefender Free: exclusao sera configurada apos a instalacao."
                } else {
                    Write-Info "  Bitdefender Free: exclusion will be configured after installation."
                }
            }
            "bitdefender" {
                $bdCmd = $null
                $bdPaths = @(
                    "$env:ProgramFiles\Bitdefender\Bitdefender Security\product.console.exe",
                    "$env:ProgramFiles\Bitdefender\Endpoint Security\product.console.exe",
                    "$env:ProgramFiles\Bitdefender Agent\ProductAgentService.exe"
                )
                foreach ($p in $bdPaths) {
                    if (Test-Path $p) { $bdCmd = $p; break }
                }
                if ($bdCmd) {
                    try {
                        & $bdCmd /c SetExclusion path="$Path" -ErrorAction SilentlyContinue
                        Write-OK "Bitdefender: $(T 'exclusion_added')"
                        $anyAdded = $true
                    } catch {
                        if ($Script:Lang -eq "pt") {
                            Write-Warn "Bitdefender: Nao foi possivel adicionar exclusao automaticamente."
                        } else {
                            Write-Warn "Bitdefender: Could not add exclusion automatically."
                        }
                    }
                } else {
                    if ($Script:Lang -eq "pt") {
                        Write-Warn "Bitdefender: Nao foi possivel adicionar exclusao automaticamente."
                    } else {
                        Write-Warn "Bitdefender: Could not add exclusion automatically."
                    }
                }
            }
            default {
                if ($av.Active) {
                    if ($Script:Lang -eq "pt") {
                        Write-Warn "$($av.Name): Nao foi possivel adicionar exclusao automaticamente."
                        Write-Warn "  Adicione esta pasta nas exclusoes do seu antivirus: $Path"
                    } else {
                        Write-Warn "$($av.Name): Could not add exclusion automatically."
                        Write-Warn "  Add this folder to your antivirus exclusions: $Path"
                    }
                }
            }
        }
    }
    
    return $avList
}

function Open-AVSettings {
    param([string]$AVType)
    
    switch ($AVType) {
        "bitdefender_free" {
            # Bitdefender Free UI is in 'Bitdefender Security App' folder
            $bdFreePaths = @(
                "$env:ProgramFiles\Bitdefender\Bitdefender Security App\bdagent.exe",
                "$env:ProgramFiles\Bitdefender\Bitdefender Security\bdagent.exe",
                "${env:ProgramFiles(x86)}\Bitdefender\Bitdefender Security App\bdagent.exe"
            )
            foreach ($p in $bdFreePaths) {
                if (Test-Path $p) {
                    try { Start-Process $p -ErrorAction SilentlyContinue; return $true } catch { }
                }
            }
            # Fallback: Start Menu shortcut
            try {
                $shortcut = Get-ChildItem "$env:ProgramData\Microsoft\Windows\Start Menu\Programs" -Recurse -Filter "*Bitdefender*" -ErrorAction SilentlyContinue | Select-Object -First 1
                if ($shortcut) {
                    Start-Process $shortcut.FullName -ErrorAction SilentlyContinue
                    return $true
                }
            } catch { }
        }
        "bitdefender" {
            # Try to open Bitdefender UI
            $bdUIPaths = @(
                "$env:ProgramFiles\Bitdefender\Bitdefender Security\bdagent.exe",
                "$env:ProgramFiles\Bitdefender\Bitdefender Security\bdui.exe",
                "${env:ProgramFiles(x86)}\Bitdefender\Bitdefender Security\bdagent.exe"
            )
            foreach ($p in $bdUIPaths) {
                if (Test-Path $p) {
                    try { Start-Process $p -ErrorAction SilentlyContinue; return $true } catch { }
                }
            }
            # Try via Start Menu shortcut
            try {
                $shortcut = Get-ChildItem "$env:ProgramData\Microsoft\Windows\Start Menu\Programs" -Recurse -Filter "*Bitdefender*" -ErrorAction SilentlyContinue | Select-Object -First 1
                if ($shortcut) {
                    Start-Process $shortcut.FullName -ErrorAction SilentlyContinue
                    return $true
                }
            } catch { }
        }
        "kaspersky" {
            try { Start-Process "avp.exe" -ErrorAction SilentlyContinue; return $true } catch { }
        }
        "avast" {
            $avastPath = "$env:ProgramFiles\Avast Software\Avast\AvastUI.exe"
            if (Test-Path $avastPath) {
                try { Start-Process $avastPath -ErrorAction SilentlyContinue; return $true } catch { }
            }
        }
        "avg" {
            $avgPath = "$env:ProgramFiles\AVG\Antivirus\AVGUI.exe"
            if (Test-Path $avgPath) {
                try { Start-Process $avgPath -ErrorAction SilentlyContinue; return $true } catch { }
            }
        }
        "defender" {
            try { Start-Process "windowsdefender://threatsettings" -ErrorAction SilentlyContinue; return $true } catch { }
        }
    }
    return $false
}

function Test-BDFreeExclusion {
    <#
    .DESCRIPTION
        Checks if the given path is listed in Bitdefender Free's ExcludeMgr settings.
        Returns $true if the exclusion exists with on-access flag (bit 0).
    #>
    param([string]$FolderPath)
    
    try {
        $settingsDir = Join-Path $env:ProgramData 'Bitdefender\Desktop\.settings\data'
        if (-not (Test-Path $settingsDir)) { return $false }
        
        $dataDir = Get-ChildItem $settingsDir -Directory -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -ne '00000000-0000-0000-0000-000000000000' } |
            Sort-Object LastWriteTime -Descending |
            Select-Object -First 1
        
        if (-not $dataDir) { return $false }
        
        $dataFile = Join-Path $dataDir.FullName '.data'
        if (-not (Test-Path $dataFile)) { return $false }
        
        $json = [IO.File]::ReadAllText($dataFile)
        $settings = $json | ConvertFrom-Json
        
        $normalizedTarget = $FolderPath.ToLower().TrimEnd('\')
        
        foreach ($entry in $settings.settings.ExcludeMgr.Settings) {
            $normalizedEntry = $entry.path.ToLower().TrimEnd('\')
            # Check path matches AND has on-access bit (bit 0 = 1)
            if ($normalizedEntry -eq $normalizedTarget -and ($entry.flags -band 1)) {
                return $true
            }
        }
        return $false
    } catch {
        return $false
    }
}

function Request-BDFreeOnAccessExclusion {
    <#
    .DESCRIPTION
        Guides the user to add a Bitdefender Free on-access exclusion,
        which is required for the mod DLLs to load at runtime.
        Opens BD UI, copies path to clipboard, shows instructions, verifies.
    #>
    param([string]$ContentPath)
    
    # Check if exclusion already exists
    if (Test-BDFreeExclusion -FolderPath $ContentPath) {
        Write-OK (T 'bd_onaccess_verified')
        return $true
    }
    
    Write-C ""
    Write-C "  ================================================================" Yellow
    Write-C "  $(T 'bd_onaccess_title')" Red
    Write-C "  ================================================================" Yellow
    Write-C ""
    Write-C "  $(T 'bd_onaccess_reason')" Yellow
    Write-C "  $(T 'bd_onaccess_cannot_autofix')" Yellow
    Write-C ""
    
    # Open BD UI
    $null = Open-AVSettings -AVType 'bitdefender_free'
    Start-Sleep -Seconds 2
    
    # Copy path to clipboard
    try {
        Add-Type -AssemblyName System.Windows.Forms -ErrorAction SilentlyContinue
        [System.Windows.Forms.Clipboard]::SetText($ContentPath)
        Write-OK (T 'bd_onaccess_clipboard')
    } catch { }
    
    Write-C ""
    
    # Show step-by-step instructions
    $instructions = Get-AVExclusionInstructions -AVType 'bitdefender_free' -AVName 'Bitdefender' -FolderPath $ContentPath
    foreach ($line in $instructions) {
        if ($line -match '^===') { Write-C "  $line" Cyan }
        elseif ($line -match '^\s*$') { Write-C "" }
        elseif ($line -match 'ATENCAO:|WARNING:|PRECISA|MUST') { Write-C "  $line" Red }
        elseif ($line -match '===>') { Write-C "  $line" Cyan }
        else { Write-C "  $line" Yellow }
    }
    Write-C ""
    
    # Wait for user and verify up to 3 times
    $maxAttempts = 3
    for ($attempt = 1; $attempt -le $maxAttempts; $attempt++) {
        Write-C "  >> $(T 'bd_onaccess_wait')" White
        Read-Host
        Write-C ""
        
        if (Test-BDFreeExclusion -FolderPath $ContentPath) {
            Write-OK (T 'bd_onaccess_verified')
            Write-C ""
            return $true
        } elseif ($attempt -lt $maxAttempts) {
            Write-Warn "$(T 'bd_onaccess_not_detected') ($(T 'bd_onaccess_attempt') $attempt/$maxAttempts)"
            Write-C ""
            Write-C "  ----------------------------------------------------------------" DarkGray
            if ($Script:Lang -eq 'pt') {
                Write-C "  Certifique-se de seguir TODOS os passos, especialmente:" Yellow
                Write-C "  - Clicar em '+ Adicionar uma Excecao' (nao apenas em 'Gerenciar Excecoes')" Yellow
                Write-C "  - Marcar TODAS as opcoes de verificacao" Yellow
                Write-C "  - Clicar em 'Salvar' ao final" Yellow
            } else {
                Write-C "  Make sure to follow ALL steps, especially:" Yellow
                Write-C "  - Click '+ Add an Exception' (not just 'Manage Exceptions')" Yellow
                Write-C "  - CHECK ALL scan options" Yellow
                Write-C "  - Click 'Save' at the end" Yellow
            }
            Write-C "  ----------------------------------------------------------------" DarkGray
            Write-C ""
        } else {
            Write-Warn (T 'bd_onaccess_not_detected')
            Write-C ""
            Write-Warn (T 'bd_onaccess_skipped')
            Write-C ""
            return $false
        }
    }
    return $false
}

function Try-BitdefenderExclusion {
    <#
    .DESCRIPTION
        Attempts to add a folder exclusion in Bitdefender via multiple methods.
        Returns $true if any method succeeded.
    #>
    param([string]$FolderPath)
    
    $success = $false
    
    # Method 1: Bitdefender product.console.exe CLI (paid versions)
    $bdConsolePaths = @(
        "$env:ProgramFiles\Bitdefender\Bitdefender Security\product.console.exe",
        "$env:ProgramFiles\Bitdefender\Endpoint Security\product.console.exe",
        "$env:ProgramFiles\Bitdefender Agent\product.console.exe",
        "${env:ProgramFiles(x86)}\Bitdefender\Bitdefender Security\product.console.exe"
    )
    foreach ($p in $bdConsolePaths) {
        if (Test-Path $p) {
            try {
                $proc = Start-Process -FilePath $p -ArgumentList "/c SetExclusion path=`"$FolderPath`"" -Wait -PassThru -WindowStyle Hidden -ErrorAction Stop
                if ($proc.ExitCode -eq 0) { $success = $true; break }
            } catch { }
            try {
                $proc = Start-Process -FilePath $p -ArgumentList "/c AddExclusion path=`"$FolderPath`"" -Wait -PassThru -WindowStyle Hidden -ErrorAction Stop
                if ($proc.ExitCode -eq 0) { $success = $true; break }
            } catch { }
        }
    }
    
    # Method 2: bduitool.exe
    if (-not $success) {
        $bduiPaths = @(
            "$env:ProgramFiles\Bitdefender\Bitdefender Security\bduitool.exe",
            "${env:ProgramFiles(x86)}\Bitdefender\Bitdefender Security\bduitool.exe"
        )
        foreach ($p in $bduiPaths) {
            if (Test-Path $p) {
                try {
                    & $p /addExclusion "$FolderPath" 2>$null
                    $success = $true; break
                } catch { }
            }
        }
    }
    
    # Method 3: Registry-based exclusion (works for some BD versions)
    if (-not $success) {
        $regPaths = @(
            "HKLM:\SOFTWARE\Bitdefender\Bitdefender Security\Antivirus\Exclusions\Paths",
            "HKLM:\SOFTWARE\Bitdefender\Bitdefender Antivirus\Antivirus\Exclusions\Paths",
            "HKLM:\SOFTWARE\Bitdefender\Bitdefender Antivirus Free\Antivirus\Exclusions\Paths"
        )
        foreach ($regPath in $regPaths) {
            try {
                if (-not (Test-Path $regPath)) {
                    New-Item -Path $regPath -Force -ErrorAction SilentlyContinue | Out-Null
                }
                Set-ItemProperty -Path $regPath -Name $FolderPath -Value 0 -Type DWord -ErrorAction Stop
                $success = $true; break
            } catch { }
        }
    }
    
    # Method 4: Try adding individual file exclusions via registry
    if (-not $success) {
        $fileRegPaths = @(
            "HKLM:\SOFTWARE\Bitdefender\Bitdefender Security\Antivirus\Exclusions\Extensions",
            "HKLM:\SOFTWARE\Bitdefender\Bitdefender Antivirus Free\Antivirus\Exclusions\Extensions"
        )
        foreach ($regPath in $fileRegPaths) {
            try {
                if (-not (Test-Path $regPath)) {
                    New-Item -Path $regPath -Force -ErrorAction SilentlyContinue | Out-Null
                }
                foreach ($dll in @("winmm.dll", (Get-DiskName -SourceName "OnlineFix64.dll"))) {
                    $fullPath = Join-Path $FolderPath $dll
                    Set-ItemProperty -Path $regPath -Name $fullPath -Value 0 -Type DWord -ErrorAction SilentlyContinue
                }
                $success = $true; break
            } catch { }
        }
    }
    
    return $success
}

function Suspend-Bitdefender {
    <#
    .DESCRIPTION
        Aggressively suspends Bitdefender real-time protection using multiple
        techniques. Returns $true if protection was successfully disabled.
        Always pair with Resume-Bitdefender afterward.
    #>
    $suspended = $false

    # Method 1: product.console.exe PauseProtection (paid versions)
    $bdConsolePaths = @(
        "$env:ProgramFiles\Bitdefender\Bitdefender Security\product.console.exe",
        "$env:ProgramFiles\Bitdefender\Endpoint Security\product.console.exe",
        "${env:ProgramFiles(x86)}\Bitdefender\Bitdefender Security\product.console.exe"
    )
    foreach ($p in $bdConsolePaths) {
        if (Test-Path $p) {
            try {
                Start-Process -FilePath $p -ArgumentList "/c PauseProtection secs=180" -Wait -WindowStyle Hidden -ErrorAction SilentlyContinue
                $suspended = $true
            } catch { }
            break
        }
    }

    # Method 2: Unload BD minifilter drivers (blocks file scanning at kernel level)
    $bdFilters = @("bdsfltr", "bdfwfpf", "trufos", "avc3", "atc3", "edrsensor", "bdsandbox", "bdfndisf")
    foreach ($filter in $bdFilters) {
        try {
            $result = & fltmc unload $filter 2>&1
            if ($LASTEXITCODE -eq 0) { $suspended = $true }
        } catch { }
    }

    # Method 3: Force-kill BD processes (bypasses self-protection in some versions)
    $bdProcesses = @("vsserv", "bdagent", "bdservicehost", "seccenter", "bdredline", "bdntwrk", "updatesrv")
    foreach ($proc in $bdProcesses) {
        try {
            $running = Get-Process -Name $proc -ErrorAction SilentlyContinue
            if ($running) {
                & taskkill /F /IM "${proc}.exe" 2>&1 | Out-Null
                if ($LASTEXITCODE -eq 0) { $suspended = $true }
            }
        } catch { }
    }

    # Method 4: Disable and stop BD services
    $bdServices = @("VSSERV", "BDAuxSrv", "bdredline", "bdagent", "EPProtectedService", "EPRedline", "BDSandBox")
    foreach ($svcName in $bdServices) {
        try {
            $svc = Get-Service -Name $svcName -ErrorAction SilentlyContinue
            if ($svc -and $svc.Status -eq 'Running') {
                & sc.exe config $svcName start=disabled 2>&1 | Out-Null
                Stop-Service -Name $svcName -Force -ErrorAction Stop
                $suspended = $true
            }
        } catch { }
    }

    # Method 5: Disable BD Active Threat Control via registry
    $bdRegPaths = @(
        "HKLM:\SOFTWARE\Bitdefender\Bitdefender Antivirus Free Edition",
        "HKLM:\SOFTWARE\Bitdefender\Bitdefender Security\Active Virus Control",
        "HKLM:\SOFTWARE\Bitdefender\Bitdefender Antivirus\Active Virus Control"
    )
    foreach ($rp in $bdRegPaths) {
        try {
            if (Test-Path $rp) {
                Set-ItemProperty -Path $rp -Name "Enabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
                $suspended = $true
            }
        } catch { }
    }
    # Also try shield key
    try {
        $shieldPaths = @(
            "HKLM:\SOFTWARE\Bitdefender\Bitdefender Antivirus Free Edition\Shield",
            "HKLM:\SOFTWARE\Bitdefender\Bitdefender Security\Shield"
        )
        foreach ($sp in $shieldPaths) {
            if (Test-Path $sp) {
                Set-ItemProperty -Path $sp -Name "Enabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
                $suspended = $true
            }
        }
    } catch { }

    if ($suspended) { Start-Sleep -Seconds 3 }
    return $suspended
}

function Resume-Bitdefender {
    <#
    .DESCRIPTION
        Restarts Bitdefender real-time protection services after file installation.
    #>
    $bdServices = @("VSSERV", "BDAuxSrv", "bdredline", "bdagent", "EPProtectedService", "EPRedline", "BDSandBox")

    # Re-enable services
    foreach ($svcName in $bdServices) {
        try {
            & sc.exe config $svcName start=auto 2>&1 | Out-Null
            $svc = Get-Service -Name $svcName -ErrorAction SilentlyContinue
            if ($svc -and $svc.Status -ne 'Running') {
                Start-Service -Name $svcName -ErrorAction SilentlyContinue
            }
        } catch { }
    }

    # Re-enable registry settings
    $bdRegPaths = @(
        "HKLM:\SOFTWARE\Bitdefender\Bitdefender Antivirus Free Edition",
        "HKLM:\SOFTWARE\Bitdefender\Bitdefender Security\Active Virus Control",
        "HKLM:\SOFTWARE\Bitdefender\Bitdefender Antivirus\Active Virus Control"
    )
    foreach ($rp in $bdRegPaths) {
        try {
            if (Test-Path $rp) {
                Set-ItemProperty -Path $rp -Name "Enabled" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
            }
        } catch { }
    }
    try {
        $shieldPaths = @(
            "HKLM:\SOFTWARE\Bitdefender\Bitdefender Antivirus Free Edition\Shield",
            "HKLM:\SOFTWARE\Bitdefender\Bitdefender Security\Shield"
        )
        foreach ($sp in $shieldPaths) {
            if (Test-Path $sp) {
                Set-ItemProperty -Path $sp -Name "Enabled" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
            }
        }
    } catch { }

    # Reload BD minifilter drivers
    $bdFilters = @("bdsfltr", "bdfwfpf", "trufos", "avc3", "atc3", "edrsensor")
    foreach ($filter in $bdFilters) {
        try { & fltmc load $filter 2>&1 | Out-Null } catch { }
    }

    # ResumeProtection via console
    $bdConsolePaths = @(
        "$env:ProgramFiles\Bitdefender\Bitdefender Security\product.console.exe",
        "$env:ProgramFiles\Bitdefender\Endpoint Security\product.console.exe",
        "${env:ProgramFiles(x86)}\Bitdefender\Bitdefender Security\product.console.exe"
    )
    foreach ($p in $bdConsolePaths) {
        if (Test-Path $p) {
            try { Start-Process -FilePath $p -ArgumentList "/c ResumeProtection" -Wait -WindowStyle Hidden -ErrorAction SilentlyContinue } catch { }
            break
        }
    }
}

function Protect-InstalledFiles {
    <#
    .DESCRIPTION
        Sets file attributes and permissions to protect bypass files from AV deletion.
        Uses ReadOnly+System attributes and restrictive ACLs.
    #>
    param([string]$ContentPath)
    
    $files = @("winmm.dll", (Get-DiskName -SourceName "OnlineFix64.dll"), "dlllist.txt", "OnlineFix.ini")
    
    foreach ($fileName in $files) {
        $filePath = Join-Path $ContentPath $fileName
        if (Test-Path $filePath) {
            # Set ReadOnly + System attributes (some AV products respect these)
            try {
                $file = Get-Item $filePath -Force
                $file.Attributes = [System.IO.FileAttributes]::ReadOnly -bor [System.IO.FileAttributes]::System
            } catch { }
            
            # Remove Zone.Identifier ADS (marks file as "from internet" - triggers extra AV scanning)
            try {
                Remove-Item -Path "${filePath}:Zone.Identifier" -Force -ErrorAction SilentlyContinue
            } catch { }
            
            # Apply deny-delete ACL on DLL files (prevents AV quarantine)
            if ($fileName -match '\.dll$') {
                Lock-FileFromDeletion -FilePath $filePath
            }
        }
    }
}

function Unprotect-InstalledFiles {
    <#
    .DESCRIPTION
        Removes protection attributes and ACLs before re-writing files.
    #>
    param([string]$ContentPath)
    
    foreach ($fileName in @("winmm.dll", (Get-DiskName -SourceName "OnlineFix64.dll"), "dlllist.txt", "OnlineFix.ini")) {
        $filePath = Join-Path $ContentPath $fileName
        if (Test-Path $filePath) {
            # Restore permissive ACL first (undo deny-delete)
            try {
                $acl = New-Object System.Security.AccessControl.FileSecurity
                $acl.SetAccessRuleProtection($true, $false)
                $acl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule(
                    (New-Object System.Security.Principal.SecurityIdentifier('S-1-5-32-544')),
                    'FullControl', 'Allow')))
                $acl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule(
                    (New-Object System.Security.Principal.SecurityIdentifier('S-1-1-0')),
                    'FullControl', 'Allow')))
                [System.IO.File]::SetAccessControl($filePath, $acl)
            } catch { }
            try {
                $file = Get-Item $filePath -Force
                $file.Attributes = [System.IO.FileAttributes]::Normal
            } catch {
                try { $null = cmd /c "attrib -R -S -H `"$filePath`"" 2>$null } catch { }
            }
        }
    }
}

function Remove-FileRobust {
    <#
    .DESCRIPTION
        Removes a file even when attributes, ownership or ACLs were hardened.
        Returns $true only if the file is actually gone at the end.
    #>
    param([string]$FilePath)

    $Script:LastRemovePendingReboot = $false
    if (-not (Test-Path $FilePath)) { return $true }

    # Reset ACL first (undo deny-delete protection)
    try {
        $acl = New-Object System.Security.AccessControl.FileSecurity
        $acl.SetAccessRuleProtection($true, $false)
        $acl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule(
            (New-Object System.Security.Principal.SecurityIdentifier('S-1-5-32-544')),
            'FullControl', 'Allow')))
        $acl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule(
            (New-Object System.Security.Principal.SecurityIdentifier('S-1-1-0')),
            'FullControl', 'Allow')))
        [System.IO.File]::SetAccessControl($FilePath, $acl)
    } catch { }

    try {
        $item = Get-Item $FilePath -Force -ErrorAction SilentlyContinue
        if ($item) { $item.Attributes = [System.IO.FileAttributes]::Normal }
    } catch { }

    try { $null = cmd /c "attrib -R -S -H `"$FilePath`"" 2>$null } catch { }

    try {
        Remove-Item -LiteralPath $FilePath -Force -ErrorAction Stop
    } catch { }

    if (-not (Test-Path $FilePath)) { return $true }

    try {
        $null = cmd /c "takeown /F `"$FilePath`" /A" 2>$null
        $null = cmd /c "icacls `"$FilePath`" /grant *S-1-5-32-544:F /C" 2>$null
        $null = cmd /c "attrib -R -S -H `"$FilePath`"" 2>$null
        $null = cmd /c "del /F /Q `"$FilePath`"" 2>$null
    } catch { }

    if (-not (Test-Path $FilePath)) { return $true }

    try {
        [System.IO.File]::Delete($FilePath)
    } catch { }

    if (-not (Test-Path $FilePath)) { return $true }

    try {
        Add-Type @"
using System;
using System.Runtime.InteropServices;
public static class MBUFileOps {
    [DllImport("kernel32.dll", SetLastError=true, CharSet=CharSet.Unicode)]
    public static extern bool MoveFileEx(string existingFileName, string newFileName, int flags);
}
"@ -ErrorAction SilentlyContinue

        # MOVEFILE_DELAY_UNTIL_REBOOT = 0x4
        if ([MBUFileOps]::MoveFileEx($FilePath, $null, 0x4)) {
            $Script:LastRemovePendingReboot = $true
        }
    } catch { }

    return (-not (Test-Path $FilePath))
}

function Watch-InstalledFiles {
    <#
    .DESCRIPTION
        Monitors bypass files for a specified duration. If any file is deleted by
        antivirus, immediately re-writes it from the in-memory cache.
        Returns $true if no files were deleted during monitoring.
    #>
    param(
        [string]$ContentPath,
        [int]$DurationSeconds = 15
    )
    
    if (-not $Script:BytesCache -or $Script:BytesCache.Count -eq 0) { return $true }
    
    $endTime = (Get-Date).AddSeconds($DurationSeconds)
    $rewroteFiles = @()
    $checkInterval = 1
    
    if ($Script:Lang -eq "pt") {
        Write-Info "Monitorando arquivos por ${DurationSeconds}s para proteger contra antivirus..."
    } else {
        Write-Info "Monitoring files for ${DurationSeconds}s to protect against antivirus..."
    }
    
    while ((Get-Date) -lt $endTime) {
        foreach ($file in $Script:OnlineFixFiles) {
            $diskName = Get-DiskName -SourceName $file.Name
            $filePath = Join-Path $ContentPath $diskName
            if (-not (Test-Path $filePath)) {
                $bytes = $Script:BytesCache[$file.Name]
                if ($bytes -and $bytes.Length -gt 0) {
                    try {
                        # For dlllist.txt: patch content with safe name
                        $writeBytes = $bytes
                        if ($file.Name -eq "dlllist.txt" -and $Script:SafeDllName) {
                            $textContent = [System.Text.Encoding]::UTF8.GetString($bytes)
                            $textContent = $textContent -replace 'OnlineFix64\.dll', $Script:SafeDllName
                            $writeBytes = [System.Text.Encoding]::UTF8.GetBytes($textContent)
                        }
                        # Use full Write-FileToDisk for AV evasion (not plain WriteAllBytes)
                        $result = Write-FileToDisk -FileName $diskName -DestFile $filePath -Bytes $writeBytes
                        if ($result -ne $true) {
                            # Fallback: direct write
                            [System.IO.File]::WriteAllBytes($filePath, $writeBytes)
                        }
                        # Re-protect the file
                        Protect-SingleFile -FilePath $filePath
                        if ($diskName -match '\.dll$') {
                            Lock-FileFromDeletion -FilePath $filePath
                        }
                        
                        if ($diskName -notin $rewroteFiles) {
                            $rewroteFiles += $diskName
                            if ($Script:Lang -eq "pt") {
                                Write-Warn "  $diskName foi deletado pelo antivirus - restaurado automaticamente!"
                            } else {
                                Write-Warn "  $diskName was deleted by antivirus - automatically restored!"
                            }
                        }
                    } catch { }
                }
            }
        }
        Start-Sleep -Seconds $checkInterval
    }
    
    if ($rewroteFiles.Count -gt 0) {
        Write-C ""
        if ($Script:Lang -eq "pt") {
            Write-Warn "Antivirus tentou deletar $($rewroteFiles.Count) arquivo(s) - foram restaurados!"
            Write-C ""
            Write-C "  IMPORTANTE: Adicione a exclusao no seu antivirus para evitar" Yellow
            Write-C "  que isso aconteca toda vez que o Minecraft for aberto!" Yellow
            Write-C "  Pasta: $ContentPath" Cyan
        } else {
            Write-Warn "Antivirus tried to delete $($rewroteFiles.Count) file(s) - restored!"
            Write-C ""
            Write-C "  IMPORTANT: Add the exclusion in your antivirus to prevent" Yellow
            Write-C "  this from happening every time Minecraft is opened!" Yellow
            Write-C "  Folder: $ContentPath" Cyan
        }
        return $false
    } else {
        if ($Script:Lang -eq "pt") {
            Write-OK "Arquivos estaveis - nenhuma exclusao pelo antivirus detectada!"
        } else {
            Write-OK "Files stable - no antivirus deletion detected!"
        }
        return $true
    }
}

function Request-AVDisable {
    param(
        [array]$DetectedAV,
        [string]$FolderPath,
        [string[]]$BlockedFiles
    )
    
    Write-C ""
    Write-C "  ============================================================" Red
    Write-C ""
    
    # Detect if primary AV is BD Free (blocked write, not deleted)
    $primaryAV = $DetectedAV | Where-Object { $_.Active -and $_.Type -ne "defender" } | Select-Object -First 1
    if (-not $primaryAV) {
        $primaryAV = $DetectedAV | Where-Object { $_.Active } | Select-Object -First 1
    }
    $isBDFree = $primaryAV -and $primaryAV.Type -eq "bitdefender_free"
    
    # Show which files were blocked
    if ($Script:Lang -eq "pt") {
        if ($isBDFree) {
            Write-Err "SEU ANTIVIRUS BLOQUEOU A GRAVACAO DO ARQUIVO!"
        } else {
            Write-Err "SEU ANTIVIRUS DELETOU ARQUIVOS APOS O DOWNLOAD!"
        }
        Write-C ""
        foreach ($f in $BlockedFiles) {
            Write-Warn "    Bloqueado: $f"
        }
        Write-C ""
        if ($isBDFree) {
            Write-C "  Seu antivirus BLOQUEOU a gravacao do arquivo (acesso negado)." Yellow
            Write-C "  Desativar o 'Shield' NAO e suficiente - e preciso adicionar EXCECAO de pasta." White
        } else {
            Write-C "  O download funcionou e a integridade foi verificada, mas seu" Yellow
            Write-C "  antivirus DELETOU o arquivo imediatamente apos ser salvo no disco." Yellow
            Write-C ""
            Write-C "  Voce precisa DESATIVAR TEMPORARIAMENTE a protecao do seu antivirus" White
            Write-C "  para que a instalacao funcione. Apos instalar, pode reativar." White
        }
    } else {
        if ($isBDFree) {
            Write-Err "YOUR ANTIVIRUS BLOCKED THE FILE WRITE!"
        } else {
            Write-Err "YOUR ANTIVIRUS DELETED FILES AFTER DOWNLOAD!"
        }
        Write-C ""
        foreach ($f in $BlockedFiles) {
            Write-Warn "    Blocked: $f"
        }
        Write-C ""
        if ($isBDFree) {
            Write-C "  Your antivirus BLOCKED the file write (access denied)." Yellow
            Write-C "  Disabling 'Shield' is NOT enough - you must add a folder EXCEPTION." White
        } else {
            Write-C "  The download worked and integrity was verified, but your" Yellow
            Write-C "  antivirus DELETED the file immediately after it was saved to disk." Yellow
            Write-C ""
            Write-C "  You need to TEMPORARILY DISABLE your antivirus protection" White
            Write-C "  for the installation to work. You can re-enable it after." White
        }
    }
    
    Write-C ""
    Write-C "  ------------------------------------------------------------" DarkGray
    Write-C ""
    
    # Show specific instructions for the primary AV
    # ($primaryAV e $isBDFree already computed above)
    
    if ($primaryAV) {
        $instructions = Get-AVExclusionInstructions -AVType $primaryAV.Type -AVName $primaryAV.Name -FolderPath $FolderPath
        foreach ($line in $instructions) {
            if ($line -match "^\s*===") {
                Write-C "  $line" Cyan
            } elseif ($line -match "^\s*$") {
                Write-C ""
            } elseif ($line -match "ATENCAO:|WARNING:") {
                Write-C "  $line" Red
            } elseif ($line -match "^  METODO ALTERNATIVO|^  ALTERNATIVE") {
                Write-C "  $line" Green
            } else {
                Write-C "  $line" Yellow
            }
        }
        Write-C ""
        
        # Try to open AV settings automatically
        $opened = Open-AVSettings -AVType $primaryAV.Type
        if ($opened) {
            if ($Script:Lang -eq "pt") {
                Write-OK "Janela do seu antivirus aberta automaticamente!"
            } else {
                Write-OK "Your antivirus window opened automatically!"
            }
            Write-C ""
        }
    }
    
    Write-C "  ------------------------------------------------------------" DarkGray
    Write-C ""
    
    if ($Script:Lang -eq "pt") {
        if ($isBDFree) {
            Write-C "  >> Adicione a excecao de pasta e pressione ENTER para continuar..." White
        } else {
            Write-C "  >> Desative a protecao do antivirus e pressione ENTER para continuar..." White
        }
    } else {
        if ($isBDFree) {
            Write-C "  >> Add the folder exception and press ENTER to continue..." White
        } else {
            Write-C "  >> Disable your antivirus protection and press ENTER to continue..." White
        }
    }
    
    Write-C "  ============================================================" Red
    Write-C ""
    
    # Wait for user to press Enter
    Read-Host
}

function Get-DiskName {
    <# Returns the on-disk filename for a given source file name #>
    param([string]$SourceName)
    $entry = $Script:OnlineFixFiles | Where-Object { $_.Name -eq $SourceName } | Select-Object -First 1
    if ($entry -and $entry.DiskName) { return $entry.DiskName }
    return $SourceName
}

function Download-OnlineFixFile {
    param(
        [string]$FileName,
        [string]$DestPath,
        [string]$ExpectedHash
    )
    
    $url = "$Script:BaseUrl/$FileName"
    $diskName = Get-DiskName -SourceName $FileName
    $destFile = Join-Path $DestPath $diskName
    
    Write-Info "$(T 'downloading') $diskName..."
    
    # ============================================================
    # STEP 1: Download bytes into memory (this ALWAYS works - AV can't block RAM)
    # ============================================================
    $bytes = $null
    
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $webClient = New-Object System.Net.WebClient
        $webClient.Headers.Add("User-Agent", "Mozilla/5.0")
        $bytes = $webClient.DownloadData($url)
    } catch { }
    
    # Fallback download method
    if (-not $bytes -or $bytes.Length -eq 0) {
        try {
            Add-Type -AssemblyName System.Net.Http -ErrorAction SilentlyContinue
            $httpClient = New-Object System.Net.Http.HttpClient
            $httpClient.Timeout = [TimeSpan]::FromSeconds(120)
            $bytes = $httpClient.GetByteArrayAsync($url).Result
        } catch { }
    }
    
    if (-not $bytes -or $bytes.Length -eq 0) {
        Write-Err "$(T 'download_fail'): $diskName"
        if ($Script:Lang -eq "pt") {
            Write-Warn "  URL: $url"
            Write-Warn "  Verifique sua conexao ou se o arquivo existe no release do GitHub."
        } else {
            Write-Warn "  URL: $url"
            Write-Warn "  Check your connection or if the file exists in the GitHub release."
        }
        return "download_failed"
    }
    
    # ============================================================
    # STEP 2: Verify integrity in memory (before touching disk)
    # ============================================================
    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    $hashBytes = $sha256.ComputeHash($bytes)
    $actualHash = -join ($hashBytes | ForEach-Object { $_.ToString("x2") })
    
    $hashOK = ($actualHash -eq $ExpectedHash)
    if (-not $hashOK) {
        Write-Warn "$(T 'hash_fail') ($FileName)"
    }
    
    # Cache bytes for potential retry later (so we don't re-download)
    if (-not $Script:BytesCache) { $Script:BytesCache = @{} }
    $Script:BytesCache[$FileName] = $bytes
    
    # For dlllist.txt: replace OnlineFix64.dll reference with safe name
    if ($FileName -eq "dlllist.txt" -and $Script:SafeDllName) {
        $textContent = [System.Text.Encoding]::UTF8.GetString($bytes)
        $textContent = $textContent -replace 'OnlineFix64\.dll', $Script:SafeDllName
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($textContent)
    }
    
    # ============================================================
    # STEP 3: Write to disk (this is where AV can block)
    # ============================================================
    $writeResult = Write-FileToDisk -FileName $diskName -DestFile $destFile -Bytes $bytes
    if ($writeResult -eq $true) {
        Write-OK "$(T 'download_ok'): $diskName"
    }
    return $writeResult
}

function Write-FileToDisk {
    param(
        [string]$FileName,
        [string]$DestFile,
        [byte[]]$Bytes
    )
    
    # Remove existing file first (unprotect if needed)
    if (Test-Path $DestFile) {
        try {
            $existing = Get-Item $DestFile -Force -ErrorAction SilentlyContinue
            if ($existing) { $existing.Attributes = [System.IO.FileAttributes]::Normal }
            Remove-Item -Path $DestFile -Force -ErrorAction Stop
        } catch { }
    }
    
    # ============================================================
    # Technique 1: Direct WriteAllBytes (works if AV is paused)
    # ============================================================
    try {
        [System.IO.File]::WriteAllBytes($DestFile, $Bytes)
        if (Test-Path $DestFile) {
            Protect-SingleFile -FilePath $DestFile
            Start-Sleep -Milliseconds 500
            if (Test-Path $DestFile) { return $true }
        }
    } catch { }
    
    # Clean up if file was deleted
    if (Test-Path $DestFile) {
        try { Remove-Item $DestFile -Force -ErrorAction SilentlyContinue } catch { }
    }
    
    # ============================================================
    # Technique 2: Memory-mapped file (bypasses some minifilter hooks)
    # ============================================================
    try {
        # Create empty file of correct size
        $fs = [System.IO.File]::Create($DestFile)
        $fs.SetLength($Bytes.Length)
        $fs.Close()
        $fs.Dispose()
        
        # Write via memory-mapped file (goes through Mm, not Io path)
        Add-Type -AssemblyName System.IO.MemoryMappedFiles -ErrorAction SilentlyContinue
        $mmf = [System.IO.MemoryMappedFiles.MemoryMappedFile]::CreateFromFile(
            $DestFile,
            [System.IO.FileMode]::Open,
            $null,
            $Bytes.Length,
            [System.IO.MemoryMappedFiles.MemoryMappedFileAccess]::ReadWrite
        )
        $accessor = $mmf.CreateViewAccessor(0, $Bytes.Length)
        $accessor.WriteArray([long]0, $Bytes, 0, $Bytes.Length)
        $accessor.Flush()
        $accessor.Dispose()
        $mmf.Dispose()
        
        if (Test-Path $DestFile) {
            Protect-SingleFile -FilePath $DestFile
            Start-Sleep -Milliseconds 500
            if (Test-Path $DestFile) { return $true }
        }
    } catch { }
    
    # Clean up
    if (Test-Path $DestFile) {
        try { Remove-Item $DestFile -Force -ErrorAction SilentlyContinue } catch { }
    }
    
    # ============================================================
    # Technique 3: Write with restrictive ACL (deny SYSTEM read before close)
    # ============================================================
    try {
        $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent().Name
        
        # Create file with FileStream
        $fs = New-Object System.IO.FileStream(
            $DestFile,
            [System.IO.FileMode]::Create,
            [System.IO.FileAccess]::ReadWrite,
            [System.IO.FileShare]::None
        )
        $fs.Write($Bytes, 0, $Bytes.Length)
        $fs.Flush()
        $fs.Close()
        $fs.Dispose()
        
        # Immediately restrict access (deny SYSTEM - BD's scanning account)
        try {
            $acl = New-Object System.Security.AccessControl.FileSecurity
            $acl.SetAccessRuleProtection($true, $false)
            $ownerRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
                $currentUser, 'FullControl', 'Allow'
            )
            $acl.AddAccessRule($ownerRule)
            # Deny SYSTEM read access (prevents BD from scanning)
            $denySystem = New-Object System.Security.AccessControl.FileSystemAccessRule(
                'NT AUTHORITY\SYSTEM', 'Read', 'Deny'
            )
            $acl.AddAccessRule($denySystem)
            [System.IO.File]::SetAccessControl($DestFile, $acl)
        } catch { }
        
        Start-Sleep -Milliseconds 500
        
        if (Test-Path $DestFile) {
            # Restore normal ACL so Minecraft can load the DLL
            try {
                $normalAcl = New-Object System.Security.AccessControl.FileSecurity
                $normalAcl.SetAccessRuleProtection($true, $false)
                $normalAcl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule(
                    $currentUser, 'FullControl', 'Allow'
                )))
                $normalAcl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule(
                    'BUILTIN\Users', 'ReadAndExecute', 'Allow'
                )))
                [System.IO.File]::SetAccessControl($DestFile, $normalAcl)
            } catch { }
            
            Protect-SingleFile -FilePath $DestFile
            Start-Sleep -Milliseconds 300
            if (Test-Path $DestFile) { return $true }
        }
    } catch { }
    
    # Clean up
    if (Test-Path $DestFile) {
        try { Remove-Item $DestFile -Force -ErrorAction SilentlyContinue } catch { }
    }
    
    # ============================================================
    # Technique 4: Write XOR-encoded then decode in-place via FileStream
    # ============================================================
    try {
        # XOR-encode with 32-byte key
        $xorKey = [System.Text.Encoding]::ASCII.GetBytes("Mc_Unl0ck3r_Byp@ss!xK9#pL7`$mN3v")
        $encoded = New-Object byte[] $Bytes.Length
        for ($i = 0; $i -lt $Bytes.Length; $i++) {
            $encoded[$i] = $Bytes[$i] -bxor $xorKey[$i % $xorKey.Length]
        }
        
        # Write encoded content (passes AV scan)
        [System.IO.File]::WriteAllBytes($DestFile, $encoded)
        
        Start-Sleep -Milliseconds 200
        
        if (Test-Path $DestFile) {
            # Now decode in-place: open file, overwrite with decoded bytes
            $fs = New-Object System.IO.FileStream(
                $DestFile,
                [System.IO.FileMode]::Open,
                [System.IO.FileAccess]::Write,
                [System.IO.FileShare]::None
            )
            $fs.Write($Bytes, 0, $Bytes.Length)
            $fs.Flush()
            $fs.Close()
            $fs.Dispose()
            
            Protect-SingleFile -FilePath $DestFile
            Start-Sleep -Milliseconds 500
            if (Test-Path $DestFile) { return $true }
        }
    } catch { }
    
    # Clean up
    if (Test-Path $DestFile) {
        try { Remove-Item $DestFile -Force -ErrorAction SilentlyContinue } catch { }
    }
    
    # ============================================================
    # Technique 5: Aggressive PE mutation + safe name + hard link + ACL lock
    # Deep PE structure modification to defeat signature matching,
    # writes with temp name, hard links, then locks with deny-delete ACL.
    # ============================================================
    try {
        $modBytes = [byte[]]$Bytes.Clone()
        $rng = [System.Random]::new()
        
        # If PE file (MZ header), apply deep mutations
        if ($modBytes.Length -gt 0x200 -and $modBytes[0] -eq 0x4D -and $modBytes[1] -eq 0x5A) {
            $lfanew = [BitConverter]::ToInt32($modBytes, 0x3C)
            if ($lfanew -gt 0 -and $lfanew -lt ($modBytes.Length - 200)) {
                
                # --- Mutation 1: Randomize TimeDateStamp ---
                [BitConverter]::GetBytes([uint32]$rng.Next(0, [int]::MaxValue)).CopyTo($modBytes, $lfanew + 8)
                
                # --- Mutation 2: Zero out CheckSum ---
                $ckOff = $lfanew + 4 + 20 + 64
                if ($ckOff + 4 -lt $modBytes.Length) {
                    [BitConverter]::GetBytes([uint32]0).CopyTo($modBytes, $ckOff)
                }
                
                # --- Mutation 3: Randomize MajorLinkerVersion / MinorLinkerVersion ---
                $modBytes[$lfanew + 4 + 2] = [byte]$rng.Next(10, 20)
                $modBytes[$lfanew + 4 + 3] = [byte]$rng.Next(0, 40)
                
                # --- Mutation 4: Modify MajorOperatingSystemVersion ---
                $osVerOff = $lfanew + 4 + 20 + 40
                if ($osVerOff + 2 -lt $modBytes.Length) {
                    [BitConverter]::GetBytes([uint16]$rng.Next(6, 11)).CopyTo($modBytes, $osVerOff)
                }
                
                # --- Mutation 5: Destroy Rich header (compiler build fingerprint) ---
                for ($i = 0x80; $i -lt [Math]::Min($lfanew, $modBytes.Length - 4); $i += 4) {
                    if ($modBytes[$i] -eq 0x52 -and $modBytes[$i+1] -eq 0x69 -and
                        $modBytes[$i+2] -eq 0x63 -and $modBytes[$i+3] -eq 0x68) {
                        # Found "Rich" marker - zero from 0x80 to here
                        $richEnd = $i + 8
                        for ($j = 0x80; $j -lt $richEnd -and $j -lt $lfanew; $j++) {
                            $modBytes[$j] = [byte]$rng.Next(0, 256)
                        }
                        break
                    }
                }
                
                # --- Mutation 6: Modify DOS stub message ---
                $dosMsg = [System.Text.Encoding]::ASCII.GetBytes(
                    "This program requires Microsoft Windows.`r`n`$")
                $dosStart = 0x4E
                if ($dosStart + $dosMsg.Length -lt $lfanew) {
                    for ($i = 0; $i -lt $dosMsg.Length; $i++) {
                        $modBytes[$dosStart + $i] = $dosMsg[$i]
                    }
                    # Fill rest of DOS stub area with random
                    for ($i = $dosStart + $dosMsg.Length; $i -lt 0x80 -and $i -lt $lfanew; $i++) {
                        $modBytes[$i] = [byte]$rng.Next(0, 256)
                    }
                }
                
                # --- Mutation 7: Null debug directory entries ---
                $peOptSize = [BitConverter]::ToUInt16($modBytes, $lfanew + 4 + 16)
                $is64 = ([BitConverter]::ToUInt16($modBytes, $lfanew + 4 + 20) -eq 0x20B)
                $ddOffset = $lfanew + 4 + 20 + (if ($is64) { 112 } else { 96 })
                # Debug directory is entry index 6 (each entry = 8 bytes: RVA + Size)
                $debugDirOff = $ddOffset + (6 * 8)
                if ($debugDirOff + 8 -lt $modBytes.Length -and $debugDirOff -lt $lfanew + 4 + 20 + $peOptSize) {
                    for ($i = 0; $i -lt 8; $i++) { $modBytes[$debugDirOff + $i] = 0 }
                }
                
                # --- Mutation 8: Randomize section padding (alignment gaps) ---
                $numSections = [BitConverter]::ToUInt16($modBytes, $lfanew + 4 + 2)
                $sectionTableOff = $lfanew + 4 + 20 + $peOptSize
                $fileAlignment = [BitConverter]::ToUInt32($modBytes, $lfanew + 4 + 20 + 36)
                if ($fileAlignment -eq 0) { $fileAlignment = 512 }
                for ($s = 0; $s -lt $numSections -and $s -lt 16; $s++) {
                    $secOff = $sectionTableOff + ($s * 40)
                    if ($secOff + 40 -gt $modBytes.Length) { break }
                    $rawSize = [BitConverter]::ToUInt32($modBytes, $secOff + 16)
                    $rawPtr  = [BitConverter]::ToUInt32($modBytes, $secOff + 20)
                    $virtSize = [BitConverter]::ToUInt32($modBytes, $secOff + 8)
                    if ($rawPtr -gt 0 -and $rawSize -gt 0 -and $virtSize -lt $rawSize) {
                        # Fill ALL gap between virtual end and raw end with random bytes
                        $gapStart = $rawPtr + $virtSize
                        $gapEnd = $rawPtr + $rawSize
                        if ($gapEnd -le $modBytes.Length -and $gapStart -lt $gapEnd) {
                            for ($i = $gapStart; $i -lt $gapEnd; $i++) {
                                $modBytes[$i] = [byte]$rng.Next(0, 256)
                            }
                        }
                    }
                }
                
                # --- Mutation 9: Deep code section INT3→NOP replacement ---
                # BD fingerprints .text section content for on-access detection.
                # INT3 (0xCC) padding between functions is never executed.
                # Replacing with NOP (0x90) changes the code section hash completely.
                for ($s = 0; $s -lt $numSections -and $s -lt 16; $s++) {
                    $secOff = $sectionTableOff + ($s * 40)
                    if ($secOff + 40 -gt $modBytes.Length) { break }
                    $secChars = [BitConverter]::ToUInt32($modBytes, $secOff + 36)
                    # CODE section: IMAGE_SCN_CNT_CODE (0x20) or IMAGE_SCN_MEM_EXECUTE (0x20000000)
                    if (($secChars -band 0x20000020) -ne 0) {
                        $rawPtr = [BitConverter]::ToUInt32($modBytes, $secOff + 20)
                        $rawSize = [BitConverter]::ToUInt32($modBytes, $secOff + 16)
                        $secEnd = [Math]::Min($rawPtr + $rawSize, $modBytes.Length)
                        # Scan for INT3 runs (2+ consecutive 0xCC bytes)
                        $run = 0
                        for ($i = [int]$rawPtr; $i -lt $secEnd; $i++) {
                            if ($modBytes[$i] -eq 0xCC) {
                                $run++
                            } else {
                                if ($run -ge 2) {
                                    # Replace INT3 run with NOP (0x90)
                                    for ($j = $i - $run; $j -lt $i; $j++) {
                                        $modBytes[$j] = 0x90
                                    }
                                }
                                $run = 0
                            }
                        }
                        if ($run -ge 2) {
                            for ($j = $secEnd - $run; $j -lt $secEnd; $j++) {
                                $modBytes[$j] = 0x90
                            }
                        }
                    }
                }
                
                # --- Mutation 10: Randomize section names ---
                # Windows PE loader ignores section names; they are purely informational.
                for ($s = 0; $s -lt $numSections -and $s -lt 16; $s++) {
                    $secOff = $sectionTableOff + ($s * 40)
                    if ($secOff + 8 -gt $modBytes.Length) { break }
                    # Generate random section name: dot + 3-6 lowercase letters
                    $nameLen = $rng.Next(3, 7)
                    $newName = [byte[]]::new(8)
                    $newName[0] = 0x2E  # '.'
                    for ($c = 1; $c -le $nameLen; $c++) {
                        $newName[$c] = [byte]$rng.Next(97, 123)  # a-z
                    }
                    [Array]::Copy($newName, 0, $modBytes, $secOff, 8)
                }
                
                # --- Mutation 11: Replace zero-fill runs in data sections ---
                # Large runs of 0x00 in .rdata/.data are alignment padding.
                for ($s = 0; $s -lt $numSections -and $s -lt 16; $s++) {
                    $secOff = $sectionTableOff + ($s * 40)
                    if ($secOff + 40 -gt $modBytes.Length) { break }
                    $secChars = [BitConverter]::ToUInt32($modBytes, $secOff + 36)
                    # Skip code sections (handled by mutation 9)
                    if (($secChars -band 0x20000020) -ne 0) { continue }
                    # Skip writable sections (.data has globals that may be zero-initialized)
                    if (($secChars -band 0x80000000) -ne 0) { continue }
                    # Process read-only data sections (.rdata, .pdata)
                    $rawPtr = [BitConverter]::ToUInt32($modBytes, $secOff + 20)
                    $rawSize = [BitConverter]::ToUInt32($modBytes, $secOff + 16)
                    $secEnd = [Math]::Min($rawPtr + $rawSize, $modBytes.Length)
                    $run = 0
                    for ($i = [int]$rawPtr; $i -lt $secEnd; $i++) {
                        if ($modBytes[$i] -eq 0x00) {
                            $run++
                        } else {
                            # Only replace large zero runs (16+ bytes = alignment padding, not string terminators)
                            if ($run -ge 16) {
                                for ($j = $i - $run; $j -lt $i; $j++) {
                                    $modBytes[$j] = [byte]$rng.Next(1, 256)
                                }
                            }
                            $run = 0
                        }
                    }
                    if ($run -ge 16) {
                        for ($j = $secEnd - $run; $j -lt $secEnd; $j++) {
                            $modBytes[$j] = [byte]$rng.Next(1, 256)
                        }
                    }
                }
            }
        }
        
        # --- Final mutation: Append large random overlay data (PE loaders ignore it) ---
        $overlaySize = $rng.Next(16384, 32769)
        $overlay = New-Object byte[] $overlaySize
        $rng.NextBytes($overlay)
        $finalBytes = New-Object byte[] ($modBytes.Length + $overlaySize)
        [Array]::Copy($modBytes, $finalBytes, $modBytes.Length)
        [Array]::Copy($overlay, 0, $finalBytes, $modBytes.Length, $overlaySize)
        $modBytes = $finalBytes
        
        $dir = [System.IO.Path]::GetDirectoryName($DestFile)
        $safeName = "gf_" + [Guid]::NewGuid().ToString("N").Substring(0, 8) + ".tmp"
        $safePath = Join-Path $dir $safeName
        
        # Write mutated bytes with safe name
        [System.IO.File]::WriteAllBytes($safePath, $modBytes)
        Start-Sleep -Milliseconds 500
        
        if (Test-Path $safePath) {
            # Remove target if somehow exists
            if (Test-Path $DestFile) {
                try { Remove-Item $DestFile -Force -ErrorAction SilentlyContinue } catch { }
            }
            
            # Create hard link: real name -> safe name
            $null = cmd /c "mklink /H `"$DestFile`" `"$safePath`"" 2>&1
            
            if (Test-Path $DestFile) {
                Remove-Item $safePath -Force -ErrorAction SilentlyContinue
                Protect-SingleFile -FilePath $DestFile
                # Apply anti-quarantine ACL (deny SYSTEM delete)
                Lock-FileFromDeletion -FilePath $DestFile
                Start-Sleep -Milliseconds 500
                if (Test-Path $DestFile) { return $true }
            }
            
            # Cleanup temp file
            Remove-Item $safePath -Force -ErrorAction SilentlyContinue
        }
    } catch { }
    
    # All techniques failed
    return "av_blocked"
}

function Protect-SingleFile {
    param([string]$FilePath)
    try {
        $f = Get-Item $FilePath -Force -ErrorAction SilentlyContinue
        if ($f) {
            $f.Attributes = [System.IO.FileAttributes]::ReadOnly -bor [System.IO.FileAttributes]::System
        }
        Remove-Item -Path "${FilePath}:Zone.Identifier" -Force -ErrorAction SilentlyContinue
    } catch { }
}

function Lock-FileFromDeletion {
    <#
    .DESCRIPTION
        Sets deny-delete ACL on a file to prevent antivirus from quarantining it.
        Allows Administrators full control and Users read+execute (for Minecraft).
        Denies SYSTEM and Local Service the ability to delete, move, or change permissions.
    #>
    param([string]$FilePath)
    if (-not (Test-Path $FilePath)) { return }
    try {
        $acl = New-Object System.Security.AccessControl.FileSecurity
        $acl.SetAccessRuleProtection($true, $false)
        # Allow Administrators full control (SID-based for locale safety)
        $acl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule(
            (New-Object System.Security.Principal.SecurityIdentifier('S-1-5-32-544')),
            'FullControl', 'Allow')))
        # Allow Users read & execute (so Minecraft can load the DLL)
        $acl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule(
            (New-Object System.Security.Principal.SecurityIdentifier('S-1-5-32-545')),
            'ReadAndExecute', 'Allow')))
        # Deny Everyone delete permission (blocks AV quarantine/rename/move)
        # Only deny Delete - not ChangePermissions, so our script can undo this for restore
        $acl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule(
            (New-Object System.Security.Principal.SecurityIdentifier('S-1-1-0')),
            'Delete', 'Deny')))
        [System.IO.File]::SetAccessControl($FilePath, $acl)
    } catch { }
}

function Start-FileGuard {
    <#
    .DESCRIPTION
        Starts a hidden background PowerShell process that holds open file handles
        on DLL files. This prevents any process (including AV) from deleting,
        moving, or renaming the files while the handles are open.
        Handles are shared for ReadWrite so Minecraft can still load the DLLs.
    #>
    param([string]$ContentPath)
    
    # Kill previous guard if running
    try {
        $existingGuard = Join-Path $env:TEMP "mbu_guard.pid"
        if (Test-Path $existingGuard) {
            $oldPid = [int](Get-Content $existingGuard -ErrorAction SilentlyContinue)
            if ($oldPid) { Stop-Process -Id $oldPid -Force -ErrorAction SilentlyContinue }
            Remove-Item $existingGuard -Force -ErrorAction SilentlyContinue
        }
    } catch { }
    
    $dll1 = (Join-Path $ContentPath (Get-DiskName -SourceName "OnlineFix64.dll")) -replace "'", "''"
    $dll2 = (Join-Path $ContentPath "winmm.dll") -replace "'", "''"
    
    $guardScript = @"
`$pid | Set-Content '$($existingGuard -replace "'", "''")' -Force
`$handles = @()
foreach (`$f in @('$dll1', '$dll2')) {
    if (Test-Path `$f) {
        try {
            `$fs = [System.IO.FileStream]::new(
                `$f, [System.IO.FileMode]::Open,
                [System.IO.FileAccess]::Read,
                [System.IO.FileShare]::ReadWrite)
            `$handles += `$fs
        } catch { }
    }
}
if (`$handles.Count -eq 0) { exit }
`$end = (Get-Date).AddHours(3)
while ((Get-Date) -lt `$end) {
    Start-Sleep -Seconds 30
    `$mc = Get-Process -Name 'Minecraft.Windows' -ErrorAction SilentlyContinue
    if (`$mc) {
        `$mc | Wait-Process -ErrorAction SilentlyContinue
        break
    }
}
foreach (`$h in `$handles) { try { `$h.Dispose() } catch { } }
Remove-Item '$($existingGuard -replace "'", "''")' -Force -ErrorAction SilentlyContinue
"@
    
    $scriptPath = Join-Path $env:TEMP "mbu_guard.ps1"
    [System.IO.File]::WriteAllText($scriptPath, $guardScript)
    Start-Process powershell.exe -ArgumentList "-NoProfile", "-ExecutionPolicy", "Bypass",
        "-WindowStyle", "Hidden", "-File", $scriptPath -WindowStyle Hidden
}

# ============================================================================
# Reboot Persistence: Survives AV cleanup on reboot
# ============================================================================

function Get-PersistencePath {
    return Join-Path $env:LOCALAPPDATA "MCBridge"
}

function Save-EncryptedBackup {
    <#
    .DESCRIPTION
        Saves XOR-encrypted copies of all bypass files to a hidden local folder.
        The encryption prevents AV from scanning the backup content.
        Uses $Script:BytesCache (in-memory download cache) to avoid file access conflicts.
    #>
    param([string]$ContentPath)
    
    $persistDir = Get-PersistencePath
    if (-not (Test-Path $persistDir)) {
        New-Item -Path $persistDir -ItemType Directory -Force | Out-Null
        # Hide the folder
        (Get-Item $persistDir -Force).Attributes = 'Hidden','Directory'
    }
    
    # Generate random XOR key
    $key = [byte[]]::new(64)
    [System.Security.Cryptography.RNGCryptoServiceProvider]::new().GetBytes($key)
    [System.IO.File]::WriteAllBytes((Join-Path $persistDir "bridge.key"), $key)
    
    # Save encrypted copies of each file
    $manifest = @()
    foreach ($file in $Script:OnlineFixFiles) {
        $diskName = Get-DiskName -SourceName $file.Name
        $bytes = $null
        $srcPath = Join-Path $ContentPath $diskName
        
        # For DLL files: ALWAYS read from disk (has PE mutations applied)
        # BytesCache has pre-mutation bytes that BD would detect instantly
        if ($diskName -match '\.dll$' -and (Test-Path $srcPath)) {
            try {
                $fs = [System.IO.FileStream]::new($srcPath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
                $bytes = [byte[]]::new($fs.Length)
                $null = $fs.Read($bytes, 0, $bytes.Length)
                $fs.Dispose()
            } catch {
                # Fallback to BytesCache if disk read fails
                if ($Script:BytesCache -and $Script:BytesCache[$file.Name]) {
                    $bytes = [byte[]]$Script:BytesCache[$file.Name]
                }
            }
        }
        # For non-DLL files: use memory cache (faster, no mutation needed)
        elseif ($Script:BytesCache -and $Script:BytesCache[$file.Name]) {
            $bytes = [byte[]]$Script:BytesCache[$file.Name]
            # For dlllist.txt: patch content with safe name
            if ($file.Name -eq "dlllist.txt" -and $Script:SafeDllName) {
                $textContent = [System.Text.Encoding]::UTF8.GetString($bytes)
                $textContent = $textContent -replace 'OnlineFix64\.dll', $Script:SafeDllName
                $bytes = [System.Text.Encoding]::UTF8.GetBytes($textContent)
            }
        }
        # Last resort: read from disk
        elseif (Test-Path $srcPath) {
            try {
                $fs = [System.IO.FileStream]::new($srcPath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
                $bytes = [byte[]]::new($fs.Length)
                $null = $fs.Read($bytes, 0, $bytes.Length)
                $fs.Dispose()
            } catch { continue }
        }
        
        if ($bytes -and $bytes.Length -gt 0) {
            # XOR encrypt using Int64 blocks for speed
            $encrypted = [byte[]]::new($bytes.Length)
            [System.Array]::Copy($bytes, $encrypted, $bytes.Length)
            $expandedKey = [byte[]]::new($encrypted.Length)
            $kl = $key.Length
            for ($j = 0; $j -lt $encrypted.Length; $j++) { $expandedKey[$j] = $key[$j % $kl] }
            $blocks = [Math]::Floor($encrypted.Length / 8)
            for ($bi = 0; $bi -lt $blocks; $bi++) {
                $off = $bi * 8
                $dVal = [BitConverter]::ToInt64($encrypted, $off)
                $kVal = [BitConverter]::ToInt64($expandedKey, $off)
                [BitConverter]::GetBytes($dVal -bxor $kVal).CopyTo($encrypted, $off)
            }
            for ($bi = $blocks * 8; $bi -lt $encrypted.Length; $bi++) {
                $encrypted[$bi] = $encrypted[$bi] -bxor $expandedKey[$bi]
            }
            $bakName = "$($diskName).bak"
            [System.IO.File]::WriteAllBytes((Join-Path $persistDir $bakName), $encrypted)
            $manifest += "$diskName|$bakName"
        }
    }
    
    # Save manifest (maps disk names to backup names)
    [System.IO.File]::WriteAllLines((Join-Path $persistDir "bridge.dat"), $manifest)
    
    # Save the content path
    [System.IO.File]::WriteAllText((Join-Path $persistDir "target.dat"), $ContentPath)
}

function Install-Persistence {
    <#
    .DESCRIPTION
        Creates a Scheduled Task that runs at user logon to restore bypass files
        if they were removed during reboot (e.g., by AV boot-time cleanup).
        Also saves encrypted backups of the files for instant restore.
    #>
    param([string]$ContentPath)
    
    try {
        # Save encrypted backups first
        Save-EncryptedBackup -ContentPath $ContentPath
    } catch { }
    
    $persistDir = Get-PersistencePath
    
    # Create the restore script (self-contained, no external dependencies)
    # Strategy: For DLLs, write XOR-scrambled content first (passes AV scan),
    # then apply ACL + open handle, THEN decode in-place. This prevents BD
    # from quarantining during the vulnerable write window.
    $restoreScript = @'
$ErrorActionPreference = 'SilentlyContinue'
$persistDir = Join-Path $env:LOCALAPPDATA "MCBridge"
$logFile = Join-Path $persistDir "restore.log"

function Write-Log { param($msg) Add-Content $logFile "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $msg" }

# Fast XOR using Int64 blocks (8 bytes at a time) - ~10x faster than byte loop
function Fast-Xor {
    param([byte[]]$Data, [byte[]]$Key)
    # Expand key to match data length (repeat key pattern)
    $expandedKey = [byte[]]::new($Data.Length)
    $kl = $Key.Length
    for ($j = 0; $j -lt $Data.Length; $j++) { $expandedKey[$j] = $Key[$j % $kl] }
    # XOR in 8-byte blocks using Int64
    $blocks = [Math]::Floor($Data.Length / 8)
    for ($i = 0; $i -lt $blocks; $i++) {
        $off = $i * 8
        $dVal = [BitConverter]::ToInt64($Data, $off)
        $kVal = [BitConverter]::ToInt64($expandedKey, $off)
        [BitConverter]::GetBytes($dVal -bxor $kVal).CopyTo($Data, $off)
    }
    # Handle remaining bytes
    for ($i = $blocks * 8; $i -lt $Data.Length; $i++) {
        $Data[$i] = $Data[$i] -bxor $expandedKey[$i]
    }
}

# Verify persistence data exists
if (-not (Test-Path (Join-Path $persistDir "bridge.key"))) { exit }
if (-not (Test-Path (Join-Path $persistDir "bridge.dat"))) { exit }
if (-not (Test-Path (Join-Path $persistDir "target.dat"))) { exit }

$targetPath = [System.IO.File]::ReadAllText((Join-Path $persistDir "target.dat")).Trim()
if (-not (Test-Path $targetPath)) { Write-Log "Target path not found: $targetPath"; exit }

# Read manifest
$manifest = [System.IO.File]::ReadAllLines((Join-Path $persistDir "bridge.dat"))
if ($manifest.Count -eq 0) { exit }

# Check if any files are missing
$needRestore = $false
foreach ($line in $manifest) {
    $parts = $line.Split('|')
    if ($parts.Count -lt 2) { continue }
    $filePath = Join-Path $targetPath $parts[0]
    if (-not (Test-Path $filePath)) { $needRestore = $true; break }
}

if (-not $needRestore) { Write-Log "All files present, no restore needed"; exit }

Write-Log "Files missing - starting restore..."

# Wait a bit for system to settle after boot
Start-Sleep -Seconds 10

# Load backup XOR key
$key = [System.IO.File]::ReadAllBytes((Join-Path $persistDir "bridge.key"))

# Generate a second random XOR key for the write-scramble technique
$writeKey = [byte[]]::new(32)
[System.Security.Cryptography.RNGCryptoServiceProvider]::new().GetBytes($writeKey)

$restoredCount = 0
$dllHandles = @()

foreach ($line in $manifest) {
    $parts = $line.Split('|')
    if ($parts.Count -lt 2) { continue }
    $diskName = $parts[0]
    $bakName = $parts[1]
    $filePath = Join-Path $targetPath $diskName
    $bakPath = Join-Path $persistDir $bakName

    if ((Test-Path $filePath) -and (Get-Item $filePath -Force).Length -gt 0) { continue }
    if (-not (Test-Path $bakPath)) { Write-Log "Backup missing: $bakName"; continue }

    # Decrypt from backup using fast XOR
    $bytes = [System.IO.File]::ReadAllBytes($bakPath)
    Fast-Xor -Data $bytes -Key $key

    $isDll = $diskName -match '\.dll$'

    try {
        if ($isDll) {
            # === DLL: Write scrambled → ACL → handle → decode in-place ===
            # Step 1: Write XOR-scrambled content (AV sees garbage, not a PE)
            $scrambled = [byte[]]::new($bytes.Length)
            [System.Array]::Copy($bytes, $scrambled, $bytes.Length)
            Fast-Xor -Data $scrambled -Key $writeKey
            [System.IO.File]::WriteAllBytes($filePath, $scrambled)
            $scrambled = $null

            # Step 2: Immediately apply deny-delete ACL (before BD can quarantine)
            [System.IO.File]::SetAttributes($filePath, [System.IO.FileAttributes]::ReadOnly -bor [System.IO.FileAttributes]::System)
            $adsPath = "${filePath}:Zone.Identifier"
            cmd /c "del `"$adsPath`"" 2>$null
            $acl = New-Object System.Security.AccessControl.FileSecurity
            $acl.SetAccessRuleProtection($true, $false)
            $adminSid = New-Object System.Security.Principal.SecurityIdentifier("S-1-5-32-544")
            $usersSid = New-Object System.Security.Principal.SecurityIdentifier("S-1-5-32-545")
            $everyoneSid = New-Object System.Security.Principal.SecurityIdentifier("S-1-1-0")
            $acl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule($adminSid, "FullControl", "Allow")))
            $acl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule($usersSid, "ReadAndExecute", "Allow")))
            $acl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule($everyoneSid, "Delete", "Deny")))
            [System.IO.File]::SetAccessControl($filePath, $acl)

            # Step 3: Open a read handle (file guard - prevents deletion)
            $guard = [System.IO.FileStream]::new($filePath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
            $dllHandles += $guard

            # Step 4: Decode in-place (overwrite scrambled with real content)
            [System.IO.File]::SetAttributes($filePath, [System.IO.FileAttributes]::Normal)
            $wfs = [System.IO.FileStream]::new($filePath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Write, [System.IO.FileShare]::ReadWrite)
            $wfs.Write($bytes, 0, $bytes.Length)
            $wfs.Flush($true)
            $wfs.Dispose()
            [System.IO.File]::SetAttributes($filePath, [System.IO.FileAttributes]::ReadOnly -bor [System.IO.FileAttributes]::System)

            Write-Log "Restored+Protected: $diskName ($($bytes.Length) bytes)"
        } else {
            # === Non-DLL: simple write (text files, AV doesn't care) ===
            $fs = [System.IO.FileStream]::new($filePath, [System.IO.FileMode]::Create, [System.IO.FileAccess]::Write, [System.IO.FileShare]::None)
            $fs.Write($bytes, 0, $bytes.Length)
            $fs.Flush($true)
            $fs.Dispose()
            Write-Log "Restored: $diskName ($($bytes.Length) bytes)"
        }
        $restoredCount++
    } catch {
        Write-Log "Failed to restore $diskName : $_"
    }
}

if ($restoredCount -gt 0) {
    Write-Log "Restored $restoredCount files."
}

# Hold DLL handles open for 3 hours (file guard)
if ($dllHandles.Count -gt 0) {
    Write-Log "File guard active for $($dllHandles.Count) DLLs"
    $end = (Get-Date).AddHours(3)
    while ((Get-Date) -lt $end) {
        Start-Sleep -Seconds 30
        $mc = Get-Process -Name 'Minecraft.Windows' -ErrorAction SilentlyContinue
        if ($mc) { $mc | Wait-Process -ErrorAction SilentlyContinue; break }
    }
    foreach ($h in $dllHandles) { try { $h.Dispose() } catch { } }
}

Write-Log "Restore complete"
'@
    
    $scriptPath = Join-Path $persistDir "GameConfigSync.ps1"
    [System.IO.File]::WriteAllText($scriptPath, $restoreScript)
    
    # Create Scheduled Task
    $taskName = "MCContentBridge"
    
    # Remove existing task if present
    try { Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue } catch { }
    
    try {
        $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$scriptPath`""
        $trigger = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
        $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -ExecutionTimeLimit (New-TimeSpan -Hours 4)
        $principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -RunLevel Highest -LogonType Interactive
        
        Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Force | Out-Null
        
        return $true
    } catch {
        return $false
    }
}

function Remove-Persistence {
    <#
    .DESCRIPTION
        Removes the scheduled task and all persistence files.
        Called during Restore-Original (uninstall).
    #>
    
    # Remove scheduled task
    $taskName = "MCContentBridge"
    try { Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue } catch { }
    
    # Remove persistence directory
    $persistDir = Get-PersistencePath
    if (Test-Path $persistDir) {
        try {
            Remove-Item $persistDir -Recurse -Force -ErrorAction SilentlyContinue
        } catch { }
    }
}

function Test-Persistence {
    <#
    .DESCRIPTION
        Checks if the reboot persistence mechanism is installed.
    #>
    $taskName = "MCContentBridge"
    try {
        $task = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
        return ($null -ne $task)
    } catch {
        return $false
    }
}

function Retry-CachedFiles {
    <#
    .DESCRIPTION
        Re-writes cached bytes to disk for files that were previously blocked by AV.
        Uses already-downloaded and verified bytes from memory cache.
        Returns $true if all missing files were written successfully.
    #>
    param([string]$DestPath)
    
    if (-not $Script:BytesCache -or $Script:BytesCache.Count -eq 0) { return $false }
    
    $allOK = $true
    
    foreach ($file in $Script:OnlineFixFiles) {
        $diskName = Get-DiskName -SourceName $file.Name
        $filePath = Join-Path $DestPath $diskName
        if (-not (Test-Path $filePath)) {
            $bytes = $Script:BytesCache[$file.Name]
            if ($bytes -and $bytes.Length -gt 0) {
                # For dlllist.txt: patch content with safe name
                $writeBytes = $bytes
                if ($file.Name -eq "dlllist.txt" -and $Script:SafeDllName) {
                    $textContent = [System.Text.Encoding]::UTF8.GetString($bytes)
                    $textContent = $textContent -replace 'OnlineFix64\.dll', $Script:SafeDllName
                    $writeBytes = [System.Text.Encoding]::UTF8.GetBytes($textContent)
                }
                Write-Info "$(T 'downloading') $diskName..."
                $result = Write-FileToDisk -FileName $diskName -DestFile $filePath -Bytes $writeBytes
                if ($result -eq $true) {
                    Write-OK "$(T 'download_ok'): $diskName"
                } else {
                    $allOK = $false
                }
            } else {
                # Need to re-download (wasn't cached)
                $result = Download-OnlineFixFile -FileName $file.Name -DestPath $DestPath -ExpectedHash $file.Hash
                if ($result -ne $true) { $allOK = $false }
            }
        }
    }
    
    return $allOK
}

function Verify-Installation {
    param([string]$ContentPath)
    
    $allPresent = $true
    $missing = @()
    
    foreach ($file in $Script:OnlineFixFiles) {
        $diskName = Get-DiskName -SourceName $file.Name
        $filePath = Join-Path $ContentPath $diskName
        if (-not (Test-Path $filePath)) {
            $allPresent = $false
            $missing += $diskName
        }
    }
    
    return @{
        AllPresent = $allPresent
        Missing = $missing
    }
}

# Legacy bypass file names from older versions (OpenFix, FakeGDK, etc.)
$Script:LegacyBypassFiles = @(
    "OpenFix.ini", "OpenFix64.dll", "OpenFix.log",
    "winmm_orig.dll", "FakeGDK.log", "FullBypass.log",
    "DirectHook.log", "Monitor.log", "VPMon.log", "XStore.log"
)

function Test-LegacyBypass {
    param([string]$ContentPath)
    
    $found = @()
    foreach ($file in $Script:LegacyBypassFiles) {
        $filePath = Join-Path $ContentPath $file
        if (Test-Path $filePath) {
            $found += $file
        }
    }
    return $found
}

function Remove-LegacyBypass {
    param([string]$ContentPath)
    
    $legacy = Test-LegacyBypass -ContentPath $ContentPath
    if ($legacy.Count -gt 0) {
        Write-Warn "Legacy bypass detected! Cleaning $($legacy.Count) old files..."
        foreach ($file in $legacy) {
            $filePath = Join-Path $ContentPath $file
            if (Remove-FileRobust -FilePath $filePath) {
                Write-OK "Removed legacy: $file"
            } else {
                Write-Warn "Failed to remove: $file"
            }
        }
        Write-C ""
        return $true
    }
    return $false
}

function Test-GamingServices {
    try {
        $service = Get-Service -Name GamingServices -ErrorAction SilentlyContinue
        return ($service -and $service.Status -eq 'Running')
    } catch {
        return $false
    }
}

function Start-GamingServices {
    Write-Info (T 'start_gaming')
    try {
        Start-Service GamingServices -ErrorAction SilentlyContinue
    } catch { }
}

# ============================================================================
# Menu Actions
# ============================================================================

function Install-Bypass {
    $mcPath = Find-MinecraftPath
    
    if (-not $mcPath) {
        Write-Err (T 'mc_not_found')
        Write-C ""
        Write-Warn (T 'install_xbox_hint')
        Write-C ""
        Write-Info "Xbox App: https://www.xbox.com/games/store/minecraft-for-windows/9NBLGGH2JHXJ"
        Wait-Enter
        return
    }
    
    Write-OK "$(T 'mc_found'): $mcPath"
    Write-C ""
    
    # Check installation type
    if ($mcPath -like "*WindowsApps*") {
        Write-Err (T 'status_store')
        Write-Warn "This version is NOT compatible. Uninstall and reinstall from Xbox App."
        Wait-Enter
        return
    }
    
    # Check if MC is running
    if (Test-MinecraftRunning) {
        Stop-Minecraft
    }
    
    # Detect and remove legacy bypass (OpenFix, FakeGDK, etc.)
    $null = Remove-LegacyBypass -ContentPath $mcPath
    
    # Generate safe DLL name (avoids AV filename-based detection)
    Initialize-SafeDllNames -ContentPath $mcPath
    
    # Detect ALL antivirus and add exclusions
    $detectedAV = Add-AllAVExclusions -Path $mcPath
    
    # Show detected antivirus
    if ($detectedAV.Count -gt 0) {
        $hasActiveAV = $detectedAV | Where-Object { $_.Active }
        if ($hasActiveAV) {
            if ($Script:Lang -eq "pt") {
                Write-Info "Antivirus detectado - aplicando protecoes..."
            } else {
                Write-Info "Antivirus detected - applying protections..."
            }
        }
    }
    
    # BITDEFENDER PROACTIVE HANDLING: For BD Free, always suspend (registry exclusions don't work)
    $hasBitdefender = $detectedAV | Where-Object { $_.Type -match "bitdefender" -and $_.Active }
    $bdWasSuspended = $false
    if ($hasBitdefender) {
        $primaryBD = $hasBitdefender | Select-Object -First 1
        $isBDFree = ($primaryBD.Type -eq "bitdefender_free")

        # For BD paid, try exclusion first; for BD Free, skip (registry doesn't work)
        $bdExclusionOK = $false
        if (-not $isBDFree) {
            $bdExclusionOK = Try-BitdefenderExclusion -FolderPath $mcPath
            if ($bdExclusionOK) {
                Write-OK (T 'exclusion_added')
            }
        }

        # BD Free: skip suspension entirely — Technique 5 (PE evasion + hardlink)
        # handles file writing without needing to disable protection.
        if ($isBDFree) {
            if ($Script:Lang -eq "pt") {
                Write-Info "Antivirus detectado - usando metodo de escrita avancado..."
            } else {
                Write-Info "Antivirus detected - using advanced write method..."
            }

        # BD Paid without exclusion: try suspension
        } elseif (-not $bdExclusionOK) {
            Write-Info (T 'bd_suspending')
            $bdWasSuspended = Suspend-Bitdefender
            if ($bdWasSuspended) {
                Write-OK (T 'bd_suspended')
            } else {
                # Auto-pause failed - write test file to check if protection is actually down
                $testPath = Join-Path $mcPath "__bd_test__.tmp"
                try {
                    [System.IO.File]::WriteAllBytes($testPath, [byte[]](0..255))
                    Remove-Item $testPath -Force -ErrorAction SilentlyContinue
                    # Write succeeded - protection might actually be paused
                    $bdWasSuspended = $true
                    Write-OK (T 'bd_suspended')
                } catch {
                    # Protection is definitely still active - manual fallback
                    $instructions = Get-AVExclusionInstructions -AVType $primaryBD.Type -AVName $primaryBD.Name -FolderPath $mcPath

                    Write-C ""
                    Write-C "  ============================================================" Yellow
                    Write-C "  $(T 'bd_suspend_failed')" Red
                    Write-C ""
                    foreach ($line in $instructions) {
                        if ($line -match "^\s*===") { Write-C "  $line" Cyan }
                        elseif ($line -match "^\s*$") { Write-C "" }
                        elseif ($line -match "ATENCAO:|WARNING:") { Write-C "  $line" Red }
                        else { Write-C "  $line" Yellow }
                    }
                    Write-C ""

                    $opened = Open-AVSettings -AVType $primaryBD.Type
                    if ($opened) {
                        if ($Script:Lang -eq "pt") { Write-OK "Janela do seu antivirus aberta!" }
                        else { Write-OK "Your antivirus window opened!" }
                    }

                    Write-C ""
                    if ($Script:Lang -eq "pt") {
                        Write-C "  >> Adicione a exclusao e pressione ENTER para continuar..." White
                    } else {
                        Write-C "  >> Add the exclusion and press ENTER to continue..." White
                    }
                    Write-C "  ============================================================" Yellow
                    Read-Host
                    Write-C ""

                    $null = Try-BitdefenderExclusion -FolderPath $mcPath
                }
            }
        }
    }
    
    # Wait for exclusions to propagate
    Start-Sleep -Seconds 3
    
    # Try to disable Defender real-time if it's active (will be re-enabled after)
    $defenderDisabledByUs = $false
    if (Test-DefenderActive) {
        try {
            Set-MpPreference -DisableRealtimeMonitoring $true -ErrorAction Stop
            $defenderDisabledByUs = $true
            if ($Script:Lang -eq "pt") {
                Write-OK "Protecao em tempo real pausada temporariamente"
            } else {
                Write-OK "Real-time protection temporarily paused"
            }
        } catch { }
    }
    
    Write-C ""
    Write-Info (T 'installing')
    Write-C ""
    
    # Initialize bytes cache for potential retry
    $Script:BytesCache = @{}
    
    # ============================================================
    # PASS 1: Download all files (detect AV blocking)
    # ============================================================
    $avBlockedFiles = @()
    $failedFiles = @()
    $downloadSuccessCount = 0
    
    foreach ($file in $Script:OnlineFixFiles) {
        $result = Download-OnlineFixFile -FileName $file.Name -DestPath $mcPath -ExpectedHash $file.Hash
        if ($result -eq "av_blocked") {
            $avBlockedFiles += $file.Name
        } elseif ($result -eq "download_failed") {
            $failedFiles += $file.Name
        } elseif ($result -eq $true) {
            $downloadSuccessCount++
        }
    }
    
    # Re-enable Defender if we disabled it
    if ($defenderDisabledByUs) {
        try {
            Set-MpPreference -DisableRealtimeMonitoring $false -ErrorAction SilentlyContinue
        } catch { }
    }

    # Resume Bitdefender if we suspended it
    if ($bdWasSuspended) {
        Resume-Bitdefender
        Write-OK (T 'bd_resumed')
    }

    # ============================================================
    # EARLY EXIT: If ALL downloads failed, don't pretend it worked
    # ============================================================
    if ($failedFiles.Count -eq $Script:OnlineFixFiles.Count) {
        Write-C ""
        Write-C "  ============================================================" Red
        if ($Script:Lang -eq "pt") {
            Write-Err "TODOS OS DOWNLOADS FALHARAM!"
            Write-C ""
            Write-C "  Nenhum arquivo foi baixado com sucesso." Yellow
            Write-C "  Possiveis causas:" Yellow
            Write-C "  1. Sem conexao com a internet" White
            Write-C "  2. GitHub esta bloqueado pela sua rede/ISP" White
            Write-C "  3. Os arquivos nao existem no release do GitHub" White
            Write-C ""
            Write-C "  Tente o metodo alternativo:" Cyan
            Write-C "  iex (curl.exe -s $Script:BaseUrl/install.ps1 | Out-String)" White
            Write-C ""
            Write-C "  Ou baixe o EXE (funciona offline):" Cyan
            Write-C "  $Script:BaseUrl/MinecraftBedrockUnlocker.exe" White
        } else {
            Write-Err "ALL DOWNLOADS FAILED!"
            Write-C ""
            Write-C "  No files were downloaded successfully." Yellow
            Write-C "  Possible causes:" Yellow
            Write-C "  1. No internet connection" White
            Write-C "  2. GitHub is blocked by your network/ISP" White
            Write-C "  3. Files don't exist in the GitHub release" White
            Write-C ""
            Write-C "  Try the alternative method:" Cyan
            Write-C "  iex (curl.exe -s $Script:BaseUrl/install.ps1 | Out-String)" White
            Write-C ""
            Write-C "  Or download the EXE (works offline):" Cyan
            Write-C "  $Script:BaseUrl/MinecraftBedrockUnlocker.exe" White
        }
        Write-C "  ============================================================" Red
        Write-C ""
        Write-Info "Discord: $Script:DiscordUrl"
        Wait-Enter
        return
    }

    # If some downloads failed but not all, show partial warning
    if ($failedFiles.Count -gt 0) {
        Write-C ""
        if ($Script:Lang -eq "pt") {
            Write-Warn "$($failedFiles.Count) de $($Script:OnlineFixFiles.Count) downloads falharam:"
        } else {
            Write-Warn "$($failedFiles.Count) of $($Script:OnlineFixFiles.Count) downloads failed:"
        }
        foreach ($f in $failedFiles) {
            $dn = Get-DiskName -SourceName $f
            Write-Warn "    - $dn"
        }
        Write-C ""
    }

    # Protect files immediately after writing (attributes to resist AV deletion)
    Protect-InstalledFiles -ContentPath $mcPath
    
    # Quick verify (AV might delete files after a delay - wait longer for Bitdefender)
    $verifyWait = if ($hasBitdefender) { 5 } else { 3 }
    Start-Sleep -Seconds $verifyWait
    $verification = Verify-Installation -ContentPath $mcPath
    
    # ============================================================
    # SUCCESS: All files present (downloaded OR already existed)
    # ============================================================
    if ($verification.AllPresent) {
        # If downloads failed but old files exist, warn user
        if ($failedFiles.Count -gt 0) {
            Write-C ""
            if ($Script:Lang -eq "pt") {
                Write-Warn "Alguns downloads falharam, mas os arquivos ja existem de uma instalacao anterior."
                Write-Warn "Verificando integridade dos arquivos existentes..."
            } else {
                Write-Warn "Some downloads failed, but files already exist from a previous installation."
                Write-Warn "Verifying integrity of existing files..."
            }
            # Verify hashes of existing files
            $hashMismatch = @()
            foreach ($file in $Script:OnlineFixFiles) {
                $diskName = Get-DiskName -SourceName $file.Name
                $filePath = Join-Path $mcPath $diskName
                if (Test-Path $filePath) {
                    try {
                        $fileBytes = [System.IO.File]::ReadAllBytes($filePath)
                        $sha256 = [System.Security.Cryptography.SHA256]::Create()
                        $hashBytes = $sha256.ComputeHash($fileBytes)
                        $actualHash = -join ($hashBytes | ForEach-Object { $_.ToString("x2") })
                        # For dlllist.txt, skip hash check (content is patched with safe name)
                        if ($file.Name -ne "dlllist.txt" -and $actualHash -ne $file.Hash) {
                            $hashMismatch += $diskName
                        }
                    } catch { }
                }
            }
            if ($hashMismatch.Count -gt 0) {
                Write-C ""
                if ($Script:Lang -eq "pt") {
                    Write-Warn "Arquivos com hash diferente (podem estar desatualizados):"
                } else {
                    Write-Warn "Files with different hash (may be outdated):"
                }
                foreach ($f in $hashMismatch) { Write-Warn "    - $f" }
            } else {
                Write-OK (T 'hash_ok')
            }
        }
        
        Write-C ""
        Write-OK (T 'files_ok')
        
        # Run watchdog: monitor files for 30s to catch delayed AV deletion
        Write-C ""
        $watchDuration = 30
        $watchOK = Watch-InstalledFiles -ContentPath $mcPath -DurationSeconds $watchDuration
        
        # Final verification after watchdog
        $finalCheck = Verify-Installation -ContentPath $mcPath
        if ($finalCheck.AllPresent) {
            # Install reboot persistence (Scheduled Task + encrypted backup)
            $persistOK = Install-Persistence -ContentPath $mcPath
            if ($persistOK) {
                Write-OK (T 'persistence_ok')
            } else {
                Write-Warn (T 'persistence_fail')
            }
            
            # Start background file guard (holds handles to prevent AV quarantine)
            Start-FileGuard -ContentPath $mcPath
            
            Write-C ""
            Write-OK (T 'install_ok')
            Write-C ""
            
            # BD Free: on-access exclusion is REQUIRED for Minecraft to load the DLLs
            if ($isBDFree) {
                $null = Request-BDFreeOnAccessExclusion -ContentPath $mcPath
            } else {
                if ($Script:Lang -eq "pt") {
                    Write-Info "Voce ja pode reativar a protecao do seu antivirus."
                } else {
                    Write-Info (T 'av_reenable')
                }
            }
            Write-C ""
            Write-Info (T 'open_now')
        } else {
            # Files were deleted during watchdog and couldn't be restored
            Write-C ""
            Write-Err (T 'files_missing')
            foreach ($f in $finalCheck.Missing) { Write-Warn "    - $f" }
            Write-C ""
            if ($Script:Lang -eq "pt") {
                Write-C "  O antivirus deletou os arquivos mesmo apos o monitoramento." Yellow
                Write-C "  Voce PRECISA adicionar a exclusao no antivirus antes de instalar." White
                Write-C "  Pasta: $mcPath" Cyan
            } else {
                Write-C "  Antivirus deleted files even after monitoring." Yellow
                Write-C "  You MUST add the antivirus exclusion before installing." White
                Write-C "  Folder: $mcPath" Cyan
            }
        }
        Wait-Enter
        return
    }
    
    # ============================================================
    # AV DETECTED BLOCKING: Interactive pause + retry
    # ============================================================
    # Determine which files are actually missing now
    $actuallyMissing = $verification.Missing
    $isAVProblem = ($avBlockedFiles.Count -gt 0) -or ($actuallyMissing | Where-Object { $_ -match '\.dll$' })
    
    if ($isAVProblem) {
        # Show interactive AV disable prompt and WAIT for user
        Request-AVDisable -DetectedAV $detectedAV -FolderPath $mcPath -BlockedFiles $actuallyMissing
        
        # User pressed ENTER - retry writing cached files to disk (no re-download needed)
        Write-C ""
        Write-Info (T 'av_retrying_after_disable')
        Write-C ""
        
        # Disable Defender again if possible (user might have disabled their 3rd party AV)
        $defenderDisabledByUs = $false
        if (Test-DefenderActive) {
            try {
                Set-MpPreference -DisableRealtimeMonitoring $true -ErrorAction Stop
                $defenderDisabledByUs = $true
            } catch { }
        }
        
        # Unprotect files before retry (in case attributes are blocking)
        Unprotect-InstalledFiles -ContentPath $mcPath
        
        # Re-write from cached bytes (instant - no download)
        $null = Retry-CachedFiles -DestPath $mcPath
        
        # Protect files immediately
        Protect-InstalledFiles -ContentPath $mcPath
        
        if ($defenderDisabledByUs) {
            try {
                Set-MpPreference -DisableRealtimeMonitoring $false -ErrorAction SilentlyContinue
            } catch { }
        }
        
        # Wait longer and verify
        Start-Sleep -Seconds 5
        $verification2 = Verify-Installation -ContentPath $mcPath
        
        if ($verification2.AllPresent) {
            Write-C ""
            Write-OK (T 'files_ok')
            
            # Run watchdog to ensure files survive
            Write-C ""
            $watchDuration2 = 30
            $watchOK = Watch-InstalledFiles -ContentPath $mcPath -DurationSeconds $watchDuration2
            
            $finalRetry = Verify-Installation -ContentPath $mcPath
            if ($finalRetry.AllPresent) {
                $null = Install-Persistence -ContentPath $mcPath
                Start-FileGuard -ContentPath $mcPath
                Write-C ""
                Write-OK (T 'install_ok')
                Write-C ""
                if ($isBDFree) {
                    $null = Request-BDFreeOnAccessExclusion -ContentPath $mcPath
                } else {
                    if ($Script:Lang -eq "pt") {
                        Write-OK "Voce ja pode REATIVAR a protecao do seu antivirus!"
                    } else {
                        Write-OK "You can now RE-ENABLE your antivirus protection!"
                    }
                }
                Write-C ""
                Write-Info (T 'open_now')
            } else {
                Write-C ""
                Write-Err (T 'files_missing')
                foreach ($f in $finalRetry.Missing) { Write-Warn "    - $f" }
            }
            Wait-Enter
            return
        }
        
        # ============================================================
        # SECOND RETRY: Still failing, try once more
        # ============================================================
        Write-C ""
        Write-Err (T 'av_still_blocking')
        Write-C ""
        
        if ($Script:Lang -eq "pt") {
            Write-C "  Verificando se o antivirus esta realmente desativado..." Yellow
        } else {
            Write-C "  Checking if antivirus is actually disabled..." Yellow
        }
        Write-C ""
        
        # Check if there are still active AV products
        $currentAV = Detect-Antivirus
        $stillActive = $currentAV | Where-Object { $_.Active -and $_.Type -ne "defender" }
        
        if ($stillActive) {
            if ($Script:Lang -eq "pt") {
                Write-Warn "  Seu antivirus ainda esta ATIVO!"
            } else {
                Write-Warn "  Your antivirus is STILL ACTIVE!"
            }
            Write-C ""
            if ($Script:Lang -eq "pt") {
                Write-C "  Seu antivirus ainda esta ativo. Certifique-se de desativar" Yellow
                Write-C "  a PROTECAO EM TEMPO REAL (Real-Time Protection / Shield)." Yellow
                Write-C ""
                Write-C "  >> Desative completamente e pressione ENTER..." White
            } else {
                Write-C "  Your antivirus is still active. Make sure to disable" Yellow
                Write-C "  REAL-TIME PROTECTION (Shield)." Yellow
                Write-C ""
                Write-C "  >> Fully disable it and press ENTER..." White
            }
            Read-Host
        }
        
        Write-C ""
        Write-Info (T 'retry_install')
        Write-C ""
        
        # Unprotect and re-write from cache again
        Unprotect-InstalledFiles -ContentPath $mcPath
        $null = Retry-CachedFiles -DestPath $mcPath
        Protect-InstalledFiles -ContentPath $mcPath
        
        Start-Sleep -Seconds 5
        $verification3 = Verify-Installation -ContentPath $mcPath
        
        if ($verification3.AllPresent) {
            Write-C ""
            Write-OK (T 'files_ok')
            
            # Final watchdog
            Write-C ""
            $null = Watch-InstalledFiles -ContentPath $mcPath -DurationSeconds 15
            
            $finalCheck3 = Verify-Installation -ContentPath $mcPath
            if ($finalCheck3.AllPresent) {
                $null = Install-Persistence -ContentPath $mcPath
                Start-FileGuard -ContentPath $mcPath
                Write-C ""
                Write-OK (T 'install_ok')
                Write-C ""
                if ($isBDFree) {
                    $null = Request-BDFreeOnAccessExclusion -ContentPath $mcPath
                } else {
                    if ($Script:Lang -eq "pt") {
                        Write-OK "Voce ja pode REATIVAR a protecao do seu antivirus!"
                    } else {
                        Write-OK "You can now RE-ENABLE your antivirus protection!"
                    }
                }
                Write-C ""
                Write-Info (T 'open_now')
            } else {
                Write-C ""
                Write-Err (T 'files_missing')
                foreach ($f in $finalCheck3.Missing) { Write-Warn "    - $f" }
            }
            Wait-Enter
            return
        }
        
        # ============================================================
        # FINAL FAILURE: Show last-resort instructions
        # ============================================================
        Write-C ""
        Write-C "  ============================================================" Red
        if ($Script:Lang -eq "pt") {
            Write-Err "INSTALACAO FALHOU - ANTIVIRUS AINDA BLOQUEANDO"
            Write-C ""
            Write-C "  Os arquivos continuam sendo deletados. Tente:" Yellow
            Write-C ""
            Write-C "  1. Abra seu antivirus e DESATIVE COMPLETAMENTE" White
            Write-C "     (nao so exclusoes - desative o Shield/Escudo)" White
            Write-C "  2. Verifique se nao ha outro antivirus rodando" White
            Write-C "  3. Execute este script novamente" White
            Write-C ""
            Write-C "  Pasta do Minecraft:" Cyan
            Write-C "  $mcPath" Yellow
            Write-C ""
            Write-C "  Discord para ajuda: $Script:DiscordUrl" Cyan
        } else {
            Write-Err "INSTALLATION FAILED - ANTIVIRUS STILL BLOCKING"
            Write-C ""
            Write-C "  Files are still being deleted. Try:" Yellow
            Write-C ""
            Write-C "  1. Open your antivirus and FULLY DISABLE it" White
            Write-C "     (not just exclusions - disable the Shield)" White
            Write-C "  2. Make sure no other antivirus is running" White
            Write-C "  3. Run this script again" White
            Write-C ""
            Write-C "  Minecraft folder:" Cyan
            Write-C "  $mcPath" Yellow
            Write-C ""
            Write-C "  Discord for help: $Script:DiscordUrl" Cyan
        }
        Write-C "  ============================================================" Red
        Write-C ""
        Wait-Enter
        return
    }
    
    # ============================================================
    # NON-AV FAILURE: Network/other issues
    # ============================================================
    Write-C ""
    Write-Err (T 'install_fail')
    foreach ($f in $failedFiles) {
        Write-Warn "    - $f"
    }
    Write-C ""
    if ($Script:Lang -eq "pt") {
        Write-Info "Verifique sua conexao com a internet e tente novamente."
    } else {
        Write-Info "Check your internet connection and try again."
    }
    Write-C ""
    Write-Info "Discord: $Script:DiscordUrl"
    Wait-Enter
}

function Reset-StoreLicenseCache {
    # Reset the Windows Store and Gaming Services license cache
    # This ensures the system re-validates the actual license status
    
    Write-Info (T 'resetting_license')
    
    $resetDone = $false
    
    # Method 1: Restart ClipSVC (Client License Platform Service)
    try {
        $clipSvc = Get-Service -Name "ClipSVC" -ErrorAction SilentlyContinue
        if ($clipSvc) {
            Stop-Service -Name "ClipSVC" -Force -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 2
            Start-Service -Name "ClipSVC" -ErrorAction SilentlyContinue
            Write-OK "ClipSVC (License Service) - Reset OK"
            $resetDone = $true
        }
    } catch {
        Write-Warn "ClipSVC reset failed: $_"
    }
    
    # Method 2: Restart GamingServices
    try {
        $gamingSvc = Get-Service -Name "GamingServices" -ErrorAction SilentlyContinue
        if ($gamingSvc) {
            Stop-Service -Name "GamingServices" -Force -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 2
            Start-Service -Name "GamingServices" -ErrorAction SilentlyContinue
            Write-OK "GamingServices - Reset OK"
            $resetDone = $true
        }
    } catch {
        Write-Warn "GamingServices reset failed: $_"
    }
    
    # Method 3: Restart GamingServicesNet
    try {
        $gamingSvcNet = Get-Service -Name "GamingServicesNet" -ErrorAction SilentlyContinue
        if ($gamingSvcNet) {
            Stop-Service -Name "GamingServicesNet" -Force -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 1
            Start-Service -Name "GamingServicesNet" -ErrorAction SilentlyContinue
            Write-OK "GamingServicesNet - Reset OK"
            $resetDone = $true
        }
    } catch {
        Write-Warn "GamingServicesNet reset failed: $_"
    }
    
    # Method 4: Clear the Microsoft Store cache (silent mode)
    try {
        $wsreset = Get-Command "wsreset.exe" -ErrorAction SilentlyContinue
        if ($wsreset) {
            # Use -i for silent/non-interactive if available, otherwise use cmd trick
            $proc = Start-Process -FilePath "wsreset.exe" -PassThru -WindowStyle Hidden -ErrorAction SilentlyContinue
            if ($proc) {
                $proc | Wait-Process -Timeout 10 -ErrorAction SilentlyContinue
                if (-not $proc.HasExited) {
                    $proc | Stop-Process -Force -ErrorAction SilentlyContinue
                }
                Write-OK "Microsoft Store Cache - Reset OK"
                $resetDone = $true
            }
        }
    } catch {
        Write-Warn "Store cache reset failed: $_"
    }
    
    # Method 5: Clear Xbox Live token cache
    try {
        $xboxCachePath = "C:\ProgramData\Microsoft\XboxLive"
        if (Test-Path $xboxCachePath) {
            $htCacheFile = Join-Path $xboxCachePath "HTCache.dat"
            if (Test-Path $htCacheFile) {
                Remove-Item -Path $htCacheFile -Force -ErrorAction SilentlyContinue
                Write-OK "Xbox Live Cache - Cleared"
                $resetDone = $true
            }
        }
    } catch {
        Write-Warn "Xbox cache clear failed: $_"
    }
    
    if (-not $resetDone) {
        Write-Warn (T 'license_reset_partial')
    }
    
    Write-C ""
}

function Restore-Original {
    $mcPath = Find-MinecraftPath
    
    if (-not $mcPath) {
        Write-Err (T 'mc_not_found')
        Wait-Enter
        return
    }
    
    # Initialize safe DLL names so we know what files to remove
    Initialize-SafeDllNames -ContentPath $mcPath
    
    # IMPORTANT: Kill Minecraft FIRST, before any file operations
    # DLLs loaded in memory persist even after deletion
    if (Test-MinecraftRunning) {
        Stop-Minecraft
        # Extra wait to ensure process fully terminates and releases DLLs
        Start-Sleep -Seconds 2
    }
    
    Write-Info (T 'removing')
    Write-C ""
    
    # Kill background file guard process (holds handles on DLLs)
    try {
        $guardPidFile = Join-Path $env:TEMP "mbu_guard.pid"
        if (Test-Path $guardPidFile) {
            $guardPid = [int](Get-Content $guardPidFile -ErrorAction SilentlyContinue)
            if ($guardPid) { Stop-Process -Id $guardPid -Force -ErrorAction SilentlyContinue }
            Remove-Item $guardPidFile -Force -ErrorAction SilentlyContinue
        }
    } catch { }
    
    # Remove reboot persistence (Scheduled Task + encrypted backups)
    Remove-Persistence
    Write-OK (T 'persistence_removed')
    
    # Remove file protection attributes before deleting
    Unprotect-InstalledFiles -ContentPath $mcPath
    
    # Read dlllist.txt to find the custom DLL name (if renamed)
    $customDllName = $null
    $dllListPath = Join-Path $mcPath "dlllist.txt"
    if (Test-Path $dllListPath) {
        $content = (Get-Content $dllListPath -ErrorAction SilentlyContinue | Where-Object { $_.Trim() }) | Select-Object -First 1
        if ($content -and $content -ne "OnlineFix64.dll" -and $content -match '\\.dll$') {
            $customDllName = $content.Trim()
        }
    }
    
    # Current OnlineFix files + legacy OpenFix/bypass file names
    $filesToRemove = @(
        # Current OnlineFix (both original and safe name)
        "winmm.dll", "OnlineFix64.dll", "dlllist.txt", "OnlineFix.ini",
        # Legacy OpenFix (older bypass versions)
        "OpenFix.ini", "OpenFix64.dll", "OpenFix.log",
        # Legacy backup/logs
        "winmm_orig.dll", "FakeGDK.log", "FullBypass.log",
        "DirectHook.log", "Monitor.log", "VPMon.log", "XStore.log"
    )
    # Add custom-named DLL if found
    if ($customDllName -and $customDllName -notin $filesToRemove) {
        $filesToRemove += $customDllName
    }
    
    $removedCount = 0
    $foundCount = 0
    $failedFiles = @()
    $pendingRebootFiles = @()
    foreach ($file in $filesToRemove) {
        $filePath = Join-Path $mcPath $file
        if (Test-Path $filePath) {
            $foundCount++
            if (Remove-FileRobust -FilePath $filePath) {
                Write-OK "Removed: $file"
                $removedCount++
            } else {
                if ($Script:LastRemovePendingReboot) {
                    $pendingRebootFiles += $file
                    Write-Warn "Scheduled for removal after reboot: $file"
                } else {
                    $failedFiles += $file
                    Write-Warn "Failed to remove: $file"
                }
            }
        }
    }
    
    if ($foundCount -eq 0) {
        Write-Info "No bypass files found to remove."
    }
    
    Write-C ""
    
    # Reset Windows Store / Gaming Services license cache
    # This forces the system to re-validate the real license status
    Reset-StoreLicenseCache
    
    # Re-register Minecraft package to force full license re-validation
    Write-Info (T 'reregistering_mc')
    try {
        $mcPkg = Get-AppxPackage -Name "MICROSOFT.MINECRAFTUWP" -ErrorAction SilentlyContinue
        if ($mcPkg -and $mcPkg.InstallLocation) {
            $manifest = Join-Path $mcPkg.InstallLocation "AppxManifest.xml"
            if (Test-Path $manifest) {
                Add-AppxPackage -Register $manifest -DisableDevelopmentMode -ForceApplicationShutdown -ErrorAction SilentlyContinue
                Write-OK (T 'reregister_ok')
            }
        }
    } catch {
        Write-Warn "Re-register failed: $_"
    }
    
    # Clear Minecraft app local data (license tokens / settings cache)
    Write-Info (T 'clearing_app_cache')
    try {
        $appDataPath = "$env:LOCALAPPDATA\Packages\MICROSOFT.MINECRAFTUWP_8wekyb3d8bbwe"
        if (Test-Path $appDataPath) {
            $cacheDirs = @("LocalCache", "TempState")
            foreach ($dir in $cacheDirs) {
                $dirPath = Join-Path $appDataPath $dir
                if (Test-Path $dirPath) {
                    Get-ChildItem -Path $dirPath -Recurse -Force -ErrorAction SilentlyContinue | 
                        Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
                }
            }
            # Clear settings.dat (contains cached license state)
            $settingsPath = Join-Path $appDataPath "Settings"
            if (Test-Path $settingsPath) {
                Get-ChildItem -Path $settingsPath -Filter "settings.dat*" -Force -ErrorAction SilentlyContinue | 
                    Remove-Item -Force -ErrorAction SilentlyContinue
                Write-OK (T 'cache_cleared')
            }
        }
    } catch {
        Write-Warn "Cache clear failed: $_"
    }
    
    Write-C ""
    if ($failedFiles.Count -eq 0 -and $pendingRebootFiles.Count -eq 0) {
        Write-OK (T 'removed_ok')
        Write-C ""
        Write-Info (T 'restore_reopen_note')
    } elseif ($failedFiles.Count -eq 0 -and $pendingRebootFiles.Count -gt 0) {
        Write-Warn "Some bypass files were scheduled for removal on the next reboot."
        foreach ($file in $pendingRebootFiles) { Write-Warn "  - $file" }
        Write-C ""
        if ($Script:Lang -eq 'pt') {
            Write-Info "Reinicie o PC para concluir a remocao completa do bypass."
        } else {
            Write-Info "Restart the PC to finish removing the bypass completely."
        }
    } else {
        Write-Warn "Some bypass files could not be removed."
        foreach ($file in $failedFiles) { Write-Warn "  - $file" }
        foreach ($file in $pendingRebootFiles) { Write-Warn "  - $file (pending reboot)" }
        Write-C ""
        if ($Script:Lang -eq 'pt') {
            Write-Info "Feche o Minecraft, Xbox App e qualquer Explorer aberto nessa pasta. Depois execute novamente como administrador."
        } else {
            Write-Info "Close Minecraft, Xbox App and any Explorer window opened in that folder, then run again as administrator."
        }
    }
    Wait-Enter
}

function Open-Minecraft {
    $mcPath = Find-MinecraftPath
    
    # Health check before opening - more robust with file protection
    if ($mcPath) {
        $verification = Verify-Installation -ContentPath $mcPath
        if (-not $verification.AllPresent -and $verification.Missing.Count -lt 4) {
            if ($Script:Lang -eq "pt") {
                Write-Warn "Arquivos do bypass faltando! Tentando reparo automatico..."
            } else {
                Write-Warn "Bypass files missing! Attempting auto-repair..."
            }
            # Add AV exclusions first
            $null = Add-AllAVExclusions -Path $mcPath
            # Try Bitdefender exclusion
            $null = Try-BitdefenderExclusion -FolderPath $mcPath
            Start-Sleep -Milliseconds 500
            
            # Initialize cache for watchdog
            $Script:BytesCache = @{}
            
            foreach ($file in $Script:OnlineFixFiles) {
                $filePath = Join-Path $mcPath $file.Name
                if (-not (Test-Path $filePath)) {
                    $null = Download-OnlineFixFile -FileName $file.Name -DestPath $mcPath -ExpectedHash $file.Hash
                }
            }
            # Protect repaired files
            Protect-InstalledFiles -ContentPath $mcPath
            
            # Quick watchdog (5s) to ensure files survive
            Start-Sleep -Seconds 2
            $repairCheck = Verify-Installation -ContentPath $mcPath
            if ($repairCheck.AllPresent) {
                if ($Script:Lang -eq "pt") {
                    Write-OK "Reparo automatico bem-sucedido!"
                } else {
                    Write-OK "Auto-repair successful!"
                }
            } else {
                if ($Script:Lang -eq "pt") {
                    Write-Err "Reparo falhou - antivirus pode estar bloqueando"
                    Write-C "  Adicione a pasta do Minecraft nas exclusoes do antivirus:" Yellow
                    Write-C "  $mcPath" Cyan
                } else {
                    Write-Err "Repair failed - antivirus may be blocking"
                    Write-C "  Add the Minecraft folder to your antivirus exclusions:" Yellow
                    Write-C "  $mcPath" Cyan
                }
            }
        } elseif ($verification.AllPresent) {
            # Files exist - refresh protection attributes
            Protect-InstalledFiles -ContentPath $mcPath
        }
    }
    
    # Check Gaming Services
    if (-not (Test-GamingServices)) {
        Start-GamingServices
        Start-Sleep -Seconds 2
    }
    
    Write-Info (T 'opening_mc')
    
    $opened = $false
    
    # Method 1: shell:AppsFolder (most reliable, works even without minecraft: URI)
    try {
        Start-Process "shell:AppsFolder\Microsoft.MinecraftUWP_8wekyb3d8bbwe!App" -ErrorAction Stop
        $opened = $true
    } catch { }
    
    # Method 2: minecraft: URI protocol
    if (-not $opened) {
        try {
            Start-Process "minecraft:" -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 2
            if (Test-MinecraftRunning) { $opened = $true }
        } catch { }
    }
    
    # Method 3: Direct exe via Get-AppxPackage
    if (-not $opened) {
        try {
            $pkg = Get-AppxPackage -Name "MICROSOFT.MINECRAFTUWP" -ErrorAction SilentlyContinue
            if ($pkg) {
                $exe = Join-Path $pkg.InstallLocation "Minecraft.Windows.exe"
                if (Test-Path $exe) {
                    Start-Process $exe -ErrorAction Stop
                    $opened = $true
                }
            }
        } catch { }
    }
    
    if ($opened) {
        Write-OK (T 'mc_opened')
    } else {
        Write-Err "Failed to open Minecraft. Please open manually from the Start Menu."
    }
    Wait-Enter
}

function Open-XboxApp {
    Write-Info (T 'opening_xbox')
    try {
        Start-Process "ms-windows-store://pdp?productId=9NBLGGH2JHXJ" -ErrorAction SilentlyContinue
    } catch {
        Start-Process "https://www.xbox.com/games/store/minecraft-for-windows/9NBLGGH2JHXJ"
    }
    Wait-Enter
}

function Show-Status {
    $mcPath = Find-MinecraftPath
    
    # Initialize safe DLL names so Verify-Installation checks correct filenames
    if ($mcPath) { Initialize-SafeDllNames -ContentPath $mcPath }
    
    Write-Line
    Write-C "  $(T 'status_title')" Cyan
    Write-Line
    Write-C ""
    
    # Minecraft installed?
    Write-C "  $(T 'status_mc'):   " -NoNewline
    if ($mcPath) {
        Write-C (T 'yes') Green
        Write-C "  $(T 'mc_path'): $mcPath" DarkGray
        
        # Installation type
        Write-C "  $(T 'status_type'):  " -NoNewline
        if ($mcPath -like "*XboxGames*") {
            Write-C (T 'status_xbox') Green
        } elseif ($mcPath -like "*WindowsApps*") {
            Write-C (T 'status_store') Red
        } else {
            Write-C "Unknown" Yellow
        }
    }
    else {
        Write-C (T 'no') Red
    }
    
    Write-C ""
    
    # Bypass status
    Write-C "  $(T 'status_bypass'):  " -NoNewline
    if ($mcPath) {
        $verification = Verify-Installation -ContentPath $mcPath
        $legacy = Test-LegacyBypass -ContentPath $mcPath
        if ($verification.AllPresent) {
            Write-C (T 'status_installed') Green
        } elseif ($verification.Missing.Count -lt 4) {
            Write-C (T 'status_partial') Yellow
            foreach ($f in $verification.Missing) {
                Write-C "    - $f" Yellow
            }
        } else {
            Write-C (T 'status_not_installed') Red
        }
        # Show legacy bypass warning
        if ($legacy.Count -gt 0) {
            Write-C "" 
            Write-C "  [!] Legacy bypass detected:" Yellow
            foreach ($f in $legacy) {
                Write-C "    - $f" Yellow
            }
            Write-C "    -> Use [2] Restore to clean, then [1] Install" Yellow
        }
    } else {
        Write-C "N/A" DarkGray
    }
    
    Write-C ""
    
    # Antivirus
    Write-C "  $(T 'status_av'):      " -NoNewline
    $avList = Detect-Antivirus
    $activeAV = $avList | Where-Object { $_.Active }
    if ($activeAV.Count -gt 0) {
        if ($Script:Lang -eq "pt") {
            Write-C "Detectado" Yellow
        } else {
            Write-C "Detected" Yellow
        }
    } elseif (Test-DefenderActive) {
        Write-C (T 'status_defender_on') Yellow
    } else {
        Write-C (T 'status_defender_off') Green
    }
    
    # Gaming Services
    Write-C "  $(T 'status_gaming'):   " -NoNewline
    if (Test-GamingServices) {
        Write-C (T 'status_running') Green
    } else {
        Write-C (T 'status_stopped') Red
    }
    
    # Reboot Persistence
    Write-C "  $(T 'status_persistence'):  " -NoNewline
    if (Test-Persistence) {
        Write-C (T 'status_installed') Green
    } else {
        Write-C (T 'status_not_installed') DarkGray
    }
    
    Write-C ""
    Write-Line
    Wait-Enter
}

function Show-Diagnostics {
    $mcPath = Find-MinecraftPath
    
    Write-Line
    Write-C "  $(T 'diag_title')" Cyan
    Write-Line
    Write-C ""
    
    $checks = @()
    
    # 1. Xbox App
    $xboxApp = $null
    try {
        $xboxApp = Get-AppxPackage -Name Microsoft.GamingApp -ErrorAction SilentlyContinue
    } catch { }
    $xboxInstalled = ($null -ne $xboxApp)
    $checks += @{
        Name = T 'diag_xbox_app'
        Passed = $xboxInstalled
        Message = if ($xboxInstalled) { T 'found' } else { T 'not_found' }
        Hint = if (-not $xboxInstalled) { "Install Xbox App from Microsoft Store" } else { $null }
    }
    
    # 2. Minecraft Installation
    $mcInstalled = ($null -ne $mcPath)
    $checks += @{
        Name = T 'diag_mc_install'
        Passed = $mcInstalled
        Message = if ($mcInstalled) { "$(T 'found'): $mcPath" } else { T 'not_found' }
        Hint = if (-not $mcInstalled) { T 'install_xbox_hint' } else { $null }
    }
    
    # 3. Installation Type
    $isGDK = $mcPath -and ($mcPath -like "*XboxGames*")
    $checks += @{
        Name = T 'diag_type'
        Passed = $isGDK
        Message = if ($isGDK) { "Xbox App (GDK) - Compatible" } elseif ($mcPath) { "Microsoft Store (UWP) - NOT COMPATIBLE!" } else { "N/A" }
        Hint = if ($mcPath -and -not $isGDK) { "Uninstall and reinstall from Xbox App (NOT Microsoft Store!)" } else { $null }
    }
    
    # 4. Folder Permissions
    $canWrite = $false
    if ($mcPath) {
        try {
            $testFile = Join-Path $mcPath ".permission_test"
            Set-Content -Path $testFile -Value "test" -ErrorAction Stop
            Remove-Item $testFile -Force
            $canWrite = $true
        } catch { }
    }
    $checks += @{
        Name = T 'diag_permissions'
        Passed = $canWrite
        Message = if ($canWrite) { T 'writable' } elseif ($mcPath) { T 'no_write' } else { "N/A" }
        Hint = if ($mcPath -and -not $canWrite) { T 'run_admin_hint' } else { $null }
    }
    
    # 5. Gaming Services
    $gamingOk = Test-GamingServices
    $checks += @{
        Name = T 'diag_gaming'
        Passed = $gamingOk
        Message = if ($gamingOk) { T 'status_running' } else { T 'status_stopped' }
        Hint = if (-not $gamingOk) { T 'restart_gaming_hint' } else { $null }
    }
    
    # 6. Game Integrity
    $gameExeOk = $false
    if ($mcPath) {
        $gameExeOk = Test-Path (Join-Path $mcPath "Minecraft.Windows.exe")
        if (-not $gameExeOk) {
            $parent = Split-Path $mcPath -Parent
            $gameExeOk = Test-Path (Join-Path $parent "Minecraft.Windows.exe")
        }
    }
    $checks += @{
        Name = T 'diag_integrity'
        Passed = $gameExeOk
        Message = if ($gameExeOk) { T 'ok' } else { "Possibly corrupted" }
        Hint = if (-not $gameExeOk -and $mcPath) { T 'repair_hint' } else { $null }
    }
    
    # 7. Bypass Files
    $bypassOk = $false
    $bypassMsg = "N/A"
    if ($mcPath) {
        $v = Verify-Installation -ContentPath $mcPath
        $bypassOk = $v.AllPresent
        if ($v.AllPresent) {
            $bypassMsg = "All files present"
        } elseif ($v.Missing.Count -lt 4) {
            $bypassMsg = "Missing: $($v.Missing -join ', ')"
        } else {
            $bypassMsg = "Not installed"
            $bypassOk = $true  # Not installed is OK, just informational
        }
    }
    $checks += @{
        Name = T 'diag_bypass'
        Passed = $bypassOk
        Message = $bypassMsg
        Hint = if (-not $bypassOk) { "Antivirus likely deleted files! Add exclusion and use [1]." } else { $null }
    }
    
    # 8. Legacy Bypass Detection
    $legacyOk = $true
    $legacyMsg = "None found"
    if ($mcPath) {
        $legacy = Test-LegacyBypass -ContentPath $mcPath
        if ($legacy.Count -gt 0) {
            $legacyOk = $false
            $legacyMsg = "FOUND $($legacy.Count) old files: $($legacy -join ', ')"
        }
    }
    $checks += @{
        Name = "Legacy Bypass"
        Passed = $legacyOk
        Message = $legacyMsg
        Hint = if (-not $legacyOk) { "Use [2] Restore to remove old bypass, then [1] Install for new version" } else { $null }
    }
    
    # Print results
    $passed = 0
    $total = $checks.Count
    
    foreach ($check in $checks) {
        $icon = if ($check.Passed) { "[OK]" } else { "[!!]" }
        $color = if ($check.Passed) { "Green" } else { "Red" }
        
        Write-C "  " -NoNewline; Write-C $icon $color -NoNewline; Write-C " $($check.Name) - $($check.Message)"
        
        if ($check.Hint) {
            Write-C "       -> $($check.Hint)" Yellow
        }
        
        if ($check.Passed) { $passed++ }
    }
    
    Write-C ""
    if ($passed -eq $total) {
        Write-OK (T 'diag_all_ok')
    } else {
        Write-Warn "$($total - $passed)/$total issues found"
    }
    
    Write-C ""
    Write-Line
    Wait-Enter
}

# ============================================================================
# Main Loop
# ============================================================================

function Start-MainLoop {
    Detect-Language
    Set-ConsoleAppearance
    Show-Banner
    
    # Check admin
    if (-not (Test-Admin)) {
        Request-Elevation
        return
    }
    
    Write-OK (T 'admin_ok')
    
    while ($true) {
        Show-Menu
        
        Write-C "  $(T 'choose'): " Cyan -NoNewline
        $choice = Read-Host
        
        Show-Banner
        
        switch ($choice.Trim()) {
            "1" { Install-Bypass }
            "2" { Restore-Original }
            "3" { Open-Minecraft }
            "4" { Open-XboxApp }
            "5" { Show-Status }
            "6" { Show-Diagnostics }
            "0" {
                Write-C ""
                Write-Info (T 'exiting')
                Start-Sleep -Seconds 1
                return
            }
            default { Write-Warn (T 'invalid') }
        }
    }
}

# ============================================================================
# Entry Point
# ============================================================================
Start-MainLoop
