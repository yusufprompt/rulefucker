#!/usr/bin/env python3
import os
import sys
import argparse
import subprocess
import shutil

# Root kontrolü
def require_root():
    if os.geteuid() != 0:
        print("Hata: Bu araç kalıcı sistem değişiklikleri yapar. Lütfen 'sudo' ile çalıştırın.")
        sys.exit(1)

def backup_file(filepath):
    if os.path.exists(filepath):
        backup_path = filepath + ".rulefucker.bak"
        if not os.path.exists(backup_path):
            shutil.copy2(filepath, backup_path)
            print(f"Yedeklendi: {filepath} -> {backup_path}")

def cmd_set_uname(args):
    require_root()
    
    # Kullanıcı argüman girmediyse interaktif olarak sor
    sysname = args.sysname or input("Sysname ne olsun? (İşletim Sistemi Adı, örn: RuleOS): ").strip()
    nodename = args.nodename or input("Nodename ne olsun? (Makine Adı, örn: god-pc): ").strip()
    release = args.release or input("Kernel Release ne olsun? (Sürüm numarası, örn: 99.0.1): ").strip()
    version = args.version or input("Kernel Version ne olsun? (Detaylı sürüm bilgisi): ").strip()
    machine = args.machine or input("Machine Architecture ne olsun? (Mimari, örn: x86_64): ").strip()
    
    # Kernel modülünü derle ve yükle
    module_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "kernel_module"))
    
    print("\nKernel modülü derleniyor...")
    res = subprocess.run(["make"], cwd=module_dir)
    if res.returncode != 0:
        print("Hata: Kernel modülü derlenemedi. 'linux-headers' yüklü mü kontrol edin.")
        return

    # Önceki modülü kaldır
    subprocess.run(["rmmod", "rulefucker_kernel"], stderr=subprocess.DEVNULL)
    
    # Yeni modülü yükle
    insmod_args = ["insmod", "rulefucker_kernel.ko"]
    if sysname: insmod_args.append(f"sysname={sysname}")
    if nodename: insmod_args.append(f"nodename={nodename}")
    if release: insmod_args.append(f"release={release}")
    if version: insmod_args.append(f"version={version}")
    if machine: insmod_args.append(f"machine={machine}")
    
    print("Kernel modülü belleğe yükleniyor (init_uts_ns değiştiriliyor)...")
    res = subprocess.run(insmod_args, cwd=module_dir)
    if res.returncode == 0:
        print("\033[92mBaşarılı! Uname değerleri kalıcı olarak (ram üzerinde) değiştirildi.\033[0m")
    else:
        print("Hata: Modül yüklenemedi. Secure Boot kapalı mı ve root musunuz?")

def cmd_set_os(args):
    require_root()
    target = "/etc/os-release"
    backup_file(target)
    
    content = f"""NAME="{args.name}"
PRETTY_NAME="{args.name} Linux"
ID="{args.id}"
ID_LIKE="arch"
ANSI_COLOR="38;2;23;147;209"
"""
    with open(target, "w") as f:
        f.write(content)
        
    print(f"\033[92mBaşarılı! İşletim sistemi kimliği {args.name} olarak değiştirildi.\033[0m")

def detect_pm():
    if shutil.which("apt"): return "apt"
    if shutil.which("pacman"): return "pacman"
    if shutil.which("dnf"): return "dnf"
    if shutil.which("zypper"): return "zypper"
    return None

def cmd_install_de(args):
    require_root()
    pm = detect_pm()
    if not pm:
        print("Desteklenen paket yöneticisi bulunamadı (apt, pacman, dnf, zypper).")
        return
        
    de = args.de.lower()
    packages = []
    
    if de == "hyprland":
        packages = ["hyprland", "kitty", "waybar"]
    elif de == "xfce":
        if pm == "apt": packages = ["xfce4", "xfce4-goodies"]
        else: packages = ["xfce4"]
    elif de == "gnome":
        packages = ["gnome"]
    else:
        packages = [de]
        
    print(f"Paket yöneticisi ({pm}) kullanılarak {de} kuruluyor...")
    
    install_cmd = []
    if pm == "apt": install_cmd = ["apt", "install", "-y"]
    elif pm == "pacman": install_cmd = ["pacman", "-S", "--noconfirm"]
    elif pm == "dnf": install_cmd = ["dnf", "install", "-y"]
    elif pm == "zypper": install_cmd = ["zypper", "install", "-y"]
    
    subprocess.run(install_cmd + packages)
    print(f"\033[92mKurulum tamamlandı. Sistem yeniden başlatıldığında veya Display Manager üzerinden {de} seçilebilir.\033[0m")

def main():
    parser = argparse.ArgumentParser(description="Rulefucker v3.0 Native Customizer")
    subparsers = parser.add_subparsers(dest="command")
    
    # uname kernel module
    p_uname = subparsers.add_parser("uname", help="Kernel kimliğini (uname) kalıcı değiştir")
    p_uname.add_argument("--sysname", help="Sysname (örn. Linux)")
    p_uname.add_argument("--nodename", help="Nodename")
    p_uname.add_argument("--release", help="Kernel release")
    p_uname.add_argument("--version", help="Kernel version")
    p_uname.add_argument("--machine", help="Machine arch")
    p_uname.set_defaults(func=cmd_set_uname)
    
    # os-release
    p_os = subparsers.add_parser("os", help="/etc/os-release kimliğini kalıcı değiştir")
    p_os.add_argument("--name", required=True, help="İşletim sistemi adı (Örn: RuleOS)")
    p_os.add_argument("--id", required=True, help="İşletim sistemi ID (Örn: ruleos)")
    p_os.set_defaults(func=cmd_set_os)
    
    # de / wm installer
    p_de = subparsers.add_parser("install", help="DE / WM yükle (Distro bağımsız)")
    p_de.add_argument("de", help="Kurulacak DE/WM adı (Örn: hyprland, xfce)")
    p_de.set_defaults(func=cmd_install_de)
    
    args = parser.parse_args()
    if hasattr(args, "func"):
        args.func(args)
    else:
        parser.print_help()

if __name__ == "__main__":
    main()
