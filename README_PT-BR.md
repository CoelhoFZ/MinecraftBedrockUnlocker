# Minecraft Bedrock Unlocker (GDK) - Minecraft Grátis Windows 10/11

<p align="center">
  <img src="https://github.com/CoelhoFZ/MinecraftBedrockUnlocker/blob/main/docs/logo.png?raw=true" width="120" alt="logo"/>
</p>

<p align="center">
  <a href="https://github.com/CoelhoFZ/MinecraftBedrockUnlocker/releases/latest">
    <img src="https://img.shields.io/github/v/release/CoelhoFZ/MinecraftBedrockUnlocker?style=for-the-badge&color=brightgreen&label=ÚLTIMA+VERSÃO" alt="Última Versão"/>
  </a>
  <a href="https://github.com/CoelhoFZ/MinecraftBedrockUnlocker/stargazers">
    <img src="https://img.shields.io/github/stars/CoelhoFZ/MinecraftBedrockUnlocker?style=for-the-badge&color=yellow" alt="Stars"/>
  </a>
  <a href="https://discord.gg/byDkXzhvuZ">
    <img src="https://img.shields.io/badge/DISCORD-ENTRAR-7289da?style=for-the-badge&logo=discord&logoColor=white" alt="Discord"/>
  </a>
  <a href="README.md">
    <img src="https://img.shields.io/badge/lang-EN-012169?style=for-the-badge" alt="English"/>
  </a>
</p>

> **🔓 Desbloqueie o Minecraft Bedrock Edition DE GRAÇA no Windows 10/11!**

**Minecraft Bedrock grátis** | **Minecraft Windows 10 grátis** | **Minecraft crack 2026** | **Minecraft desbloqueador** | **Minecraft PC grátis** | **Como baixar Minecraft de graça**

Uma ferramenta para desbloquear a versão completa do **Minecraft Bedrock Edition (GDK)**. **Só funciona com instalações do Xbox App** (NÃO Microsoft Store!).

> ⚠️ **Aviso**: Este projeto é apenas para fins educacionais. Por favor, apoie os desenvolvedores comprando o jogo.

---

## ⬇️ Download

<p align="center">
  <a href="https://github.com/CoelhoFZ/MinecraftBedrockUnlocker/releases/latest/download/MinecraftBedrockUnlocker.exe">
    <img src="https://img.shields.io/badge/Baixar%20EXE-MinecraftBedrockUnlocker.exe-blue?style=for-the-badge&logo=windows" alt="Baixar EXE"/>
  </a>
</p>

> **Opção 1 - PowerShell one-liner** *(recomendado)*
> Baixa o EXE self-contained mais recente, verifica SHA256 e inicia como Administrador:
> ```powershell
> irm https://github.com/CoelhoFZ/MinecraftBedrockUnlocker/raw/main/e.ps1 | iex
> ```

> **Opção 2 - Bootstrap alternativo**
> Igual à Opção 1, usa um método de download diferente:
> ```powershell
> irm https://github.com/CoelhoFZ/MinecraftBedrockUnlocker/raw/main/i.ps1 | iex
> ```

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
4. Gerencia exclusões de antivírus automaticamente
5. Instala e verifica os arquivos de desbloqueio
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

- 🌍 **Multi-idioma**: Detecta automaticamente EN, PT-BR, ES
- 🛡️ **Tratamento de antivírus**: Adiciona exclusões automaticamente para Windows Defender, Bitdefender Free e outros
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

Os arquivos usados podem disparar alertas de antivírus - **isso é esperado** com qualquer ferramenta de desbloqueio.

1. **Código do instalador disponível** - Você pode revisar o instalador PowerShell GPLv3 e o source do wrapper EXE neste repositório
2. **DLLs de runtime são third-party** - `winmm.dll` e `OnlineFix64.dll` são componentes fechados da Online-Fix documentados em [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)
3. **Exclusões guiadas** - A ferramenta guia você para adicionar exceções no seu AV específico

## Escopo do código-fonte e licença

O instalador, o wrapper launcher e a documentação criados neste repositório continuam licenciados sob **GPLv3**. Veja [SOURCE.md](SOURCE.md) para o mapa de source e instruções de build.

As DLLs de runtime que fazem o desbloqueio são componentes fechados da Online-Fix. CoelhoFZ não tem acesso ao código-fonte delas, então elas são documentadas separadamente em [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) e não são relicenciadas por este repositório.

## O que muda no seu PC

- Instala os arquivos de desbloqueio em `C:\XboxGames\Minecraft for Windows\Content`.
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

- Equipe OnlineFix pelas DLLs de runtime fechadas usadas pelo fluxo de desbloqueio
- CoelhoFZ pelo desenvolvimento do instalador e wrapper GPLv3

## Licença

Instalador, wrapper launcher e documentação criados neste repositório: GPLv3 - Veja [LICENSE](LICENSE).

Binários third-party de runtime da Online-Fix estão documentados em [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) e não são relicenciados por este repositório.
