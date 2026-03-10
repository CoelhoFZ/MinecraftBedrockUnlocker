# Minecraft Bedrock Unlocker (GDK) - Free Minecraft Windows 10/11

<p align="center">
  <img src="https://github.com/CoelhoFZ/MinecraftBedrockUnlocker/blob/main/docs/logo.png?raw=true" width="120" alt="logo"/>
</p>

<p align="center">
  <a href="https://github.com/CoelhoFZ/MinecraftBedrockUnlocker/releases/latest">
    <img src="https://img.shields.io/github/v/release/CoelhoFZ/MinecraftBedrockUnlocker?style=for-the-badge&color=brightgreen&label=LATEST+VERSION" alt="Latest Version"/>
  </a>
  <a href="https://github.com/CoelhoFZ/MinecraftBedrockUnlocker/stargazers">
    <img src="https://img.shields.io/github/stars/CoelhoFZ/MinecraftBedrockUnlocker?style=for-the-badge&color=yellow" alt="Stars"/>
  </a>
  <a href="https://discord.gg/bfFdyJ3gEj">
    <img src="https://img.shields.io/badge/DISCORD-JOIN-7289da?style=for-the-badge&logo=discord&logoColor=white" alt="Discord"/>
  </a>
  <a href="README_PT-BR.md">
    <img src="https://img.shields.io/badge/lang-PT--BR-009c3b?style=for-the-badge" alt="PT-BR"/>
  </a>
</p>

> **🔓 Unlock Minecraft Bedrock Edition for FREE on Windows 10/11!**

**Minecraft Bedrock free download** | **Minecraft Windows 10 free** | **Minecraft crack 2026** | **Minecraft unlocker** | **Free Minecraft PC**

A tool to unlock the full version of **Minecraft Bedrock Edition (GDK)**. **Only works with Xbox App installations** (NOT Microsoft Store!).

> ⚠️ **Disclaimer**: This project is for educational purposes only. Please support the developers by purchasing the game.

---

## ⬇️ Download

<p align="center">
  <a href="https://github.com/CoelhoFZ/MinecraftBedrockUnlocker/releases/latest/download/MinecraftBedrockUnlocker.exe">
    <img src="https://img.shields.io/badge/Download%20EXE-MinecraftBedrockUnlocker.exe-blue?style=for-the-badge&logo=windows" alt="Download EXE"/>
  </a>
</p>

> **Option 1 — Portable EXE** *(recommended, no setup required)*
> Download and run `MinecraftBedrockUnlocker.exe` as Administrator. No PowerShell, no manual steps.

> **Option 2 — PowerShell one-liner** *(online, no file to download)*
> Open **PowerShell as Administrator** and run:
> ```powershell
> irm https://github.com/CoelhoFZ/MinecraftBedrockUnlocker/releases/latest/download/install.ps1 | iex
> ```

> If blocked by ISP/DNS, try:
> ```powershell
> iex (curl.exe -s https://github.com/CoelhoFZ/MinecraftBedrockUnlocker/releases/latest/download/install.ps1 | Out-String)
> ```

👉 [View all releases and changelogs](https://github.com/CoelhoFZ/MinecraftBedrockUnlocker/releases)

---

## Requirements

- Windows 10/11 (64-bit)
- Minecraft Bedrock Edition installed from **Xbox App** (⚠️ NOT Microsoft Store!)
- Game installed in `C:\XboxGames\Minecraft for Windows\` (default Xbox App location)

## What it does

The tool:
1. Auto-detects your language (EN, PT-BR, ES)
2. Requests Administrator privileges if needed
3. Finds your Minecraft installation
4. Handles antivirus exclusions automatically
5. Installs and verifies the bypass files
6. Keeps the game unlocked across reboots

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

- 🌍 **Multi-language**: Auto-detects EN, PT-BR, ES
- 🛡️ **Antivirus handling**: Adds exclusions automatically for Windows Defender, BD Free, and others
- 🔄 **Auto-retry**: If antivirus removes files, retries installation
- 📊 **Diagnostics**: Full system health check
- 🔧 **Auto-repair**: Fixes missing files when opening Minecraft
- ✅ **Integrity verification**: Hash checking after install
- 💾 **Reboot persistence**: Survives system restarts

## Troubleshooting

### Antivirus Setup (Important)

Add this folder to exclusions:

`C:\XboxGames\Minecraft for Windows\Content`

#### Bitdefender Free

1. Open Bitdefender.
2. Go to `Protection`.
3. Open `Antivirus`.
4. Click `Settings`.
5. Open `Manage Exceptions`.
6. Click `+ Add an Exception`.
7. Paste `C:\XboxGames\Minecraft for Windows\Content`.
8. Enable all scan options (On-access, On-demand, ATD/ATC).
9. Click `Save`.

#### Windows Defender

1. Open `Windows Security`.
2. Go to `Virus & threat protection`.
3. Click `Manage settings`.
4. Scroll to `Exclusions` and click `Add or remove exclusions`.
5. Click `Add an exclusion` -> `Folder`.
6. Select `C:\XboxGames\Minecraft for Windows\Content`.

### Common Issues

| Issue | Solution |
|-------|----------|
| "Minecraft not found" | Install via Xbox App to `C:\XboxGames` |
| Game shows "Unlock Full Version" | Files were removed — run the tool again |
| Game crashes | Run Diagnostics [6] and check Gaming Services |

> See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for detailed help.

## ⚠️ Antivirus False Positives

The files used may trigger antivirus warnings — **this is expected** with any game unlocker.

1. **Source available** — You can review the installer script in this repository
2. **No malware** — This tool does NOT steal data, mine crypto, or harm your PC
3. **Guided exclusions** — The tool walks you through adding exceptions for your specific AV

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

Join our Discord: https://discord.gg/bfFdyJ3gEj

## Credits

- OnlineFix team
- CoelhoFZ for developing the tool

## License

GPLv3 - See [LICENSE](LICENSE)
