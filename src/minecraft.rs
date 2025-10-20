use anyhow::{Context, Result};
use colored::*;
use std::process::Command;
use winreg::enums::*;
use winreg::RegKey;
use crate::i18n::Translations;

pub fn is_minecraft_installed() -> bool {
    // Check via Registry
    if check_registry_current_user() {
        return true;
    }

    // Check WindowsApps folder
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
    
    let uri = "ms-windows-store://pdp/?productid=9NBLGGH2JHXJ";
    Command::new("cmd")
        .args(&["/C", "start", uri])
        .spawn()
        .context("Failed to open Microsoft Store")?;
    
    println!("             {} {}", Translations::ok().green(), Translations::store_opened());
    Ok(())
}

fn check_registry_current_user() -> bool {
    let hkcu = RegKey::predef(HKEY_CURRENT_USER);
    
    if let Ok(packages) = hkcu.open_subkey("Software\\Classes\\Local Settings\\Software\\Microsoft\\Windows\\CurrentVersion\\AppModel\\Repository\\Packages") {
        for key_name in packages.enum_keys().filter_map(|k| k.ok()) {
            if key_name.to_lowercase().contains("microsoft.minecraftuwp") {
                return true;
            }
        }
    }
    
    false
}

fn check_windows_apps() -> bool {
    let program_files = std::env::var("ProgramFiles")
        .unwrap_or_else(|_| "C:\\Program Files".to_string());
    
    let windows_apps = std::path::PathBuf::from(program_files).join("WindowsApps");
    
    if windows_apps.exists() {
        if let Ok(entries) = std::fs::read_dir(&windows_apps) {
            for entry in entries.filter_map(|e| e.ok()) {
                if let Some(name) = entry.file_name().to_str() {
                    if name.to_lowercase().contains("microsoft.minecraftuwp") {
                        return true;
                    }
                }
            }
        }
    }
    
    false
}
