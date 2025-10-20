# 📦 Installation Guide - Minecraft Bedrock Unlocker

> Complete step-by-step installation guide for Windows

## 🎯 Quick Install (Recommended)

### For Regular Users

1. **Download the latest release**
   - Go to [Releases](https://github.com/DuarteFZ/MinecraftBedrockUnlocker/releases)
   - Download `mc_unlocker.exe` (latest version)
   - File size: ~5.3 MB

2. **Run as Administrator**
   ```
   Right-click on mc_unlocker.exe
   → Select "Run as administrator"
   ```

3. **Choose your option**
   - The program will auto-detect your language
   - Select option `[1]` to unlock Minecraft
   - Follow the on-screen instructions

4. **Done!** 🎉
   - Open Minecraft from the menu or Microsoft Store
   - Enjoy!

---

## 🛠️ Advanced Installation (Developers)

### Prerequisites

- **Windows 10/11** (64-bit)
- **Rust toolchain** (if compiling from source)
- **Git** (for cloning repository)

### Compile from Source

```bash
# 1. Install Rust
winget install Rustlang.Rustup

# 2. Clone repository
git clone https://github.com/DuarteFZ/MinecraftBedrockUnlocker.git
cd MinecraftBedrockUnlocker

# 3. Build release version
cargo build --release

# 4. Executable location
# Output: target/release/mc_unlocker.exe
```

### Using Python Build Script

```bash
# Alternative build method
python build.py
```

---

## 🌍 Language Support

The program automatically detects your Windows language:

| Language | Auto-Detect |
|----------|-------------|
| 🇺🇸 English | ✅ |
| 🇧🇷 Português (Brasil) | ✅ |
| 🇵🇹 Português (Portugal) | ✅ |
| 🇪🇸 Español | ✅ |
| 🇫🇷 Français | ✅ |
| 🇩🇪 Deutsch | ✅ |
| 🇨🇳 中文 (简体) | ✅ |
| 🇷🇺 Русский | ✅ |

---

## ❓ Troubleshooting

### "Windows protected your PC" warning

This is normal for unsigned executables:

1. Click **"More info"**
2. Click **"Run anyway"**

### Antivirus blocking the file

The tool modifies System32, which triggers false positives:

1. Add exception in your antivirus
2. Or temporarily disable real-time protection

### "Access Denied" error

You must run as Administrator:

1. Right-click → "Run as administrator"
2. Or open Command Prompt as admin first

### Minecraft Store is blocking

If Microsoft Store won't close:

1. Open Task Manager (Ctrl+Shift+Esc)
2. Find "Microsoft Store" process
3. End task manually
4. Try again

---

## 🔄 Restore Original DLL

To revert changes and restore original DLL:

1. Run `mc_unlocker.exe` as Administrator
2. Choose option `[2]` - Restore Original DLL
3. Confirm the operation
4. Done! Original state restored

---

## 📋 System Requirements

- **OS:** Windows 10/11 (64-bit)
- **RAM:** 100 MB free
- **Disk:** 10 MB free space
- **Permissions:** Administrator rights
- **Dependencies:** None (self-contained)

---

## ⚠️ Important Notes

1. **Backup recommended**
   - The program creates automatic backups
   - Original DLL is embedded in the executable

2. **Educational purposes only**
   - This tool is for learning and research
   - May violate Microsoft's Terms of Service
   - Consider purchasing a legitimate license

3. **No warranty**
   - Use at your own risk
   - We're not responsible for system instability
   - Always have a Windows restore point

---

## 🆘 Need Help?

- **Issues:** [Report a bug](https://github.com/DuarteFZ/MinecraftBedrockUnlocker/issues)
- **Discussions:** [Ask questions](https://github.com/DuarteFZ/MinecraftBedrockUnlocker/discussions)
- **YouTube:** [@CoelhoFZ](https://www.youtube.com/@CoelhoFZ)

---

## 📝 Command Line Usage

For automation or advanced users:

```bash
# Install modified DLL (unlock)
mc_unlocker.exe instalar-mod

# Restore original DLL
mc_unlocker.exe restaurar-original

# Check current status
mc_unlocker.exe status

# Open Minecraft
mc_unlocker.exe abrir-minecraft

# Open Microsoft Store
mc_unlocker.exe abrir-store
```

---

Made with ❤️ by [CoelhoFZ](https://github.com/DuarteFZ) | [Back to README](README.md)
