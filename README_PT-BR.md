# Minecraft Bedrock Unlocker

[![Buy Me A Coffee](https://img.shields.io/badge/Buy%20Me%20A%20Coffee-Apoie-yellow?style=for-the-badge&logo=buy-me-a-coffee)](https://buymeacoffee.com/coelhofz)

> 🌍 **Português (Brasil)** | **[English](README.md)**

Ferramenta CLI desenvolvida em Rust para gerenciar a DLL de licenciamento do Minecraft Bedrock Edition no Windows.
Desbloqueia o Minecraft substituindo a DLL de licenciamento da System32 por uma versão modificada.

> ⚠️ **Apenas para fins educacionais** - Pode violar os Termos de Serviço da Microsoft.

## Instalação

> 📖 **[Guia completo de instalação](INSTALL.md)** | Início rápido abaixo

Baixe o `mc_unlocker.exe` mais recente em [Releases](https://github.com/CoelhoFZ/MinecraftBedrockUnlocker/releases).

**Execute como Administrador:**
```cmd
# Clique com botão direito em mc_unlocker.exe → "Executar como administrador"
# Ou pelo terminal:
mc_unlocker.exe
```

## Recursos

- 🚀 **Executável nativo** - Sem necessidade de .NET Runtime (~800 KB)
- 🌍 **Multi-idioma** - Detecção automática de 8 idiomas (EN, PT-BR, PT-PT, ES, FR, DE, ZH-CN, RU)
- 🔒 **Memory-safe** - Construído com Rust
- 🔄 **Reversível** - Restaure a DLL original a qualquer momento
- 🔐 **Gerenciamento inteligente** - Fecha automaticamente processos que bloqueiam a DLL

## Como Usar

Menu interativo com opções:
```
[1] Instalar DLL Modificada (Desbloquear Minecraft)
[2] Restaurar DLL Original
[3] Abrir Minecraft
[4] Abrir Microsoft Store
[5] Verificar Status
[0] Sair
```

**Modo linha de comando:**
```cmd
mc_unlocker.exe instalar-mod        # Instala DLL modificada
mc_unlocker.exe restaurar-original  # Restaura DLL original
mc_unlocker.exe status              # Verifica estado atual
```

## Estrutura do Projeto

```
src/
├── main.rs          # Ponto de entrada + menu interativo
├── dll_manager.rs   # Gerenciamento de DLL (core)
├── minecraft.rs     # Detecção/abertura do Minecraft
├── process_utils.rs # Manipulação de processos Windows
└── i18n.rs          # Suporte multi-idioma
```

**Tecnologias:** Rust 2021 | Windows API | Verificação SHA256

## Compilar do Código-Fonte

```bash
# Instalar Rust
winget install Rustlang.Rustup

# Clonar e compilar
git clone https://github.com/CoelhoFZ/MinecraftBedrockUnlocker.git
cd MinecraftBedrockUnlocker
cargo build --release

# Saída: target/release/mc_unlocker.exe
```

## ☕ Apoie o Projeto

Se essa ferramenta te ajudou, considere apoiar meu trabalho!

[![Buy Me A Coffee](https://img.shields.io/badge/Buy%20Me%20A%20Coffee-Doar-yellow.svg?style=for-the-badge&logo=buy-me-a-coffee)](https://buymeacoffee.com/coelhofz)

Seu apoio me ajuda a criar mais ferramentas gratuitas e conteúdo! 🚀

## Contribuindo & Licença

Contribuições são bem-vindas! Reporte bugs, sugira recursos ou adicione traduções.

**Licença:** MIT - Veja o arquivo [LICENSE](LICENSE).

**Autor:** [CoelhoFZ](https://www.youtube.com/@CoelhoFZ) | 2025
