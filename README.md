# Minecraft Bedrock Unlocker

> 🌍 **[Português (Brasil)](README_PT-BR.md)** | **English**

A CLI tool developed in Rust to manage the licensing DLL for Minecraft Bedrock Edition on Windows.
Unlocks Minecraft by replacing the System32 licensing DLL with a modified version.

> ⚠️ **Educational purposes only** - May violate Microsoft's Terms of Service.craft Unlocker

A CLI tool developed in Rust to manage the licensing DLL for Minecraft Bedrock Edition on Windows.
Unlocks Minecraft by replacing the System32 licensing DLL with a modified version.

> ⚠️ **Educational purposes only** - May violate Microsoft's Terms of Service.

## Installation

Download the latest `mc_unlocker.exe` from [Releases](https://github.com/CoelhoFZ/MinecraftBedrockUnlocker/releases).

**Run as Administrator:**
```cmd
# Right-click mc_unlocker.exe → "Run as administrator"
# Or from terminal:
mc_unlocker.exe
```

## Features

- 🚀 **Native executable** - No .NET Runtime required (~800 KB)
- 🌍 **Multi-language** - Auto-detects 8 languages (EN, PT-BR, PT-PT, ES, FR, DE, ZH-CN, RU)
- 🔒 **Memory-safe** - Built with Rust
- 🔄 **Reversible** - Restore original DLL anytime
- 🔐 **Smart process management** - Auto-closes blocking processes

## Usage

Interactive menu with options:
```
[1] Install Modified DLL (Unlock Minecraft)
[2] Restore Original DLL
[3] Open Minecraft
[4] Open Microsoft Store
[5] Check Status
[0] Exit
```

**Command line mode:**
```cmd
mc_unlocker.exe instalar-mod        # Install modified DLL
mc_unlocker.exe restaurar-original  # Restore original
mc_unlocker.exe status              # Check current state
```

## Project Structure

```
src/
├── main.rs          # Entry point + interactive menu
├── dll_manager.rs   # Core DLL management
├── minecraft.rs     # Minecraft detection/launching
├── process_utils.rs # Windows process handling
└── i18n.rs          # Multi-language support
```

**Technologies:** Rust 2021 | Windows API | SHA256 verification

## Building from Source

```bash
# Install Rust
winget install Rustlang.Rustup

# Clone and build
git clone https://github.com/CoelhoFZ/MinecraftBedrockUnlocker.git
cd MinecraftBedrockUnlocker
cargo build --release

# Output: target/release/mc_unlocker.exe
```

## Contributing & License

Contributions welcome! Report bugs, suggest features, or add language translations.

**License:** MIT - See [LICENSE](LICENSE) file.

**Author:** [CoelhoFZ](https://www.youtube.com/@CoelhoFZ) | 2025
