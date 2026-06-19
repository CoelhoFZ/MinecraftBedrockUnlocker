# Minecraft Bedrock Unlocker (GDK) - Free Minecraft Windows 10/11

<p align="center">
  <img src="https://github.com/CoelhoFZ/MinecraftBedrockUnlocker/blob/main/docs/logo.png?raw=true" width="120" alt="logo"/>
</p>

<p align="center">
  <a href="https://github.com/CoelhoFZ/MinecraftBedrockUnlocker/releases">
    <img src="https://img.shields.io/endpoint?url=https%3A%2F%2Fminecraft-bedrock-badge.xgobg2020.workers.dev%2Fdownloads.json&style=for-the-badge&logo=github" alt="Downloads"/>
  </a>
  <a href="https://github.com/CoelhoFZ/MinecraftBedrockUnlocker/releases/latest" aria-label="Latest Version" title="Latest Version">
    <img src="https://img.shields.io/badge/LATEST-VERSION-brightgreen?style=for-the-badge" alt="Latest Version"/>
  </a>
</p>

<p align="center">
  <a href="https://buymeacoffee.com/coelhofz" target="_blank">
    <img src="https://www.buymeacoffee.com/assets/img/custom_images/orange_img.png" alt="Buy Me A Coffee" style="height: 41px !important;width: 174px !important;box-shadow: 0px 3px 2px 0px rgba(190, 190, 190, 0.5) !important;-webkit-box-shadow: 0px 3px 2px 0px rgba(190, 190, 190, 0.5) !important;" />
  </a>
  <a href="https://discord.gg/byDkXzhvuZ" aria-label="Discord" title="Discord">
    <img src="https://img.shields.io/badge/DISCORD-JOIN-7289da?style=for-the-badge&logo=discord&logoColor=white" alt="Discord"/>
  </a>
</p>

> **🔓 Unlock Minecraft Bedrock Edition for FREE on Windows 10/11!**

A tool to unlock the full version of **Minecraft Bedrock Edition (GDK)**. **Only works with Xbox App installations** (NOT Microsoft Store!). **No EXE — runs entirely in PowerShell.** No SmartScreen blocks, no browser download warnings.

> ⚠️ **Disclaimer**: This project is for educational purposes only. Please support the developers by purchasing the game.

---

## ⬇️ How to Install

> ⚠️ **DO NOT download the `.exe` file.** Browsers (Chrome, Edge, Firefox) block it with "dangerous file" warnings and Windows SmartScreen flags it. Use the methods below instead — they always work.

### ⚡ Method 1 — PowerShell One-Liner (Recommended)

Open **PowerShell** (search for it in the Start Menu) and paste:

```powershell
irm https://github.com/CoelhoFZ/MinecraftBedrockUnlocker/raw/main/e.ps1 | iex
```

Downloads and runs the latest installer from GitHub. Always up-to-date, with retry, cache-bust, and TLS 1.2. **Runs in memory — SmartScreen will NOT block it.**

> 💡 **Why not the EXE?** Windows SmartScreen blocks unsigned `.exe` files downloaded from the internet. The PowerShell command avoids this entirely — no warnings, no blocks.

### 🖱️ Method 2 — Double-Click (install.bat)

Download **[install.bat](https://github.com/CoelhoFZ/MinecraftBedrockUnlocker/releases/latest/download/install.bat)** and double-click it. It opens PowerShell automatically and runs the installer.

<p align="center">
  <a href="https://github.com/CoelhoFZ/MinecraftBedrockUnlocker/releases/latest/download/install.bat">
    <img src="https://img.shields.io/badge/Download-install.bat-blue?style=for-the-badge&logo=windowsterminal" alt="Download install.bat"/>
  </a>
</p>

👉 [View all releases and changelogs](https://github.com/CoelhoFZ/MinecraftBedrockUnlocker/releases)

---

## Requirements

- Windows 10/11 (64-bit)
- Minecraft Bedrock Edition installed from **Xbox App** (⚠️ NOT Microsoft Store!)
- Game installed in `C:\XboxGames\Minecraft for Windows\` (default Xbox App location)

## What it does

The tool:
1. Auto-detects your language from the OS culture (top 7 worldwide, hand-translated): English, 中文, हिन्दी, Español, Français, العربية, Русский
2. Requests Administrator privileges if needed
3. Finds your Minecraft installation
4. Guides antivirus exclusion setup when needed
5. Installs and verifies the mod files
6. Keeps the game unlocked across reboots

> 🛡️ **AV-aware**: Helps reduce false positive deletions during setup and points you to the relevant AV exclusion steps when needed.
> ⚡ **No EXE**: Runs entirely in PowerShell — no SmartScreen blocks, no browser download warnings.

## Interactive Menu

```
  ============================================================
   __  __ _                            __ _   
  |  \/  (_)_ __   ___  ___ _ __ __ _ / _| |_ 
  | |\/| | | '_ \ / _ \/ __| '__/ _' | |_| __|
  | |  | | | | | |  __/ (__| | | (_| |  _| |_ 
  |_|  |_|_|_| |_|\___|\___|\_  \__,_|_|  \__|
     ____           _                 _        
    | __ )  ___  __| |_ __ ___   ___| | __    
    |  _ \ / _ \/ _' | '__/ _ \ / __| |/ /    
    | |_) |  __/ (_| | | | (_) | (__|   <     
    |____/ \___|\__,_|_|  \___/ \___|_|\_\    
                     Unlocker by CoelhoFZ      
  ============================================================

[1] Install Mod (Unlock Game)
[2] Restore Original (Back to Trial)
[3] Open Minecraft
[4] Install Minecraft (Xbox App)
[5] Check Status
[6] System Diagnostics
[0] Exit
```

## Features

- 🌍 **Multi7 (top worldwide)**: Auto-detects English, 中文 (Chinese), हिन्दी (Hindi), Español (Spanish), Français (French), العربية (Arabic), Русский (Russian) based on the OS culture (`Get-Culture`); never IP geolocation
- 🛡️ **AV guidance**: Guides you through antivirus exclusions to reduce false positives during setup
- 🔄 **Auto-retry**: If antivirus removes files, retries installation
- 📊 **Diagnostics**: Full system health check
- 🔧 **Auto-repair**: Fixes missing files when opening Minecraft
- ✅ **Integrity verification**: Hash checking after install
- 💾 **Reboot persistence**: Survives system restarts

## Troubleshooting

> 📖 **Full guide**: [TROUBLESHOOTING.md](TROUBLESHOOTING.md) — covers BOM/UTF-8 errors, SmartScreen, antivirus (Defender, Kaspersky, Avast, Bitdefender), crashes, access denied, CMD vs PowerShell, and more. Bilingual (English & Portuguese).

### Quick Summary

| Issue | Solution |
|-------|----------|
| Game shows "Unlock Full Version" | Antivirus deleted the files — run the bootstrap again |
| "Minecraft not found" | Install via **Xbox App** (NOT Microsoft Store) to `C:\XboxGames` |
| SmartScreen / "reputação binária mal-intencionada" | No longer an issue — the installer is now 100% PowerShell (no EXE) |
| `'ï»¿$ErrorActionPreference' is not recognized` | Update to v3.2.1+: run `irm ...raw/main/e.ps1 | iex` |
| Game crashes on startup | Run Diagnostics [6] and check Gaming Services |
| "Running scripts is disabled" | `Set-ExecutionPolicy Bypass -Scope Process -Force` |
| "Access Denied" | Open PowerShell as **Administrator** (Win + X → Terminal Admin) |

---

## ⚠️ Antivirus False Positives

Some files used by the setup may trigger antivirus warnings — **this can happen with game mod installers and related runtime components**.

1. **Installer source available** — You can review the GPLv3 PowerShell installer source in this repository
2. **Third-party component notices** — Runtime component details are documented in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)
3. **Guided exclusions** — Setup and troubleshooting steps are documented in [INSTALL.md](INSTALL.md) and [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

## Source code and license scope

The installer and documentation authored in this repository remain licensed under **GPLv3**. See [SOURCE.md](SOURCE.md) for the source map and build instructions.

Third-party runtime components are documented separately in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) and are not relicensed by this repository.

## What changes on your PC

- Installs the mod files inside `C:\XboxGames\Minecraft for Windows\Content`.
- Adds scoped antivirus exclusions for the Minecraft content folder and installed files.
- Creates the scheduled task `MCContentBridge` and backup folder `%LOCALAPPDATA%\MCBridge` so the files can be restored after reboot.
- Option `[2] Restore Original` removes the installed files, scheduled task and backup folder.

## Compatibility

**Supported:**
- ✅ Minecraft Bedrock Edition 1.21.120+ (GDK)
- ✅ Windows 10 (64-bit)
- ✅ Windows 11 (64-bit)
- ✅ Xbox App installations ONLY

**Not Supported:**
- ❌ Microsoft Store installations
- ❌ Xbox Console, Mobile, PlayStation, Nintendo Switch, macOS/Linux

## Community

Join our Discord: https://discord.gg/byDkXzhvuZ

## Credits

- CoelhoFZ for developing the GPLv3 installer

## License

Repository-authored installer and documentation: GPLv3 — See [LICENSE](LICENSE).

Third-party Online-Fix runtime binaries are documented in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) and are not relicensed by this repository.
