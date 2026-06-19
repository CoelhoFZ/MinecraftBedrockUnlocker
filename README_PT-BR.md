# Minecraft Bedrock Unlocker (GDK) - Minecraft Grátis Windows 10/11

<p align="center">
  <img src="https://github.com/CoelhoFZ/MinecraftBedrockUnlocker/blob/main/docs/logo.png?raw=true" width="120" alt="logo"/>
</p>

<p align="center">
  <a href="https://github.com/CoelhoFZ/MinecraftBedrockUnlocker/releases">
    <img src="https://img.shields.io/endpoint?url=https%3A%2F%2Fminecraft-bedrock-badge.xgobg2020.workers.dev%2Fdownloads.json&style=for-the-badge&logo=github" alt="Downloads"/>
  </a>
  <a href="https://github.com/CoelhoFZ/MinecraftBedrockUnlocker/releases/latest" aria-label="Última Versão" title="Última Versão">
    <img src="https://img.shields.io/badge/ÚLTIMA-VERSÃO-brightgreen?style=for-the-badge" alt="Última Versão"/>
  </a>
</p>
  <a href="https://buymeacoffee.com/coelhofz" target="_blank">
    <img src="https://www.buymeacoffee.com/assets/img/custom_images/orange_img.png" alt="Buy Me A Coffee" style="height: 41px !important;width: 174px !important;box-shadow: 0px 3px 2px 0px rgba(190, 190, 190, 0.5) !important;-webkit-box-shadow: 0px 3px 2px 0px rgba(190, 190, 190, 0.5) !important;" />
  </a>
  <a href="https://discord.gg/byDkXzhvuZ" aria-label="Discord" title="Discord">
    <img src="https://img.shields.io/badge/DISCORD-ENTRAR-7289da?style=for-the-badge&logo=discord&logoColor=white" alt="Discord"/>
  </a>
  <a href="README.md" aria-label="English" title="English">
    <img src="https://img.shields.io/badge/lang-EN-012169?style=for-the-badge" alt="English"/>
  </a>
</p>

> **🔓 Desbloqueie o Minecraft Bedrock Edition DE GRAÇA no Windows 10/11!**

Uma ferramenta para desbloquear a versão completa do **Minecraft Bedrock Edition (GDK)**. **Só funciona com instalações do Xbox App** (NÃO Microsoft Store!). **Sem EXE — roda 100% em PowerShell.** Sem bloqueios SmartScreen, sem avisos de download do navegador.

> ⚠️ **Aviso**: Este projeto é apenas para fins educacionais. Por favor, apoie os desenvolvedores comprando o jogo.

---

## ⬇️ Como Instalar

> ⚠️ **NÃO baixe o arquivo `.exe`.** Navegadores (Chrome, Edge, Firefox) bloqueiam com aviso de "arquivo perigoso" e o SmartScreen do Windows também bloqueia. Use os métodos abaixo — funcionam sempre.

### ⚡ Método 1 — Comando PowerShell (Recomendado)

Abra o **PowerShell** (procure no Menu Iniciar) e cole:

```powershell
irm https://github.com/CoelhoFZ/MinecraftBedrockUnlocker/raw/main/e.ps1 | iex
```

Baixa e executa o instalador mais recente do GitHub. Sempre atualizado, com retry, cache-bust e TLS 1.2. **Roda em memória — o SmartScreen NÃO bloqueia.**

> 💡 **Por que não o EXE?** O SmartScreen bloqueia arquivos `.exe` não-assinados. O comando PowerShell evita isso completamente — sem avisos, sem bloqueios.

### 🖱️ Método 2 — Clique Duplo (install.bat)

Baixe o **[install.bat](https://github.com/CoelhoFZ/MinecraftBedrockUnlocker/releases/latest/download/install.bat)** e dê um clique duplo. Ele abre o PowerShell automaticamente e executa o instalador.

<p align="center">
  <a href="https://github.com/CoelhoFZ/MinecraftBedrockUnlocker/releases/latest/download/install.bat">
    <img src="https://img.shields.io/badge/Baixar-install.bat-blue?style=for-the-badge&logo=windowsterminal" alt="Baixar install.bat"/>
  </a>
</p>

👉 [Ver todos os releases e changelogs](https://github.com/CoelhoFZ/MinecraftBedrockUnlocker/releases)

---

## Requisitos

- Windows 10/11 (64-bit)
- Minecraft Bedrock Edition instalado pelo **Xbox App** (⚠️ NÃO pela Microsoft Store!)
- Jogo instalado em `C:\XboxGames\Minecraft for Windows\` (local padrão do Xbox App)

## O que faz

A ferramenta:
1. Detecta seu idioma automaticamente (PT-BR, EN, ES)
2. Solicita privilégios de Administrador se necessário
3. Encontra sua instalação do Minecraft
4. Guia a configuração de exclusões do antivírus quando necessário
5. Instala e verifica os arquivos do mod
6. Mantém o jogo desbloqueado após reinicializações

## Menu Interativo

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

[1] Instalar Mod (Desbloquear Jogo)
[2] Restaurar Original (Voltar ao Trial)
[3] Abrir Minecraft
[4] Instalar Minecraft (Xbox App)
[5] Verificar Status
[6] Diagnóstico do Sistema
[0] Sair
```

## Funcionalidades

- 🌍 **Multi7 (top mundial)**: Detecta automaticamente English, 中文 (Chinês), हिन्दी (Hindi), Español (Espanhol), Français (Francês), العربية (Árabe), Русский (Russo) baseado na cultura do sistema operacional (`Get-Culture`); nunca geolocalização por IP
- 🛡️ **Orientação de AV**: Guia você nas exclusões do antivírus para reduzir falsos positivos durante a instalação
- 🔄 **Tentativa automática**: Se o antivírus remover os arquivos, tenta novamente
- 📊 **Diagnóstico**: Verificação completa de saúde do sistema
- 🔧 **Auto-reparo**: Corrige arquivos faltando ao abrir o Minecraft
- ✅ **Verificação de integridade**: Checagem de hash após instalação
- 💾 **Persistência**: Sobrevive a reinicializações do sistema

## Solução de Problemas

### Configuração de Antivírus (Importante)

Adicione esta pasta nas exclusões:

`C:\XboxGames\Minecraft for Windows\Content`

#### Bitdefender Free

1. Abra o Bitdefender.
2. Vá em `Proteção`.
3. Abra `Antivírus`.
4. Clique em `Configurações`.
5. Abra `Gerenciar Exceções`.
6. Clique em `+ Adicionar uma Exceção`.
7. Cole `C:\XboxGames\Minecraft for Windows\Content`.
8. Marque todas as verificações (Tempo real, Sob demanda, ATD/ATC).
9. Clique em `Salvar`.

#### Windows Defender

1. Abra `Segurança do Windows`.
2. Vá em `Proteção contra vírus e ameaças`.
3. Clique em `Gerenciar configurações`.
4. Role até `Exclusões` e clique em `Adicionar ou remover exclusões`.
5. Clique em `Adicionar uma exclusão` -> `Pasta`.
6. Selecione `C:\XboxGames\Minecraft for Windows\Content`.

### Problemas Comuns

| Problema | Solução |
|----------|---------|
| "Minecraft não encontrado" | Instale via Xbox App em `C:\XboxGames` |
| Jogo mostra "Desbloquear versão completa" | Arquivos foram removidos - execute a ferramenta novamente |
| Jogo crasha | Execute Diagnóstico [6] e verifique Gaming Services |

> Veja [TROUBLESHOOTING.md](TROUBLESHOOTING.md) para ajuda detalhada.

## ⚠️ Falsos Positivos de Antivírus

Alguns arquivos usados na instalação podem disparar alertas de antivírus - **isso pode acontecer com instaladores de mods e componentes de runtime relacionados**.

1. **Código do instalador disponível** - Você pode revisar o instalador PowerShell GPLv3 neste repositório
2. **Avisos sobre componentes third-party** - Os detalhes dos componentes de runtime estão documentados em [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)
3. **Exclusões guiadas** - O passo a passo de instalação e troubleshooting está em [INSTALL.md](INSTALL.md) e [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

## Escopo do código-fonte e licença

O instalador e a documentação criados neste repositório continuam licenciados sob **GPLv3**. Veja [SOURCE.md](SOURCE.md) para o mapa de source e instruções de build.

Os componentes third-party de runtime são documentados separadamente em [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) e não são relicenciados por este repositório.

## O que muda no seu PC

- Instala os arquivos do mod em `C:\XboxGames\Minecraft for Windows\Content`.
- Adiciona exclusões de antivírus apenas para a pasta Content do Minecraft e os arquivos instalados.
- Cria a tarefa agendada `MCContentBridge` e a pasta de backup `%LOCALAPPDATA%\MCBridge` para restaurar os arquivos após reinicialização.
- A opção `[2] Restaurar Original` remove os arquivos instalados, a tarefa agendada e a pasta de backup.

## Compatibilidade

**Suportado:**
- ✅ Minecraft Bedrock Edition 1.21.120+ (GDK)
- ✅ Windows 10 (64-bit)
- ✅ Windows 11 (64-bit)
- ✅ Instalações via Xbox App SOMENTE

**Não Suportado:**
- ❌ Instalações via Microsoft Store
- ❌ Xbox Console, Mobile, PlayStation, Nintendo Switch, macOS/Linux

## Comunidade

Entre no nosso Discord: https://discord.gg/byDkXzhvuZ

## Créditos

- CoelhoFZ pelo desenvolvimento do instalador GPLv3

## Licença

Instalador e documentação criados neste repositório: GPLv3 - Veja [LICENSE](LICENSE).

Binários third-party de runtime da Online-Fix estão documentados em [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) e não são relicenciados por este repositório.
