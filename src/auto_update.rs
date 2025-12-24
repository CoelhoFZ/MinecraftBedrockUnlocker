// Auto-Update Module - Checks for and downloads new versions from GitHub
// Uses GitHub API to check latest release

use colored::*;
use std::process::Command;
use crate::i18n::{get_language, Language};

const GITHUB_REPO: &str = "CoelhoFZ/MinecraftBedrockUnlocker";
const GITHUB_API_URL: &str = "https://api.github.com/repos/CoelhoFZ/MinecraftBedrockUnlocker/releases/latest";

pub struct AutoUpdater {
    current_version: String,
}

#[derive(Debug, Clone)]
pub struct UpdateInfo {
    pub version: String,
    pub download_url: String,
    pub changelog: String,
    pub is_newer: bool,
}

impl AutoUpdater {
    pub fn new() -> Self {
        Self {
            current_version: env!("CARGO_PKG_VERSION").to_string(),
        }
    }

    /// Check if there's a new version available
    pub fn check_for_updates(&self) -> Option<UpdateInfo> {
        // Use PowerShell to fetch GitHub API (avoids adding HTTP dependencies)
        let script = format!(
            r#"
            try {{
                [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
                $response = Invoke-RestMethod -Uri '{}' -Headers @{{'User-Agent'='MinecraftUnlocker'}} -TimeoutSec 10
                $version = $response.tag_name -replace '^v', ''
                $url = ($response.assets | Where-Object {{ $_.name -like '*.exe' }} | Select-Object -First 1).browser_download_url
                $body = $response.body
                Write-Output "$version|$url|$body"
            }} catch {{
                Write-Output "error"
            }}
            "#,
            GITHUB_API_URL
        );

        let output = Command::new("powershell")
            .args(["-NoProfile", "-ExecutionPolicy", "Bypass", "-Command", &script])
            .output()
            .ok()?;

        let stdout = String::from_utf8_lossy(&output.stdout);
        let result = stdout.trim();

        if result == "error" || result.is_empty() {
            return None;
        }

        let parts: Vec<&str> = result.splitn(3, '|').collect();
        if parts.len() < 2 {
            return None;
        }

        let latest_version = parts[0].to_string();
        let download_url = parts.get(1).unwrap_or(&"").to_string();
        let changelog = parts.get(2).unwrap_or(&"").to_string();

        let is_newer = Self::compare_versions(&latest_version, &self.current_version);

        Some(UpdateInfo {
            version: latest_version,
            download_url,
            changelog,
            is_newer,
        })
    }

    /// Compare two version strings (returns true if new > current)
    fn compare_versions(new: &str, current: &str) -> bool {
        let parse_version = |v: &str| -> Vec<u32> {
            v.split('.')
                .filter_map(|s| s.parse::<u32>().ok())
                .collect()
        };

        let new_parts = parse_version(new);
        let current_parts = parse_version(current);

        for i in 0..3 {
            let new_num = new_parts.get(i).copied().unwrap_or(0);
            let current_num = current_parts.get(i).copied().unwrap_or(0);

            if new_num > current_num {
                return true;
            } else if new_num < current_num {
                return false;
            }
        }

        false
    }

    /// Download and install the new version
    pub fn download_and_install(&self, update_info: &UpdateInfo) -> Result<(), String> {
        if update_info.download_url.is_empty() {
            return Err(update_no_download_url().to_string());
        }

        println!("                    {} {}", 
            "[UPDATE]".cyan().bold(), 
            update_downloading());

        // Download to temp folder
        let temp_path = std::env::temp_dir().join("MinecraftUnlocker_new.exe");
        let temp_path_str = temp_path.display().to_string();

        let script = format!(
            r#"
            try {{
                [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
                Invoke-WebRequest -Uri '{}' -OutFile '{}' -TimeoutSec 60
                Write-Output "success"
            }} catch {{
                Write-Output "error: $($_.Exception.Message)"
            }}
            "#,
            update_info.download_url,
            temp_path_str
        );

        let output = Command::new("powershell")
            .args(["-NoProfile", "-ExecutionPolicy", "Bypass", "-Command", &script])
            .output()
            .map_err(|e| format!("PowerShell error: {}", e))?;

        let stdout = String::from_utf8_lossy(&output.stdout);
        
        if !stdout.contains("success") {
            return Err(format!("{}: {}", update_download_failed(), stdout.trim()));
        }

        println!("                    {} {}", 
            "[UPDATE]".green().bold(), 
            update_downloaded());

        // Open folder containing the new exe
        let _ = Command::new("explorer")
            .arg("/select,")
            .arg(&temp_path_str)
            .spawn();

        println!("                    {} {}", 
            "[UPDATE]".yellow().bold(), 
            update_manual_replace());

        Ok(())
    }

    /// Open GitHub releases page in browser
    pub fn open_releases_page() {
        let url = format!("https://github.com/{}/releases/latest", GITHUB_REPO);
        let _ = Command::new("cmd")
            .args(["/C", "start", &url])
            .spawn();
    }

    /// Print update status to console
    pub fn print_update_status(&self) {
        print!("                    {} ", "[UPDATE]".cyan().bold());
        println!("{}", update_checking());

        match self.check_for_updates() {
            Some(info) if info.is_newer => {
                println!("                    {} {} {} → {}", 
                    "[UPDATE]".green().bold(),
                    update_available(),
                    self.current_version.yellow(),
                    info.version.green().bold());
            }
            Some(_) => {
                println!("                    {} {}", 
                    "[UPDATE]".green().bold(),
                    update_up_to_date());
            }
            None => {
                println!("                    {} {}", 
                    "[UPDATE]".yellow().bold(),
                    update_check_failed());
            }
        }
    }
}

impl Default for AutoUpdater {
    fn default() -> Self {
        Self::new()
    }
}

// Localized strings
fn update_checking() -> &'static str {
    match get_language() {
        Language::English => "Checking for updates...",
        Language::PortugueseBR | Language::PortuguesePT => "Verificando atualizações...",
        Language::Spanish => "Buscando actualizaciones...",
        Language::French => "Vérification des mises à jour...",
        Language::German => "Suche nach Updates...",
        Language::ChineseSimplified => "检查更新中...",
        Language::Russian => "Проверка обновлений...",
    }
}

fn update_available() -> &'static str {
    match get_language() {
        Language::English => "New version available!",
        Language::PortugueseBR | Language::PortuguesePT => "Nova versão disponível!",
        Language::Spanish => "¡Nueva versión disponible!",
        Language::French => "Nouvelle version disponible!",
        Language::German => "Neue Version verfügbar!",
        Language::ChineseSimplified => "有新版本可用！",
        Language::Russian => "Доступна новая версия!",
    }
}

fn update_up_to_date() -> &'static str {
    match get_language() {
        Language::English => "You have the latest version ✓",
        Language::PortugueseBR | Language::PortuguesePT => "Você tem a versão mais recente ✓",
        Language::Spanish => "Tienes la última versión ✓",
        Language::French => "Vous avez la dernière version ✓",
        Language::German => "Sie haben die neueste Version ✓",
        Language::ChineseSimplified => "您已是最新版本 ✓",
        Language::Russian => "У вас последняя версия ✓",
    }
}

fn update_check_failed() -> &'static str {
    match get_language() {
        Language::English => "Could not check for updates (offline?)",
        Language::PortugueseBR | Language::PortuguesePT => "Não foi possível verificar atualizações (offline?)",
        Language::Spanish => "No se pudo verificar actualizaciones (¿sin conexión?)",
        Language::French => "Impossible de vérifier les mises à jour (hors ligne?)",
        Language::German => "Updates konnten nicht geprüft werden (offline?)",
        Language::ChineseSimplified => "无法检查更新（离线？）",
        Language::Russian => "Не удалось проверить обновления (оффлайн?)",
    }
}

fn update_downloading() -> &'static str {
    match get_language() {
        Language::English => "Downloading new version...",
        Language::PortugueseBR | Language::PortuguesePT => "Baixando nova versão...",
        Language::Spanish => "Descargando nueva versión...",
        Language::French => "Téléchargement de la nouvelle version...",
        Language::German => "Neue Version wird heruntergeladen...",
        Language::ChineseSimplified => "正在下载新版本...",
        Language::Russian => "Загрузка новой версии...",
    }
}

fn update_downloaded() -> &'static str {
    match get_language() {
        Language::English => "Download complete!",
        Language::PortugueseBR | Language::PortuguesePT => "Download concluído!",
        Language::Spanish => "¡Descarga completada!",
        Language::French => "Téléchargement terminé!",
        Language::German => "Download abgeschlossen!",
        Language::ChineseSimplified => "下载完成！",
        Language::Russian => "Загрузка завершена!",
    }
}

fn update_download_failed() -> &'static str {
    match get_language() {
        Language::English => "Download failed",
        Language::PortugueseBR | Language::PortuguesePT => "Download falhou",
        Language::Spanish => "Descarga fallida",
        Language::French => "Échec du téléchargement",
        Language::German => "Download fehlgeschlagen",
        Language::ChineseSimplified => "下载失败",
        Language::Russian => "Ошибка загрузки",
    }
}

fn update_manual_replace() -> &'static str {
    match get_language() {
        Language::English => "Replace the old exe with the new one",
        Language::PortugueseBR | Language::PortuguesePT => "Substitua o exe antigo pelo novo",
        Language::Spanish => "Reemplace el exe antiguo por el nuevo",
        Language::French => "Remplacez l'ancien exe par le nouveau",
        Language::German => "Ersetzen Sie die alte exe durch die neue",
        Language::ChineseSimplified => "用新文件替换旧的exe",
        Language::Russian => "Замените старый exe на новый",
    }
}

fn update_no_download_url() -> &'static str {
    match get_language() {
        Language::English => "No download URL found",
        Language::PortugueseBR | Language::PortuguesePT => "URL de download não encontrada",
        Language::Spanish => "URL de descarga no encontrada",
        Language::French => "URL de téléchargement non trouvée",
        Language::German => "Download-URL nicht gefunden",
        Language::ChineseSimplified => "未找到下载链接",
        Language::Russian => "URL загрузки не найден",
    }
}
