# Minecraft Bedrock Unlocker (GDK)

🎮 **Bypass do Modo Trial do Minecraft Bedrock (Windows 10/11)**

Ferramenta CLI para desbloquear a versão completa do Minecraft Bedrock Edition (GDK) usando o método OnlineFix.

> ⚠️ **Aviso**: Este projeto é apenas para fins educacionais. Por favor, apoie os desenvolvedores comprando o jogo.

## Requisitos

- Windows 10/11
- Minecraft Bedrock Edition (Trial) instalado da **Microsoft Store** ou **Xbox App**
- Jogo instalado em `C:\XboxGames\Minecraft for Windows\` (via Xbox App)

## Instalação

### Opção 1: Usar o Executável (Recomendado)

1. Baixe o executável da [página de Releases](https://github.com/CoelhoFZ/MinecraftBedrockUnlocker/releases)
2. Execute como **Administrador**
3. Escolha **[1] Instalar Mod**
4. Abra o Minecraft pelo Menu Iniciar!

### Opção 2: Compilar do Código Fonte

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
[4] Abrir Microsoft Store
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

## Compatibilidade

- ✅ Minecraft Bedrock 1.21.120+ (GDK)
- ✅ Windows 10/11
- ❌ Xbox Console / Mobile

## Créditos

- Equipe OnlineFix pelo método de bypass
- CoelhoFZ pelo desenvolvimento da ferramenta

## Comunidade

Entre no nosso Discord: https://discord.gg/HP74ccUP

## Licença

GPLv3 License - Veja [LICENSE](LICENSE)
