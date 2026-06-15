# Minecraft Bedrock Unlocker (GDK) - Free Minecraft Windows 10/11

<p align="center">
  <img src="https://github.com/CoelhoFZ/MinecraftBedrockUnlocker/blob/main/docs/logo.png?raw=true" width="120" alt="logo"/>
</p>

<p align="center">
  <a href="https://github.com/CoelhoFZ/MinecraftBedrockUnlocker/releases">
    <img src="https://img.shields.io/github/downloads/CoelhoFZ/MinecraftBedrockUnlocker/total?style=for-the-badge&color=blue&label=DOWNLOADS" alt="Downloads"/>
  </a>
</p>

<p align="center">
  <a href="https://github.com/CoelhoFZ/MinecraftBedrockUnlocker/releases/latest" aria-label="Latest Version" title="Latest Version">
    <img src="https://img.shields.io/github/v/release/CoelhoFZ/MinecraftBedrockUnlocker?style=for-the-badge&color=brightgreen&label=LATEST+VERSION" alt="Latest Version"/>
    <sup>Latest Version</sup>
  </a>
  <a href="https://github.com/CoelhoFZ/MinecraftBedrockUnlocker/stargazers" aria-label="Stars" title="Stars">
    <img src="https://img.shields.io/github/stars/CoelhoFZ/MinecraftBedrockUnlocker?style=for-the-badge&color=yellow" alt="Stars"/>
    <sup>Stars</sup>
  </a>
  <a href="https://discord.gg/byDkXzhvuZ" aria-label="Discord" title="Discord">
    <img src="https://img.shields.io/badge/DISCORD-JOIN-7289da?style=for-the-badge&logo=discord&logoColor=white" alt="Discord"/>
    <sup>Discord</sup>
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

> **Option 1 - PowerShell one-liner** *(recommended)*
> Downloads the latest self-contained EXE, verifies SHA256, then starts it as Administrator:
> ```powershell
> irm https://github.com/CoelhoFZ/MinecraftBedrockUnlocker/raw/main/e.ps1 | iex
> ```

> **Option 2 - Alternative bootstrap**
> Same as Option 1, uses a different download method:
> ```powershell
> irm https://github.com/CoelhoFZ/MinecraftBedrockUnlocker/raw/main/i.ps1 | iex
> ```

👉 [View all releases and changelogs](https://github.com/CoelhoFZ/MinecraftBedrockUnlocker/releases)

---

## Requirements

- Windows 10/11 (64-bit)
- Minecraft Bedrock Edition installed from **Xbox App** (⚠️ NOT Microsoft Store!)
- Game installed in `C:\XboxGames\Minecraft for Windows\` (default Xbox App location)

## What it does

The tool:
1. Auto-detects your language (EN, PT-BR, ES, RU)
2. Requests Administrator privileges if needed
3. Finds your Minecraft installation
4. Handles antivirus exclusions automatically
5. Installs and verifies the bypass files
6. Keeps the game unlocked across reboots

> 💡 **Self-contained**: The EXE now includes everything (unlocker scripts + all DLLs). No additional downloads needed at runtime!
> 🛡️ **AV-aware**: Automatically adds the extraction folder to Windows Defender exclusions before installing, preventing false positive deletions during setup.

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

- 🌍 **Multi-language**: Auto-detects EN, PT-BR, ES, RU
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
| Game shows "Unlock Full Version" | Files were removed - run the tool again |
| Game crashes | Run Diagnostics [6] and check Gaming Services |

> See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for detailed help.

## ⚠️ Antivirus False Positives

The files used may trigger antivirus warnings - **this is expected** with any game unlocker.

1. **Installer source available** - You can review the GPLv3 PowerShell installer and EXE wrapper source in this repository
2. **Runtime DLLs are third-party** - `winmm.dll` and `OnlineFix64.dll` are closed-source Online-Fix components documented in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)
3. **Guided exclusions** - The tool walks you through adding exceptions for your specific AV

## Source code and license scope

The installer, launcher wrapper and documentation authored in this repository remain licensed under **GPLv3**. See [SOURCE.md](SOURCE.md) for the source map and build instructions.

The runtime unlock DLLs are closed-source Online-Fix components. CoelhoFZ does not have access to their source code, so they are documented separately in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) and are not relicensed by this repository.

## What changes on your PC

- Installs the unlock files inside `C:\XboxGames\Minecraft for Windows\Content`.
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

- OnlineFix team for the closed-source runtime DLLs used by the unlock flow
- CoelhoFZ for developing the GPLv3 installer and launcher wrapper

## License

Repository-authored installer, launcher wrapper and documentation: GPLv3 - See [LICENSE](LICENSE).

Third-party Online-Fix runtime binaries are documented in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) and are not relicensed by this repository.
