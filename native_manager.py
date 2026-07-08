#!/usr/bin/env python3
import os
import sys
import argparse
import subprocess
import shutil
import re

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

# ==========================================
# AKILLI OS MOTORU (SYSTEM DETECTOR)
# ==========================================
class SystemDetector:
    @staticmethod
    def get_pm():
        if shutil.which("apt"): return "apt"
        if shutil.which("pacman"): return "pacman"
        if shutil.which("dnf"): return "dnf"
        if shutil.which("zypper"): return "zypper"
        if shutil.which("apk"): return "apk"
        return None

    @staticmethod
    def get_bootloader():
        if os.path.exists("/boot/grub/grub.cfg") or os.path.exists("/etc/default/grub"):
            return "grub"
        if os.path.exists("/boot/efi/loader/loader.conf") or os.path.exists("/boot/loader/loader.conf"):
            return "systemd-boot"
        return "unknown"

    @staticmethod
    def get_init():
        try:
            with open("/proc/1/comm", "r") as f:
                return f.read().strip()
        except:
            return "unknown"

# ==========================================
# GÖREV: KERNEL UNAME DEĞİŞTİRİCİ
# ==========================================
def cmd_set_uname(args):
    require_root()
    sysname = args.sysname or input("Sysname ne olsun? (örn: RuleOS): ").strip()
    nodename = args.nodename or input("Nodename ne olsun? (örn: god-pc): ").strip()
    release = args.release or input("Kernel Release ne olsun? (örn: 99.0.1): ").strip()
    version = args.version or input("Kernel Version ne olsun?: ").strip()
    machine = args.machine or input("Machine Architecture ne olsun? (örn: x86_64): ").strip()
    
    module_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "kernel_module"))
    
    print("\nKernel modülü derleniyor...")
    res = subprocess.run(["make"], cwd=module_dir)
    if res.returncode != 0:
        print("Hata: Kernel modülü derlenemedi. 'linux-headers' yüklü mü kontrol edin.")
        return

    subprocess.run(["rmmod", "rulefucker_kernel"], stderr=subprocess.DEVNULL)
    
    insmod_args = ["insmod", "rulefucker_kernel.ko"]
    if sysname: insmod_args.append(f"sysname={sysname}")
    if nodename: insmod_args.append(f"nodename={nodename}")
    if release: insmod_args.append(f"release={release}")
    if version: insmod_args.append(f"version={version}")
    if machine: insmod_args.append(f"machine={machine}")
    
    res = subprocess.run(insmod_args, cwd=module_dir)
    if res.returncode == 0:
        print("\033[92mBaşarılı! Uname değerleri kalıcı olarak (ram üzerinde) değiştirildi.\033[0m")
    else:
        print("Hata: Modül yüklenemedi. Secure Boot kapalı mı ve root musunuz?")

# ==========================================
# GÖREV: OS IDENTITY
# ==========================================
def cmd_set_os(args):
    require_root()
    name = args.name or input("İşletim Sistemi Adı ne olsun? (Örn: RuleOS): ").strip()
    id_ = args.id or input("İşletim Sistemi ID'si ne olsun? (Örn: ruleos): ").strip()
    
    if not name or not id_: return
    
    target = "/etc/os-release"
    backup_file(target)
    
    content = f'NAME="{name}"\nPRETTY_NAME="{name} Linux"\nID="{id_}"\nID_LIKE="arch"\nANSI_COLOR="38;2;23;147;209"\n'
    with open(target, "w") as f: f.write(content)
        
    print(f"\033[92mBaşarılı! İşletim sistemi kimliği {name} olarak değiştirildi.\033[0m")

# ==========================================
# GÖREV: DE/WM KURUCU
# ==========================================
def cmd_install_de(args):
    require_root()
    pm = SystemDetector.get_pm()
    if not pm:
        print("Desteklenen paket yöneticisi bulunamadı.")
        return
        
    de = args.de.lower()
    packages = []
    
    if de == "hyprland": packages = ["hyprland", "kitty", "waybar"]
    elif de == "xfce": packages = ["xfce4", "xfce4-goodies"] if pm == "apt" else ["xfce4"]
    elif de == "gnome": packages = ["gnome"]
    else: packages = [de]
        
    print(f"[{pm}] kullanılarak {de} kuruluyor...")
    
    install_cmd = []
    if pm == "apt": install_cmd = ["apt", "install", "-y"]
    elif pm == "pacman": install_cmd = ["pacman", "-S", "--noconfirm"]
    elif pm == "dnf": install_cmd = ["dnf", "install", "-y"]
    elif pm == "zypper": install_cmd = ["zypper", "install", "-y"]
    elif pm == "apk": install_cmd = ["apk", "add"]
    
    subprocess.run(install_cmd + packages)
    print(f"\033[92mKurulum tamamlandı.\033[0m")

# ==========================================
# GÖREV: GIT INSTALL (DERLEYİCİ/KURUCU)
# ==========================================
def cmd_git_install(args):
    require_root()
    url = args.url or input("Git Depo URL'si: ").strip()
    if not url: return
    
    build_dir = "/tmp/rulefucker_build"
    shutil.rmtree(build_dir, ignore_errors=True)
    
    print(f"Depo klonlanıyor: {url}")
    if subprocess.run(["git", "clone", url, build_dir]).returncode != 0:
        print("Klonlama başarısız oldu!")
        return
        
    print("Derleme sistemi aranıyor...")
    if os.path.exists(os.path.join(build_dir, "Cargo.toml")):
        print("[Cargo (Rust)] tespit edildi.")
        subprocess.run(["cargo", "install", "--path", "."], cwd=build_dir)
    elif os.path.exists(os.path.join(build_dir, "CMakeLists.txt")):
        print("[CMake] tespit edildi.")
        os.makedirs(os.path.join(build_dir, "build"), exist_ok=True)
        subprocess.run(["cmake", ".."], cwd=os.path.join(build_dir, "build"))
        subprocess.run(["make", "-j4"], cwd=os.path.join(build_dir, "build"))
        subprocess.run(["make", "install"], cwd=os.path.join(build_dir, "build"))
    elif os.path.exists(os.path.join(build_dir, "configure")):
        print("[Autotools] tespit edildi.")
        subprocess.run(["./configure"], cwd=build_dir)
        subprocess.run(["make", "-j4"], cwd=build_dir)
        subprocess.run(["make", "install"], cwd=build_dir)
    elif os.path.exists(os.path.join(build_dir, "Makefile")):
        print("[Make] tespit edildi.")
        subprocess.run(["make", "-j4"], cwd=build_dir)
        subprocess.run(["make", "install"], cwd=build_dir)
    elif os.path.exists(os.path.join(build_dir, "setup.py")):
        print("[Python] tespit edildi.")
        subprocess.run(["python3", "setup.py", "install"], cwd=build_dir)
    else:
        print("Otomatik derleme sistemi tespit edilemedi. Sadece klonlandı.")
        return
        
    print("\033[92mKurulum başarıyla tamamlandı!\033[0m")

# ==========================================
# GÖREV: BOOTLOADER / INIT
# ==========================================
def cmd_boot(args):
    require_root()
    bootloader = SystemDetector.get_bootloader()
    if bootloader != "grub":
        print("Şu an sadece GRUB otomatik düzenlemesi destekleniyor.")
        return
        
    param = args.param or input("Eklenecek kernel parametresi (Örn: init=/bin/bash veya quiet): ").strip()
    if not param: return
    
    grub_path = "/etc/default/grub"
    backup_file(grub_path)
    
    with open(grub_path, "r") as f:
        lines = f.readlines()
        
    for i, line in enumerate(lines):
        if line.startswith("GRUB_CMDLINE_LINUX_DEFAULT="):
            match = re.search(r'GRUB_CMDLINE_LINUX_DEFAULT="(.*)"', line)
            if match:
                current = match.group(1)
                lines[i] = f'GRUB_CMDLINE_LINUX_DEFAULT="{current} {param}"\n'
                break
    
    with open(grub_path, "w") as f:
        f.writelines(lines)
        
    print("GRUB güncelleniyor...")
    if shutil.which("update-grub"):
        subprocess.run(["update-grub"])
    elif shutil.which("grub-mkconfig"):
        subprocess.run(["grub-mkconfig", "-o", "/boot/grub/grub.cfg"])
        
    print("\033[92mBoot parametreleri eklendi. Sonraki yeniden başlatmada aktif olacak.\033[0m")

# ==========================================
# GÖREV: AĞ / MAC ADRESİ
# ==========================================
def cmd_mac(args):
    require_root()
    iface = args.iface or input("Ağ arayüzü adı (Örn: eth0, wlan0): ").strip()
    mac = args.mac or input("Yeni MAC adresi (Örn: 00:11:22:33:44:55): ").strip()
    
    if not iface or not mac: return
    
    print(f"{iface} kapatılıyor...")
    subprocess.run(["ip", "link", "set", "dev", iface, "down"])
    print("MAC değiştiriliyor...")
    subprocess.run(["ip", "link", "set", "dev", iface, "address", mac])
    print(f"{iface} açılıyor...")
    subprocess.run(["ip", "link", "set", "dev", iface, "up"])
    
    print("\033[92mMAC adresi başarıyla değiştirildi.\033[0m")

# ==========================================
# GÖREV: KABUK (SHELL) DEĞİŞTİRME
# ==========================================
def cmd_shell(args):
    require_root()
    new_shell = args.shell or input("Geçiş yapılacak kabuk (Örn: /bin/zsh veya /bin/fish): ").strip()
    user = input("Hangi kullanıcı için değiştirilecek? (örn: root): ").strip()
    
    if not new_shell or not user: return
    
    if subprocess.run(["chsh", "-s", new_shell, user]).returncode == 0:
        print("\033[92mVarsayılan kabuk başarıyla değiştirildi.\033[0m")
    else:
        print("Kabuk değiştirilemedi.")

def main():
    parser = argparse.ArgumentParser(description="Rulefucker v4.0 God Mode")
    subparsers = parser.add_subparsers(dest="command")
    
    p_uname = subparsers.add_parser("uname")
    p_uname.add_argument("--sysname"); p_uname.add_argument("--nodename")
    p_uname.add_argument("--release"); p_uname.add_argument("--version"); p_uname.add_argument("--machine")
    p_uname.set_defaults(func=cmd_set_uname)
    
    p_os = subparsers.add_parser("os")
    p_os.add_argument("--name"); p_os.add_argument("--id")
    p_os.set_defaults(func=cmd_set_os)
    
    p_de = subparsers.add_parser("install")
    p_de.add_argument("de", nargs="?")
    p_de.set_defaults(func=cmd_install_de)
    
    p_git = subparsers.add_parser("git-install")
    p_git.add_argument("url", nargs="?")
    p_git.set_defaults(func=cmd_git_install)
    
    p_boot = subparsers.add_parser("boot")
    p_boot.add_argument("--param")
    p_boot.set_defaults(func=cmd_boot)
    
    p_mac = subparsers.add_parser("mac")
    p_mac.add_argument("--iface"); p_mac.add_argument("--mac")
    p_mac.set_defaults(func=cmd_mac)
    
    p_shell = subparsers.add_parser("shell")
    p_shell.add_argument("--shell")
    p_shell.set_defaults(func=cmd_shell)
    
    args = parser.parse_args()
    if hasattr(args, "func"):
        args.func(args)
    else:
        parser.print_help()

if __name__ == "__main__":
    main()
