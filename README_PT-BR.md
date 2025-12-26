# Minecraft Bedrock Unlocker (GDK) - Minecraft Grátis Windows 10/11

[![GitHub release](https://img.shields.io/github/v/release/CoelhoFZ/MinecraftBedrockUnlocker?style=flat-square&color=brightgreen)](https://github.com/CoelhoFZ/MinecraftBedrockUnlocker/releases)
[![License](https://img.shields.io/github/license/CoelhoFZ/MinecraftBedrockUnlocker?style=flat-square&color=blue)](LICENSE)
[![Stars](https://img.shields.io/github/stars/CoelhoFZ/MinecraftBedrockUnlocker?style=flat-square&color=yellow)](https://github.com/CoelhoFZ/MinecraftBedrockUnlocker/stargazers)
[![Downloads](https://img.shields.io/github/downloads/CoelhoFZ/MinecraftBedrockUnlocker/total?style=flat-square&color=purple)](https://github.com/CoelhoFZ/MinecraftBedrockUnlocker/releases)
[![Rust](https://img.shields.io/badge/Rust-1.70+-orange?style=flat-square&logo=rust)](https://www.rust-lang.org/)
[![Discord](https://img.shields.io/badge/Discord-Entrar-7289da?style=flat-square&logo=discord&logoColor=white)](https://discord.gg/bfFdyJ3gEj)
[![VirusTotal](https://img.shields.io/badge/VirusTotal-Limpo-success?style=flat-square&logo=virustotal)](https://www.virustotal.com/)

> **🔓 Desbloqueie o Minecraft Bedrock Edition DE GRAÇA no Windows 10/11!**

**Minecraft Bedrock grátis** | **Minecraft Windows 10 grátis** | **Minecraft crack 2024** | **Minecraft desbloqueador** | **Minecraft PC grátis** | **Como baixar Minecraft de graça**

Uma poderosa ferramenta CLI para desbloquear a versão completa do **Minecraft Bedrock Edition (GDK)** usando o método OnlineFix. **Só funciona com instalações do Xbox App** (NÃO Microsoft Store!). Sem precisar comprar - jogue Minecraft de graça!

> ⚠️ **Aviso**: Este projeto é apenas para fins educacionais. Por favor, apoie os desenvolvedores comprando o jogo.

## Requisitos

- Windows 10/11
- Minecraft Bedrock Edition (Trial) instalado pelo **Xbox App** (⚠️ NÃO pela Microsoft Store!)
- Jogo instalado em `C:\XboxGames\Minecraft for Windows\` (local padrão do Xbox App)

## Instalação

### Opção 1: PowerShell One-Liner (Recomendado)

Abra o PowerShell e execute:

```powershell
irm https://raw.githubusercontent.com/CoelhoFZ/MinecraftBedrockUnlocker/main/install.ps1 | iex
```

> Se bloqueado pelo provedor/DNS, tente esta alternativa:
> ```powershell
> iex (curl.exe -s https://raw.githubusercontent.com/CoelhoFZ/MinecraftBedrockUnlocker/main/install.ps1 | Out-String)
> ```

### Opção 2: Baixar o Executável

1. Baixe o executável da [página de Releases](https://github.com/CoelhoFZ/MinecraftBedrockUnlocker/releases)
2. Execute como **Administrador**
3. Escolha **[1] Instalar Mod**
4. Abra o Minecraft pelo Menu Iniciar!

### Opção 3: Compilar do Código Fonte

```bash
# Clonar repositório
git clone https://github.com/CoelhoFZ/MinecraftBedrockUnlocker.git
cd MinecraftBedrockUnlocker

# Compilar
cargo build --release

# Executar como Administrador
.\target\release\mc_unlocker.exe
```

## Como Funciona

O programa usa o método OnlineFix que:
1. Copia arquivos de bypass para a pasta Content do Minecraft
2. O `winmm.dll` intercepta chamadas de API XStore
3. Retorna status "licenciado" antes da UI carregar

## Menu Interativo

```
╔══════════════════════════════════════════════════════════════════════╗
║ ██╗   ██╗███╗   ██╗██╗      ██████╗  ██████╗██╗  ██╗███████╗██████╗  ║
║ ██║   ██║████╗  ██║██║     ██╔═══██╗██╔════╝██║ ██╔╝██╔════╝██╔══██╗ ║
║ ██║   ██║██╔██╗ ██║██║     ██║   ██║██║     █████╔╝ █████╗  ██████╔╝ ║
║ ██║   ██║██║╚██╗██║██║     ██║   ██║██║     ██╔═██╗ ██╔══╝  ██╔══██╗ ║
║ ╚██████╔╝██║ ╚████║███████╗╚██████╔╝╚██████╗██║  ██╗███████╗██║  ██║ ║
║  ╚═════╝ ╚═╝  ╚═══╝╚══════╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝ ║
╚══════════════════════════════════════════════════════════════════════╝

[1] Instalar Mod (Desbloquear jogo)
[2] Restaurar Original (Voltar ao Trial)
[3] Abrir Minecraft
[4] Abrir Xbox App
[5] Verificar Status
[0] Sair
```

## Solução de Problemas

### Aviso do Windows SmartScreen

Ao executar o programa pela primeira vez, o Windows pode mostrar um aviso "O Windows protegeu o computador". Isso é normal para aplicativos não assinados.

**Para continuar:**
1. Clique em **"Mais informações"**
2. Clique em **"Executar assim mesmo"**

### Problemas Comuns

| Problema | Solução |
|----------|---------|
| Antivírus bloqueia | Adicione exceção ou desative temporariamente |
| "Minecraft não encontrado" | Instale via Xbox App em C:\XboxGames |
| Jogo crasha | Verifique se o Minecraft Trial está instalado corretamente |

## ⚠️ Falsos Positivos de Antivírus

Alguns antivírus podem marcar esta ferramenta como maliciosa. **Isso é um falso positivo.**

### Por que isso acontece?

| Tipo de Detecção | Explicação |
|------------------|------------|
| `Generic.Trojan` | Detecção heurística - não é uma assinatura de vírus real |
| `AI.DetectMalware` | Correspondência genérica de padrões por IA |
| `BehavesLike.Win64` | Comportamento similar a ferramentas de hacking (porque É uma ferramenta de bypass!) |
| `HackTool` | Corretamente identificado como "ferramenta de hack" - isso é esperado! |

### O que você deve saber:

1. **Código Aberto** - Você pode revisar 100% do código neste repositório
2. **Método OnlineFix** - As DLLs usadas são da confiável equipe OnlineFix
3. **Comportamento Esperado** - Qualquer ferramenta de injeção de DLL / bypass de licença vai acionar o antivírus
4. **Sem Malware** - Esta ferramenta NÃO rouba dados, minera criptomoedas ou danifica seu PC

### Ações Recomendadas:

- ✅ Adicione uma exceção para `mc_unlocker.exe` no seu antivírus
- ✅ Desative temporariamente a proteção em tempo real durante a instalação
- ✅ Use o Windows Defender ao invés de antivírus de terceiros agressivos
- ❌ NÃO baixe de fontes não oficiais

> 💡 **Dica Pro**: Se você está paranoico, compile você mesmo a partir do código fonte!

## Compatibilidade

**Plataformas Suportadas:**
- ✅ Minecraft Bedrock Edition 1.21.120+ (GDK) - Última versão 2024/2025
- ✅ Windows 10 (64-bit)
- ✅ Windows 11 (64-bit)
- ✅ **Instalações via Xbox App SOMENTE**

**Não Suportado:**
- ❌ **Instalações via Microsoft Store** (o jogo precisa estar em C:\XboxGames)
- ❌ Xbox Console (Xbox One / Series X|S)
- ❌ Mobile (Android / iOS)
- ❌ PlayStation
- ❌ Nintendo Switch
- ❌ macOS / Linux

## Créditos

- Equipe OnlineFix pelo método de bypass
- CoelhoFZ pelo desenvolvimento da ferramenta

## Comunidade

Entre no nosso Discord: https://discord.gg/bfFdyJ3gEj

## Licença

GPLv3 License - Veja [LICENSE](LICENSE)

