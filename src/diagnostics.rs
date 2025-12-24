// Diagnostics Module - Detects common problems and suggests solutions
// Checks: Xbox App, Microsoft login, folder permissions, Minecraft integrity

use colored::*;
use std::process::Command;
use std::path::Path;
use crate::i18n::{get_language, Language};

pub struct Diagnostics {
    minecraft_path: std::path::PathBuf,
}

#[derive(Debug, Clone)]
pub struct DiagnosticResult {
    pub name: String,
    pub passed: bool,
    pub message: String,
    pub suggestion: Option<String>,
}

impl Diagnostics {
    pub fn new(minecraft_path: std::path::PathBuf) -> Self {
        Self { minecraft_path }
    }

    /// Run all diagnostic checks
    pub fn run_all(&self) -> Vec<DiagnosticResult> {
        vec![
            self.check_xbox_app(),
            self.check_minecraft_installed(),
            self.check_folder_permissions(),
            self.check_gaming_services(),
            self.check_minecraft_integrity(),
        ]
    }

    /// Check if Xbox App is installed
    fn check_xbox_app(&self) -> DiagnosticResult {
        let script = r#"
            $app = Get-AppxPackage -Name Microsoft.GamingApp 2>$null
            if ($app) { Write-Output "installed" } else { Write-Output "missing" }
        "#;

        let output = Command::new("powershell")
            .args(["-NoProfile", "-Command", script])
            .output();

        let installed = match output {
            Ok(out) => String::from_utf8_lossy(&out.stdout).contains("installed"),
            Err(_) => false,
        };

        DiagnosticResult {
            name: diag_xbox_app().to_string(),
            passed: installed,
            message: if installed { diag_installed().to_string() } else { diag_not_found().to_string() },
            suggestion: if installed { None } else { Some(diag_install_xbox().to_string()) },
        }
    }

    /// Check if Minecraft is installed
    fn check_minecraft_installed(&self) -> DiagnosticResult {
        let exists = self.minecraft_path.exists();
        
        DiagnosticResult {
            name: diag_minecraft().to_string(),
            passed: exists,
            message: if exists { 
                format!("{}: {}", diag_found(), self.minecraft_path.display())
            } else { 
                diag_not_found().to_string() 
            },
            suggestion: if exists { None } else { Some(diag_install_minecraft().to_string()) },
        }
    }

    /// Check folder write permissions
    fn check_folder_permissions(&self) -> DiagnosticResult {
        let test_file = self.minecraft_path.join(".permission_test");
        
        let can_write = std::fs::write(&test_file, "test").is_ok();
        if can_write {
            let _ = std::fs::remove_file(&test_file);
        }

        DiagnosticResult {
            name: diag_permissions().to_string(),
            passed: can_write,
            message: if can_write { diag_writable().to_string() } else { diag_no_write().to_string() },
            suggestion: if can_write { None } else { Some(diag_run_admin().to_string()) },
        }
    }

    /// Check if Gaming Services is running
    fn check_gaming_services(&self) -> DiagnosticResult {
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

        let running = match output {
            Ok(out) => String::from_utf8_lossy(&out.stdout).contains("running"),
            Err(_) => false,
        };

        DiagnosticResult {
            name: diag_gaming_services().to_string(),
            passed: running,
            message: if running { diag_running().to_string() } else { diag_stopped().to_string() },
            suggestion: if running { None } else { Some(diag_restart_gaming().to_string()) },
        }
    }

    /// Check Minecraft installation integrity
    fn check_minecraft_integrity(&self) -> DiagnosticResult {
        // Check for essential game files
        let essential_files = [
            "Minecraft.Windows.exe",
            "bedrock_server.exe",
        ];

        let mut found_exe = false;
        for file in essential_files.iter() {
            // Search in parent directory (Content is inside the app folder)
            let parent = self.minecraft_path.parent().unwrap_or(&self.minecraft_path);
            let path = parent.join(file);
            if path.exists() {
                found_exe = true;
                break;
            }
            // Also check in content folder itself
            if self.minecraft_path.join(file).exists() {
                found_exe = true;
                break;
            }
        }

        // Check for Minecraft.Windows.exe in parent
        let parent = self.minecraft_path.parent().unwrap_or(&self.minecraft_path);
        let main_exe = parent.join("Minecraft.Windows.exe");
        
        DiagnosticResult {
            name: diag_integrity().to_string(),
            passed: main_exe.exists() || found_exe,
            message: if main_exe.exists() || found_exe { 
                diag_ok().to_string() 
            } else { 
                diag_possibly_corrupted().to_string() 
            },
            suggestion: if main_exe.exists() || found_exe { None } else { 
                Some(diag_repair_minecraft().to_string()) 
            },
        }
    }

    /// Print all diagnostic results
    pub fn print_results(&self) {
        println!();
        println!("                    ════════════════════════════════════════════════════");
        println!("                                     {}                    ", 
            diag_title().cyan().bold());
        println!("                    ════════════════════════════════════════════════════");
        println!();

        let results = self.run_all();
        
        for result in &results {
            let status = if result.passed {
                "✓".green().bold()
            } else {
                "✗".red().bold()
            };

            println!("             {} {} - {}", status, result.name.white(), result.message);
            
            if let Some(suggestion) = &result.suggestion {
                println!("                {} {}", "→".yellow(), suggestion.yellow());
            }
        }

        println!();
        
        let passed = results.iter().filter(|r| r.passed).count();
        let total = results.len();
        
        if passed == total {
            println!("             {} {}", 
                "[✓]".green().bold(), 
                diag_all_passed());
        } else {
            println!("             {} {} {}/{}", 
                "[!]".yellow().bold(), 
                diag_issues_found(),
                total - passed,
                total);
        }

        println!();
        println!("                    ════════════════════════════════════════════════════");
    }
}

// Localized strings
fn diag_title() -> &'static str {
    match get_language() {
        Language::English => "SYSTEM DIAGNOSTICS",
        Language::PortugueseBR | Language::PortuguesePT => "DIAGNÓSTICO DO SISTEMA",
        Language::Spanish => "DIAGNÓSTICO DEL SISTEMA",
        Language::French => "DIAGNOSTIC SYSTÈME",
        Language::German => "SYSTEMDIAGNOSE",
        Language::ChineseSimplified => "系统诊断",
        Language::Russian => "ДИАГНОСТИКА СИСТЕМЫ",
    }
}

fn diag_xbox_app() -> &'static str {
    match get_language() {
        Language::English => "Xbox App",
        Language::PortugueseBR | Language::PortuguesePT => "Xbox App",
        Language::Spanish => "Xbox App",
        _ => "Xbox App",
    }
}

fn diag_minecraft() -> &'static str {
    match get_language() {
        Language::English => "Minecraft Installation",
        Language::PortugueseBR | Language::PortuguesePT => "Instalação do Minecraft",
        Language::Spanish => "Instalación de Minecraft",
        Language::French => "Installation Minecraft",
        Language::German => "Minecraft Installation",
        Language::ChineseSimplified => "Minecraft安装",
        Language::Russian => "Установка Minecraft",
    }
}

fn diag_permissions() -> &'static str {
    match get_language() {
        Language::English => "Folder Permissions",
        Language::PortugueseBR | Language::PortuguesePT => "Permissões de Pasta",
        Language::Spanish => "Permisos de Carpeta",
        Language::French => "Permissions du Dossier",
        Language::German => "Ordnerberechtigungen",
        Language::ChineseSimplified => "文件夹权限",
        Language::Russian => "Права папки",
    }
}

fn diag_gaming_services() -> &'static str {
    match get_language() {
        Language::English => "Gaming Services",
        Language::PortugueseBR | Language::PortuguesePT => "Serviços de Jogos",
        Language::Spanish => "Servicios de Juegos",
        Language::French => "Services de Jeux",
        Language::German => "Gaming-Dienste",
        Language::ChineseSimplified => "游戏服务",
        Language::Russian => "Игровые сервисы",
    }
}

fn diag_integrity() -> &'static str {
    match get_language() {
        Language::English => "Game Integrity",
        Language::PortugueseBR | Language::PortuguesePT => "Integridade do Jogo",
        Language::Spanish => "Integridad del Juego",
        Language::French => "Intégrité du Jeu",
        Language::German => "Spielintegrität",
        Language::ChineseSimplified => "游戏完整性",
        Language::Russian => "Целостность игры",
    }
}

fn diag_installed() -> &'static str {
    match get_language() {
        Language::English => "Installed",
        Language::PortugueseBR | Language::PortuguesePT => "Instalado",
        Language::Spanish => "Instalado",
        Language::French => "Installé",
        Language::German => "Installiert",
        Language::ChineseSimplified => "已安装",
        Language::Russian => "Установлено",
    }
}

fn diag_not_found() -> &'static str {
    match get_language() {
        Language::English => "Not found",
        Language::PortugueseBR | Language::PortuguesePT => "Não encontrado",
        Language::Spanish => "No encontrado",
        Language::French => "Non trouvé",
        Language::German => "Nicht gefunden",
        Language::ChineseSimplified => "未找到",
        Language::Russian => "Не найдено",
    }
}

fn diag_found() -> &'static str {
    match get_language() {
        Language::English => "Found",
        Language::PortugueseBR | Language::PortuguesePT => "Encontrado",
        Language::Spanish => "Encontrado",
        Language::French => "Trouvé",
        Language::German => "Gefunden",
        Language::ChineseSimplified => "找到",
        Language::Russian => "Найдено",
    }
}

fn diag_writable() -> &'static str {
    match get_language() {
        Language::English => "Writable",
        Language::PortugueseBR | Language::PortuguesePT => "Gravável",
        Language::Spanish => "Escribible",
        Language::French => "Accessible en écriture",
        Language::German => "Beschreibbar",
        Language::ChineseSimplified => "可写入",
        Language::Russian => "Записываемо",
    }
}

fn diag_no_write() -> &'static str {
    match get_language() {
        Language::English => "No write access",
        Language::PortugueseBR | Language::PortuguesePT => "Sem acesso de escrita",
        Language::Spanish => "Sin acceso de escritura",
        Language::French => "Pas d'accès en écriture",
        Language::German => "Kein Schreibzugriff",
        Language::ChineseSimplified => "无写入权限",
        Language::Russian => "Нет доступа на запись",
    }
}

fn diag_running() -> &'static str {
    match get_language() {
        Language::English => "Running",
        Language::PortugueseBR | Language::PortuguesePT => "Rodando",
        Language::Spanish => "Ejecutándose",
        Language::French => "En cours d'exécution",
        Language::German => "Läuft",
        Language::ChineseSimplified => "运行中",
        Language::Russian => "Работает",
    }
}

fn diag_stopped() -> &'static str {
    match get_language() {
        Language::English => "Stopped/Not installed",
        Language::PortugueseBR | Language::PortuguesePT => "Parado/Não instalado",
        Language::Spanish => "Detenido/No instalado",
        Language::French => "Arrêté/Non installé",
        Language::German => "Gestoppt/Nicht installiert",
        Language::ChineseSimplified => "已停止/未安装",
        Language::Russian => "Остановлено/Не установлено",
    }
}

fn diag_ok() -> &'static str {
    match get_language() {
        Language::English => "OK",
        Language::PortugueseBR | Language::PortuguesePT => "OK",
        Language::Spanish => "OK",
        _ => "OK",
    }
}

fn diag_possibly_corrupted() -> &'static str {
    match get_language() {
        Language::English => "Possibly corrupted or incomplete",
        Language::PortugueseBR | Language::PortuguesePT => "Possivelmente corrompido ou incompleto",
        Language::Spanish => "Posiblemente corrupto o incompleto",
        Language::French => "Possiblement corrompu ou incomplet",
        Language::German => "Möglicherweise beschädigt oder unvollständig",
        Language::ChineseSimplified => "可能损坏或不完整",
        Language::Russian => "Возможно повреждено или неполное",
    }
}

fn diag_install_xbox() -> &'static str {
    match get_language() {
        Language::English => "Install Xbox App from Microsoft Store",
        Language::PortugueseBR | Language::PortuguesePT => "Instale o Xbox App da Microsoft Store",
        Language::Spanish => "Instale Xbox App desde Microsoft Store",
        Language::French => "Installez Xbox App depuis Microsoft Store",
        Language::German => "Installieren Sie Xbox App aus dem Microsoft Store",
        Language::ChineseSimplified => "从Microsoft Store安装Xbox App",
        Language::Russian => "Установите Xbox App из Microsoft Store",
    }
}

fn diag_install_minecraft() -> &'static str {
    match get_language() {
        Language::English => "Install Minecraft Trial from Xbox App",
        Language::PortugueseBR | Language::PortuguesePT => "Instale o Minecraft Trial pelo Xbox App",
        Language::Spanish => "Instale Minecraft Trial desde Xbox App",
        Language::French => "Installez Minecraft Trial depuis Xbox App",
        Language::German => "Installieren Sie Minecraft Trial über Xbox App",
        Language::ChineseSimplified => "从Xbox App安装Minecraft试用版",
        Language::Russian => "Установите Minecraft Trial из Xbox App",
    }
}

fn diag_run_admin() -> &'static str {
    match get_language() {
        Language::English => "Run this program as Administrator",
        Language::PortugueseBR | Language::PortuguesePT => "Execute este programa como Administrador",
        Language::Spanish => "Ejecute este programa como Administrador",
        Language::French => "Exécutez ce programme en tant qu'Administrateur",
        Language::German => "Führen Sie dieses Programm als Administrator aus",
        Language::ChineseSimplified => "以管理员身份运行此程序",
        Language::Russian => "Запустите эту программу от имени Администратора",
    }
}

fn diag_restart_gaming() -> &'static str {
    match get_language() {
        Language::English => "Restart Gaming Services or reinstall Xbox App",
        Language::PortugueseBR | Language::PortuguesePT => "Reinicie os Serviços de Jogos ou reinstale o Xbox App",
        Language::Spanish => "Reinicie los Servicios de Juegos o reinstale Xbox App",
        Language::French => "Redémarrez les Services de Jeux ou réinstallez Xbox App",
        Language::German => "Starten Sie Gaming-Dienste neu oder installieren Sie Xbox App neu",
        Language::ChineseSimplified => "重启游戏服务或重新安装Xbox App",
        Language::Russian => "Перезапустите Игровые сервисы или переустановите Xbox App",
    }
}

fn diag_repair_minecraft() -> &'static str {
    match get_language() {
        Language::English => "Repair or reinstall Minecraft from Xbox App",
        Language::PortugueseBR | Language::PortuguesePT => "Repare ou reinstale o Minecraft pelo Xbox App",
        Language::Spanish => "Repare o reinstale Minecraft desde Xbox App",
        Language::French => "Réparez ou réinstallez Minecraft depuis Xbox App",
        Language::German => "Reparieren oder installieren Sie Minecraft über Xbox App neu",
        Language::ChineseSimplified => "从Xbox App修复或重新安装Minecraft",
        Language::Russian => "Восстановите или переустановите Minecraft из Xbox App",
    }
}

fn diag_all_passed() -> &'static str {
    match get_language() {
        Language::English => "All checks passed! System is ready.",
        Language::PortugueseBR | Language::PortuguesePT => "Todas as verificações passaram! Sistema pronto.",
        Language::Spanish => "¡Todas las verificaciones pasaron! Sistema listo.",
        Language::French => "Toutes les vérifications passées! Système prêt.",
        Language::German => "Alle Prüfungen bestanden! System bereit.",
        Language::ChineseSimplified => "所有检查通过！系统就绪。",
        Language::Russian => "Все проверки пройдены! Система готова.",
    }
}

fn diag_issues_found() -> &'static str {
    match get_language() {
        Language::English => "issues found:",
        Language::PortugueseBR | Language::PortuguesePT => "problemas encontrados:",
        Language::Spanish => "problemas encontrados:",
        Language::French => "problèmes trouvés:",
        Language::German => "Probleme gefunden:",
        Language::ChineseSimplified => "发现问题:",
        Language::Russian => "обнаружено проблем:",
    }
}
