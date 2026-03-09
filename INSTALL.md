# 📦 Installation Guide - Minecraft Bedrock Unlocker

> Complete step-by-step installation guide for Windows

## 🎯 Quick Install

### Step 1: Install Minecraft Trial

1. Open the **Xbox App** (NOT Microsoft Store!)
2. Search for "Minecraft for Windows"
3. Install the **Trial version** (free)
4. Make sure it installs to `C:\XboxGames\` (default)

> ⚠️ **IMPORTANT**: Must be installed from Xbox App, NOT Microsoft Store!

### Step 2: Run the Unlocker

Open **PowerShell as Administrator** and paste:

```powershell
irm https://raw.githubusercontent.com/CoelhoFZ/MinecraftBedrockUnlocker/main/install.ps1 | iex
```

### Step 3: Choose Option [1]

The script will show an interactive menu. Select **[1] Install Mod**.

### Step 4: Play!

Open Minecraft from the Start Menu or use option **[3]** in the script.

---

## 🔧 How to Open PowerShell as Administrator

### Method 1 (Easiest):
1. Press **Win + X**
2. Click **Terminal (Admin)** or **PowerShell (Admin)**

### Method 2:
1. Press **Win** key
2. Type **PowerShell**
3. Right-click → **Run as administrator**

### Method 3:
1. Press **Win + R**
2. Type `powershell`
3. Press **Ctrl + Shift + Enter** (runs as admin)

---

## 🌍 Language Support

The script automatically detects your Windows language:

| Language | Auto-Detect |
|----------|-------------|
| 🇺🇸 English | ✅ |
| 🇧🇷 Português (Brasil) | ✅ |
| 🇪🇸 Español | ✅ |

---

## 🔄 Alternative Installation (if blocked by ISP/DNS)

If the main command doesn't work:

```powershell
iex (curl.exe -s https://raw.githubusercontent.com/CoelhoFZ/MinecraftBedrockUnlocker/main/install.ps1 | Out-String)
```

---

## ❓ Troubleshooting

### "Running scripts is disabled on this system"

Run this first:
```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
```
Then try the install command again.

### "Access Denied" error

Make sure you're running PowerShell as **Administrator** (see above).

### Antivirus blocks the files

The script adds Windows Defender exclusions automatically. If you have a third-party antivirus:

1. Temporarily disable real-time protection
2. Run the script
3. Add exception for `C:\XboxGames\Minecraft for Windows\Content`
4. Re-enable antivirus

### "Minecraft not found"

The game must be installed via **Xbox App** in `C:\XboxGames\`:

1. Open Xbox App
2. Search "Minecraft for Windows"
3. Install the Trial version
4. Run the script again

---

## 📋 System Requirements

- **OS:** Windows 10/11 (64-bit)
- **PowerShell:** 5.1+ (pre-installed on Windows 10/11)
- **Internet:** Required (to download DLL files from GitHub)
- **Permissions:** Administrator rights
- **Disk:** ~15 MB free space in Minecraft folder

---

## 🔄 Uninstall / Restore Original

To remove the bypass and restore the game to Trial mode:

1. Run the script again
2. Choose option **[2] Restore Original**
3. Done! Game is back to normal

---

## ⚠️ Important Notes

1. **Educational purposes only**
   - This tool is for learning and research
   - Consider purchasing a legitimate license

2. **No warranty**
   - Use at your own risk

3. **Xbox App required**
   - Microsoft Store installations are NOT compatible

---

## 🆘 Need Help?

- **Discord:** https://discord.gg/bfFdyJ3gEj
- **Issues:** [Report a bug](https://github.com/CoelhoFZ/MinecraftBedrockUnlocker/issues)

---

Made with ❤️ by [CoelhoFZ](https://github.com/CoelhoFZ) | [Back to README](README.md)
