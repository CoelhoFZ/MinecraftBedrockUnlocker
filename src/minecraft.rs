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
    
    Command::new("cmd")
        .args(&["/C", "start", "minecraft:"])
        .spawn()
        .context("Failed to open Minecraft")?;
    
    println!("             {} {}", Translations::ok().green(), Translations::minecraft_started());
    Ok(())
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
    let mut drives = Vec::new();
    
    #[cfg(target_os = "windows")]
    {
        extern "system" {
            fn GetLogicalDrives() -> u32;
        }
        
        let bitmask = unsafe { GetLogicalDrives() };
        
        for i in 0..26u32 {
            if (bitmask & (1 << i)) != 0 {
                let drive_letter = (b'A' + i as u8) as char;
                if drive_letter != 'A' && drive_letter != 'B' {
                    drives.push(drive_letter);
                }
            }
        }
    }
    
    #[cfg(not(target_os = "windows"))]
    {
        drives = vec!['C', 'D', 'E', 'F', 'G'];
    }
    
    drives
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
