# Minecraft Bedrock Unlocker (GDK) - Free Minecraft Windows 10/11

[![GitHub release](https://img.shields.io/github/v/release/CoelhoFZ/MinecraftBedrockUnlocker?style=flat-square&color=brightgreen)](https://github.com/CoelhoFZ/MinecraftBedrockUnlocker/releases)
[![License](https://img.shields.io/github/license/CoelhoFZ/MinecraftBedrockUnlocker?style=flat-square&color=blue)](LICENSE)
[![Stars](https://img.shields.io/github/stars/CoelhoFZ/MinecraftBedrockUnlocker?style=flat-square&color=yellow)](https://github.com/CoelhoFZ/MinecraftBedrockUnlocker/stargazers)
[![Discord](https://img.shields.io/badge/Discord-Join-7289da?style=flat-square&logo=discord&logoColor=white)](https://discord.gg/bfFdyJ3gEj)

> **🔓 Unlock Minecraft Bedrock Edition for FREE on Windows 10/11!**

**Minecraft Bedrock free download** | **Minecraft Windows 10 free** | **Minecraft crack 2024** | **Minecraft unlocker** | **Free Minecraft PC**

A PowerShell tool to unlock the full version of **Minecraft Bedrock Edition (GDK)** using the OnlineFix method. **Only works with Xbox App installations** (NOT Microsoft Store!). No need to buy - play Minecraft for free!

> ⚠️ **Disclaimer**: This project is for educational purposes only. Please support the developers by purchasing the game.

## Requirements

- Windows 10/11
- Minecraft Bedrock Edition (Trial) installed from **Xbox App** (⚠️ NOT Microsoft Store!)
- Game installed in `C:\XboxGames\Minecraft for Windows\` (default Xbox App location)

## Installation

### PowerShell One-Liner (Just copy & paste!)

Open **PowerShell as Administrator** and run:

```powershell
irm https://raw.githubusercontent.com/CoelhoFZ/MinecraftBedrockUnlocker/main/install.ps1 | iex
```

> If blocked by ISP/DNS, try this alternative:
> ```powershell
> iex (curl.exe -s https://raw.githubusercontent.com/CoelhoFZ/MinecraftBedrockUnlocker/main/install.ps1 | Out-String)
> ```

That's it! The script will:
1. Auto-detect your language
2. Request Administrator privileges if needed
3. Find your Minecraft installation
4. Add Windows Defender exclusions automatically
5. Download and install the bypass files
6. Verify the installation

## How It Works

The script uses the OnlineFix method which:
1. Downloads bypass files directly from GitHub to Minecraft's Content folder
2. The `winmm.dll` intercepts XStore API calls
3. Returns "licensed" status before UI loads

## Interactive Menu

```
  ============================================================
   __  __ _                            __ _   
  |  \/  (_)_ __   ___  ___ _ __ __ _ / _| |_ 
  | |\/| | | '_ \ / _ \/ __| '__/ _' | |_| __|
  | |  | | | | | |  __/ (__| | | (_| |  _| |_ 
  |_|  |_|_|_| |_|\___|\___|_|  \__,_|_|  \__|
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
- 🛡️ **Antivirus handling**: Adds Windows Defender exclusions automatically
- 🔄 **Auto-retry**: If antivirus deletes files, retries installation
- 📊 **Diagnostics**: Full system health check
- 🔧 **Auto-repair**: Fixes missing files when opening Minecraft
- ✅ **Integrity verification**: SHA256 hash checking after download
- 📦 **No EXE needed**: Runs 100% in PowerShell - no downloads flagged by antivirus!

## Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| Antivirus blocks files | The script adds exclusions automatically. If still failing, temporarily disable AV |
| "Minecraft not found" | Install via Xbox App to C:\XboxGames |
| Game shows "Unlock Full Version" | Antivirus deleted files - run the script again |
| Game crashes | Run Diagnostics [6] and check Gaming Services |

### Manual Antivirus Exclusion

If the script can't add exclusions automatically:

1. Open **Windows Security**
2. Go to **Virus & threat protection** → **Manage settings**
3. Scroll to **Exclusions** → **Add or remove exclusions**
4. Add folder: `C:\XboxGames\Minecraft for Windows\Content`

> See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for detailed help.

## ⚠️ Antivirus False Positives

The DLL files used may trigger antivirus warnings. **This is expected behavior** - any license bypass tool will trigger heuristic detections.

### What you should know:

1. **Open Source** - You can review 100% of the code in this repository
2. **OnlineFix Method** - The DLLs used are from the trusted OnlineFix team
3. **No EXE** - The PowerShell script downloads DLLs directly from GitHub
4. **No Malware** - This tool does NOT steal data, mine crypto, or harm your PC

## Compatibility

**Supported:**
- ✅ Minecraft Bedrock Edition 1.21.120+ (GDK) - 2024/2025
- ✅ Windows 10 (64-bit)
- ✅ Windows 11 (64-bit)
- ✅ **Xbox App installations ONLY**

**Not Supported:**
- ❌ Microsoft Store installations (game must be in C:\XboxGames)
- ❌ Xbox Console (Xbox One / Series X|S)
- ❌ Mobile (Android / iOS)
- ❌ PlayStation / Nintendo Switch
- ❌ macOS / Linux

## Credits

- OnlineFix team for the bypass method
- CoelhoFZ for developing the tool

## Community

Join our Discord: https://discord.gg/bfFdyJ3gEj

## License

GPLv3 License - See [LICENSE](LICENSE)
