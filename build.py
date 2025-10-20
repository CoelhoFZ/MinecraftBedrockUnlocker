#!/usr/bin/env python3
"""
Script de Build - Minecraft Unlocker Rust
Compila o projeto e embute o manifest de administrador
"""
import subprocess
import sys
import os
import shutil
from pathlib import Path
import glob

def print_banner():
    """Exibe o banner do script"""
    print("╔══════════════════════════════════════════════════════════╗")
    print("║        COMPILADOR RÁPIDO - Minecraft Unlocker Rust       ║")
    print("╚══════════════════════════════════════════════════════════╝")
    print()

def find_mt_exe():
    """Encontra o mt.exe do Windows SDK"""
    windows_kits = Path(r"C:\Program Files (x86)\Windows Kits\10\bin")
    
    if not windows_kits.exists():
        return None
    
    # Procurar mt.exe em todas as versões do SDK (exceto ARM)
    for mt_path in windows_kits.rglob("mt.exe"):
        # Ignorar versões ARM
        if "arm" not in str(mt_path).lower() and "x64" in str(mt_path):
            return mt_path
    
    return None

def get_file_size(file_path):
    """Retorna o tamanho do arquivo formatado"""
    size = os.path.getsize(file_path)
    
    if size < 1024:
        return f"{size} bytes"
    elif size < 1024 * 1024:
        return f"{size / 1024:.2f} KB"
    else:
        return f"{size / (1024 * 1024):.2f} MB"

def compile_project():
    """Compila o projeto Rust"""
    print("[INFO] Compilando versão Release (otimizada)...")
    print()
    
    # Mudar para o diretório do script
    script_dir = Path(__file__).parent
    os.chdir(script_dir)
    
    # Executar cargo build
    result = subprocess.run(
        ["cargo", "build", "--release"],
        capture_output=False,
        text=True
    )
    
    return result.returncode == 0

def embed_manifest():
    """Embute o manifest de administrador no executável"""
    print()
    print("[INFO] Embutindo manifest de Administrador...")
    
    exe_path = Path("target/release/mc_unlocker.exe")
    manifest_path = Path("minecraft-unlocker-cli.manifest")
    
    if not exe_path.exists():
        print("[ERRO] Executável não encontrado!")
        return False
    
    if not manifest_path.exists():
        print("[AVISO] Manifest não encontrado - pulando...")
        return True
    
    # Procurar mt.exe
    mt_exe = find_mt_exe()
    
    if not mt_exe:
        print("[AVISO] mt.exe não encontrado - manifest não embutido")
        print("         O executável ainda funcionará, mas pode precisar de UAC manual")
        return True
    
    # Embutir manifest
    try:
        result = subprocess.run(
            [
                str(mt_exe),
                "-manifest", str(manifest_path),
                "-outputresource:" + str(exe_path) + ";1"
            ],
            capture_output=True,
            text=True
        )
        
        if result.returncode == 0:
            print("[OK] Manifest embutido com sucesso!")
            return True
        else:
            print("[AVISO] Falha ao embutir manifest")
            print(f"        {result.stderr}")
            return True  # Não é crítico
    except Exception as e:
        print(f"[AVISO] Erro ao embutir manifest: {e}")
        return True  # Não é crítico

def show_results():
    """Exibe informações sobre o executável gerado"""
    exe_path = Path("target/release/mc_unlocker.exe")
    
    if not exe_path.exists():
        return
    
    print()
    print(f"Executável: {exe_path}")
    print(f"Tamanho:    {get_file_size(exe_path)}")
    print()

def copy_to_parent():
    """Copia o executável para a pasta pai do projeto"""
    source = Path("target/release/mc_unlocker.exe")
    dest = Path("../minecraft-unlocker-cli-rust.exe")
    
    if not source.exists():
        return False
    
    try:
        print("Copiando para a raiz do projeto...")
        shutil.copy2(source, dest)
        print(f"[OK] Executável copiado para: {dest.absolute()}")
        return True
    except Exception as e:
        print(f"[AVISO] Erro ao copiar executável: {e}")
        return False

def main():
    """Função principal"""
    print_banner()
    
    # Verificar se cargo está instalado
    if shutil.which("cargo") is None:
        print("[ERRO] Cargo não encontrado!")
        print("       Instale o Rust de: https://rustup.rs/")
        return 1
    
    # Compilar
    if not compile_project():
        print()
        print("[ERRO] Falha na compilação!")
        return 1
    
    print()
    print("[OK] Compilação concluída!")
    
    # Embutir manifest
    embed_manifest()
    
    # Mostrar resultados
    show_results()
    
    # Copiar para pasta pai
    copy_to_parent()
    
    print()
    print("✓ Build concluído com sucesso!")
    return 0

if __name__ == "__main__":
    try:
        exit_code = main()
        print()
        input("Pressione ENTER para sair...")
        sys.exit(exit_code)
    except KeyboardInterrupt:
        print()
        print("[AVISO] Build cancelado pelo usuário")
        sys.exit(1)
    except Exception as e:
        print()
        print(f"[ERRO] Erro inesperado: {e}")
        import traceback
        traceback.print_exc()
        input("Pressione ENTER para sair...")
        sys.exit(1)
