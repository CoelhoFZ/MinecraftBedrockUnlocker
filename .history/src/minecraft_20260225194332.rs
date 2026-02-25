use anyhow::{Context, Result};
use colored::*;
use std::process::Command;
use std::path::PathBuf;
use winreg::enums::*;
use winreg::RegKey;
use crate::i18n::Translations;

pub fn is_minecraft_installed() -> bool {
    // Priority 1: Check XboxGames folder (GDK installation)
    if check_xbox_games() {
        return true;
    }

    // Priority 2: Check via Registry
    if check_registry_current_user() {
        return true;
    }

    // Priority 3: Check WindowsApps folder (old UWP method)
    if check_windows_apps() {
        return true;
    }

    false
}

pub fn open_minecraft() -> Result<()> {
    println!("             {} {}", Translations::info().cyan(), Translations::opening_minecraft());
    
    // First, check if Gaming Services is running
    if !is_gaming_services_running() {
        println!("             {} {}", Translations::warning().yellow(), gaming_services_not_running());
        println!("             {} {}", Translations::info().cyan(), starting_gaming_services());
        start_gaming_services();
        std::thread::sleep(std::time::Duration::from_secs(2));
    }
    
    Command::new("cmd")
        .args(&["/C", "start", "minecraft:"])
        .spawn()
        .context("Failed to open Minecraft")?;
    
    println!("             {} {}", Translations::ok().green(), Translations::minecraft_started());
    Ok(())
}

/// Check if Gaming Services is running
fn is_gaming_services_running() -> bool {
    let script = r#"
        $service = Get-Service -Name GamingServices -ErrorAction SilentlyContinue
        if ($service -and $service.Status -eq 'Running') { 
            Write-Output "running" 
        } else { 
            Write-Output "stopped" 
        }
    "#;

    let output = Command::new("powershell")
        .args(["-NoProfile", "-Command", script])
        .output();

    match output {
        Ok(out) => String::from_utf8_lossy(&out.stdout).contains("running"),
        Err(_) => true, // Assume running if we can't check
    }
}

/// Try to start Gaming Services
fn start_gaming_services() {
    let _ = Command::new("powershell")
        .args([
            "-NoProfile",
            "-Command",
            "Start-Service GamingServices -ErrorAction SilentlyContinue"
        ])
        .output();
}

fn gaming_services_not_running() -> &'static str {
    use crate::i18n::get_language;
    use crate::i18n::Language;
    match get_language() {
        Language::English => "Gaming Services is not running",
        Language::PortugueseBR | Language::PortuguesePT => "Gaming Services não está rodando",
        Language::Spanish => "Gaming Services no está ejecutándose",
        Language::French => "Gaming Services n'est pas en cours d'exécution",
        Language::German => "Gaming Services läuft nicht",
        Language::ChineseSimplified => "游戏服务未运行",
        Language::Russian => "Gaming Services не запущен",
    }
}

fn starting_gaming_services() -> &'static str {
    use crate::i18n::get_language;
    use crate::i18n::Language;
    match get_language() {
        Language::English => "Attempting to start Gaming Services...",
        Language::PortugueseBR | Language::PortuguesePT => "Tentando iniciar Gaming Services...",
        Language::Spanish => "Intentando iniciar Gaming Services...",
        Language::French => "Tentative de démarrage de Gaming Services...",
        Language::German => "Versuche Gaming Services zu starten...",
        Language::ChineseSimplified => "正在尝试启动游戏服务...",
        Language::Russian => "Попытка запустить Gaming Services...",
    }
}

pub fn open_store() -> Result<()> {
    println!("             {} {}", Translations::info().cyan(), Translations::opening_store());
    
    // Open Xbox website with Minecraft page (installation via Xbox App required)
    let url = "https://www.xbox.com/games/store/minecraft-for-windows/9NBLGGH2JHXJ";
    Command::new("cmd")
        .args(&["/C", "start", url])
        .spawn()
        .context("Failed to open browser")?;
    
    println!("             {} {}", Translations::ok().green(), Translations::store_opened());
    Ok(())
}

fn check_xbox_games() -> bool {
    // Check XboxGames folder on all available drives (GDK installation location)
    let drives = get_available_drives();
    
    for drive in drives {
        let path = PathBuf::from(format!(r"{}:\XboxGames\Minecraft for Windows\Content", drive));
        if path.exists() {
            // Check for Minecraft.Windows.exe
            let exe_path = path.join("Minecraft.Windows.exe");
            if exe_path.exists() {
                return true;
            }
        }
    }
    
    false
}

/// Get all available drive letters on the system using Windows API
fn get_available_drives() -> Vec<char> {
    crate::utils::get_available_drives()
}

fn check_registry_current_user() -> bool {
    let hkcu = RegKey::predef(HKEY_CURRENT_USER);
    
    if let Ok(packages) = hkcu.open_subkey("Software\\Classes\\Local Settings\\Software\\Microsoft\\Windows\\CurrentVersion\\AppModel\\Repository\\Packages") {
        for key_name in packages.enum_keys().filter_map(|k| k.ok()) {
            let key_lower = key_name.to_lowercase();
            if key_lower.contains("microsoft.minecraftuwp") || key_lower.contains("microsoft.minecraft") {
                return true;
            }
        }
    }
    
    false
}

fn check_windows_apps() -> bool {
    let program_files = std::env::var("ProgramFiles")
        .unwrap_or_else(|_| "C:\\Program Files".to_string());
    
    let windows_apps = PathBuf::from(program_files).join("WindowsApps");
    
    if windows_apps.exists() {
        if let Ok(entries) = std::fs::read_dir(&windows_apps) {
            for entry in entries.filter_map(|e| e.ok()) {
                if let Some(name) = entry.file_name().to_str() {
                    let name_lower = name.to_lowercase();
                    if name_lower.contains("microsoft.minecraftuwp") || name_lower.contains("microsoft.minecraft") {
                        return true;
                    }
                }
            }
        }
    }
    
    false
}
