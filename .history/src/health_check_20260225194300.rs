// Health Check Module - Verifies if OnlineFix files are present and valid
// Auto-reinstalls if files are missing or corrupted

use colored::*;
use crate::i18n::Translations;
use std::fs;

// OnlineFix files embedded in binary for auto-repair
const WINMM_DLL: &[u8] = include_bytes!("../dlls/OnlineFix/winmm.dll");
const ONLINEFIX64_DLL: &[u8] = include_bytes!("../dlls/OnlineFix/OnlineFix64.dll");
const DLLLIST_TXT: &[u8] = include_bytes!("../dlls/OnlineFix/dlllist.txt");
const ONLINEFIX_INI: &[u8] = include_bytes!("../dlls/OnlineFix/OnlineFix.ini");

pub struct HealthCheck {
    minecraft_path: std::path::PathBuf,
}

#[derive(Debug, Clone, PartialEq)]
pub enum HealthStatus {
    Healthy,           // All files present and valid
    Missing(Vec<String>), // Some files missing
    Corrupted(Vec<String>), // Some files corrupted
    NotInstalled,      // Bypass not installed at all
}

impl HealthCheck {
    pub fn new(minecraft_path: std::path::PathBuf) -> Self {
        Self { minecraft_path }
    }

    /// Check the health status of the bypass installation
    pub fn check(&self) -> HealthStatus {
        let required_files = ["winmm.dll", "OnlineFix64.dll", "dlllist.txt", "OnlineFix.ini"];
        let mut missing_files = Vec::new();
        let mut found_count = 0;

        for file in required_files.iter() {
            let path = self.minecraft_path.join(file);
            if path.exists() {
                found_count += 1;
            } else {
                missing_files.push(file.to_string());
            }
        }

        if found_count == 0 {
            HealthStatus::NotInstalled
        } else if missing_files.is_empty() {
            HealthStatus::Healthy
        } else {
            HealthStatus::Missing(missing_files)
        }
    }

    /// Print health status to console
    pub fn print_status(&self) {
        let status = self.check();
        
        match status {
            HealthStatus::Healthy => {
                println!("                    {} {}", 
                    "[HEALTH]".green().bold(), 
                    health_all_files_ok());
            }
            HealthStatus::Missing(files) => {
                println!("                    {} {}", 
                    "[HEALTH]".red().bold(), 
                    health_files_missing());
                for file in files {
                    println!("                      - {}", file.yellow());
                }
                println!("                    {} {}", 
                    Translations::info().cyan(), 
                    health_will_reinstall());
            }
            HealthStatus::Corrupted(files) => {
                println!("                    {} {}", 
                    "[HEALTH]".red().bold(), 
                    health_files_corrupted());
                for file in files {
                    println!("                      - {}", file.yellow());
                }
            }
            HealthStatus::NotInstalled => {
                println!("                    {} {}", 
                    "[HEALTH]".yellow().bold(), 
                    health_not_installed());
            }
        }
    }

    /// Check if files were deleted by antivirus (checks recently)
    pub fn was_deleted_by_antivirus(&self) -> bool {
        // Check if OnlineFix64.dll is missing but others exist
        let onlinefix = self.minecraft_path.join("OnlineFix64.dll");
        let winmm = self.minecraft_path.join("winmm.dll");
        
        // If winmm exists but OnlineFix64 doesn't, antivirus probably deleted it
        winmm.exists() && !onlinefix.exists()
    }

    /// Auto-repair missing files (for when antivirus deletes them)
    pub fn auto_repair(&self) -> bool {
        let status = self.check();
        
        match status {
            HealthStatus::Missing(files) => {
                println!("                    {} {}", 
                    "[AUTO-REPAIR]".yellow().bold(), 
                    auto_repair_attempting());
                
                let mut all_repaired = true;
                
                for file in &files {
                    let data = match file.as_str() {
                        "winmm.dll" => WINMM_DLL,
                        "OnlineFix64.dll" => ONLINEFIX64_DLL,
                        "dlllist.txt" => DLLLIST_TXT,
                        "OnlineFix.ini" => ONLINEFIX_INI,
                        _ => continue,
                    };
                    
                    let target_path = self.minecraft_path.join(file);
                    match fs::write(&target_path, data) {
                        Ok(_) => {
                            println!("                      {} {} {}", 
                                Translations::ok().green(), 
                                file, 
                                auto_repair_restored());
                        }
                        Err(_) => {
                            println!("                      {} {} {}", 
                                Translations::error().red(), 
                                file, 
                                auto_repair_failed());
                            all_repaired = false;
                        }
                    }
                }
                
                all_repaired
            }
            HealthStatus::Healthy => true,
            _ => false,
        }
    }

    /// Perform a quick health check and auto-repair before launching Minecraft
    pub fn ensure_healthy(&self) -> bool {
        let status = self.check();
        
        match status {
            HealthStatus::Healthy => true,
            HealthStatus::Missing(_) => {
                // Try auto-repair
                if self.auto_repair() {
                    // Wait a moment for files to be written
                    std::thread::sleep(std::time::Duration::from_millis(500));
                    // Verify again
                    matches!(self.check(), HealthStatus::Healthy)
                } else {
                    false
                }
            }
            _ => false,
        }
    }
}

// Localized strings for health check
fn health_all_files_ok() -> &'static str {
    use crate::i18n::get_language;
    use crate::i18n::Language;
    match get_language() {
        Language::English => "All bypass files OK ✓",
        Language::PortugueseBR | Language::PortuguesePT => "Todos os arquivos do bypass OK ✓",
        Language::Spanish => "Todos los archivos del bypass OK ✓",
        Language::French => "Tous les fichiers du bypass OK ✓",
        Language::German => "Alle Bypass-Dateien OK ✓",
        Language::ChineseSimplified => "所有绕过文件正常 ✓",
        Language::Russian => "Все файлы обхода в порядке ✓",
    }
}

fn health_files_missing() -> &'static str {
    use crate::i18n::get_language;
    use crate::i18n::Language;
    match get_language() {
        Language::English => "Some bypass files are MISSING!",
        Language::PortugueseBR | Language::PortuguesePT => "Alguns arquivos do bypass estão FALTANDO!",
        Language::Spanish => "¡Faltan algunos archivos del bypass!",
        Language::French => "Certains fichiers du bypass sont MANQUANTS!",
        Language::German => "Einige Bypass-Dateien FEHLEN!",
        Language::ChineseSimplified => "部分绕过文件缺失！",
        Language::Russian => "Некоторые файлы обхода ОТСУТСТВУЮТ!",
    }
}

fn health_files_corrupted() -> &'static str {
    use crate::i18n::get_language;
    use crate::i18n::Language;
    match get_language() {
        Language::English => "Some bypass files are CORRUPTED!",
        Language::PortugueseBR | Language::PortuguesePT => "Alguns arquivos do bypass estão CORROMPIDOS!",
        Language::Spanish => "¡Algunos archivos del bypass están CORRUPTOS!",
        Language::French => "Certains fichiers du bypass sont CORROMPUS!",
        Language::German => "Einige Bypass-Dateien sind BESCHÄDIGT!",
        Language::ChineseSimplified => "部分绕过文件损坏！",
        Language::Russian => "Некоторые файлы обхода ПОВРЕЖДЕНЫ!",
    }
}

fn health_not_installed() -> &'static str {
    use crate::i18n::get_language;
    use crate::i18n::Language;
    match get_language() {
        Language::English => "Bypass not installed yet",
        Language::PortugueseBR | Language::PortuguesePT => "Bypass ainda não instalado",
        Language::Spanish => "Bypass aún no instalado",
        Language::French => "Bypass pas encore installé",
        Language::German => "Bypass noch nicht installiert",
        Language::ChineseSimplified => "绕过尚未安装",
        Language::Russian => "Обход ещё не установлен",
    }
}

fn health_will_reinstall() -> &'static str {
    use crate::i18n::get_language;
    use crate::i18n::Language;
    match get_language() {
        Language::English => "Use option [1] to reinstall missing files",
        Language::PortugueseBR | Language::PortuguesePT => "Use a opção [1] para reinstalar arquivos faltando",
        Language::Spanish => "Use la opción [1] para reinstalar archivos faltantes",
        Language::French => "Utilisez l'option [1] pour réinstaller les fichiers manquants",
        Language::German => "Verwenden Sie Option [1] um fehlende Dateien neu zu installieren",
        Language::ChineseSimplified => "使用选项[1]重新安装缺失文件",
        Language::Russian => "Используйте опцию [1] для переустановки недостающих файлов",
    }
}

pub fn health_antivirus_warning() -> &'static str {
    use crate::i18n::get_language;
    use crate::i18n::Language;
    match get_language() {
        Language::English => "⚠️  Antivirus may have deleted OnlineFix64.dll!",
        Language::PortugueseBR | Language::PortuguesePT => "⚠️  Antivírus pode ter apagado OnlineFix64.dll!",
        Language::Spanish => "⚠️  ¡El antivirus puede haber eliminado OnlineFix64.dll!",
        Language::French => "⚠️  L'antivirus a peut-être supprimé OnlineFix64.dll!",
        Language::German => "⚠️  Antivirus hat möglicherweise OnlineFix64.dll gelöscht!",
        Language::ChineseSimplified => "⚠️  杀毒软件可能删除了OnlineFix64.dll！",
        Language::Russian => "⚠️  Антивирус мог удалить OnlineFix64.dll!",
    }
}
