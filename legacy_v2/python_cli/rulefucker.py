#!/usr/bin/env python3
import os
import sys
import argparse
import subprocess
import shutil

# Dinamik ana dizin tespiti (Hardcoded yollar yerine esnek yapı)
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
CONFIG_PATH = os.environ.get("RULEFUCKER_CONFIG_PATH", os.path.join(BASE_DIR, "config/rulefucker.conf"))
SPOOF_DIR = os.environ.get("RULEFUCKER_SPOOF_DIR", os.path.join(BASE_DIR, "config/rulefucker_spoof"))

def parse_config():
    config = {}
    if os.path.exists(CONFIG_PATH):
        with open(CONFIG_PATH, "r") as f:
            for line in f:
                if "=" in line:
                    k, v = line.strip().split("=", 1)
                    config[k] = v
    return config

def write_config(config):
    os.makedirs(os.path.dirname(CONFIG_PATH), exist_ok=True)
    with open(CONFIG_PATH, "w") as f:
        for k, v in config.items():
            f.write(f"{k}={v}\n")

def ensure_c_compiled():
    """
    Sistemdeki .c dosyalarını ve Makefile'ları otomatik olarak tarar ve derler.
    """
    # Proje içindeki olası C ve Kernel modülü dizinleri
    target_dirs = [
        os.path.join(BASE_DIR, "c_hook"),
        os.path.join(BASE_DIR, "kernel_module"),
        BASE_DIR
    ]
    
    for d in target_dirs:
        if os.path.exists(d):
            # Dizinde Makefile veya .c dosyası var mı kontrol et
            files = os.listdir(d)
            if "Makefile" in files or any(f.endswith(".c") for f in files):
                print(f"\033[36m[*] C kaynak dosyaları tarandı, otomatik derleniyor: {d}\033[0m")
                if shutil.which("make"):
                    # Sudo PATH hatasını engellemek için kabuk üzerinden tetikliyoruz
                    res = subprocess.run("make", shell=True, cwd=d)
                    if res.returncode == 0:
                        print(f"\033[32m[✓] {os.path.basename(d)} başarıyla derlendi.\033[0m")
                    else:
                        print(f"\033[31m[-] {os.path.basename(d)} derlemesi hata verdi (Kod: {res.returncode}).\033[0m")
                else:
                    print("\033[31m[-] Hata: Sistemde 'make' bulunamadı.\033[0m")

def cmd_set_uname(args):
    config = parse_config()
    
    # EĞER BASH'TEN PARAMETRESİZ ÇAĞRILDIYSA: İnteraktif girdi iste (Boş kalan değişmez)
    if not (args.sysname or args.nodename or args.release or args.version or args.machine):
        print("\n\033[1;33m[*] Uname Özelleştirme Modu (Değiştirmek istemediğinizi Boş Geçin)\033[0m")
        sysname = input("Yeni Sysname (Örn: Linux, Windows): ").strip()
        nodename = input("Yeni Nodename (Örn: yustea-godmode): ").strip()
        release = input("Yeni Kernel Release (Örn: 9.9.9-arch-rulefucker): ").strip()
        version = input("Yeni Kernel Version (Örn: #1 SMP PREEMPT_DYNAMIC): ").strip()
        machine = input("Yeni Mimari (Örn: x86_64, arm64): ").strip()
        
        if sysname: config["sysname"] = sysname
        if nodename: config["nodename"] = nodename
        if release: config["release"] = release
        if version: config["version"] = version
        if machine: config["machine"] = machine
    else:
        if args.sysname: config["sysname"] = args.sysname
        if args.nodename: config["nodename"] = args.nodename
        if args.release: config["release"] = args.release
        if args.version: config["version"] = args.version
        if args.machine: config["machine"] = args.machine
        
    write_config(config)
    print("\033[32m[✓] Uname hafıza konfigürasyonu başarıyla güncellendi.\033[0m")

def cmd_os_identity(args):
    """ Bash scriptindeki 'os' seçeneği için tetiklenen interaktif arayüzü """
    print("\n\033[1;33m[*] OS Identity Customization (/etc/os-release Sahteleme)\033[0m")
    name = input("Görüntülenecek İşletim Sistemi Adı (Örn: Arch Linux): ").strip()
    os_id = input("İşletim Sistemi ID'si (Örn: arch): ").strip()
    
    if not name or not os_id:
        print("\033[31m[-] Hata: Değerler boş bırakılamaz.\033[0m")
        return
        
    content = f'NAME="{name}"\nID={os_id}\nPRETTY_NAME="{name}"\nID_LIKE=arch\n'
    target = "/etc/os-release"
    
    spoofed_path = os.path.join(SPOOF_DIR, target.lstrip("/"))
    os.makedirs(os.path.dirname(spoofed_path), exist_ok=True)
    
    with open(spoofed_path, "w") as f:
        f.write(content)
        
    print(f"\033[32m[✓] {target} dosyası başarıyla sahtelendi.\033[0m")

def cmd_spoof_file(args):
    if not args.target.startswith("/"):
        print("\033[31mHata: Hedef dosya yolu mutlak olmalıdır.\033[0m")
        return
    spoofed_path = os.path.join(SPOOF_DIR, args.target.lstrip("/"))
    os.makedirs(os.path.dirname(spoofed_path), exist_ok=True)
    with open(spoofed_path, "w") as f:
        f.write(args.content)
    print(f"[✓] Sahtelendi: {args.target}")

def cmd_shell(args):
    # Kabuk açılmadan hemen önce tüm C dosyalarını tara ve derle!
    ensure_c_compiled()
    
    env = os.environ.copy()
    so_path = os.path.abspath(os.path.join(BASE_DIR, "c_hook/rulefucker.so"))
    ko_path = os.path.abspath(os.path.join(BASE_DIR, "kernel_module/rf_uname.ko"))
    
    # Eğer kernel modülü (.ko) derlendiyse, kernele enjekte etmeye çalış
    if os.path.exists(ko_path):
        print("\033[35m[*] Kernel modülü (.ko) tespit edildi, enjekte ediliyor...\033[0m")
        subprocess.run(["sudo", "insmod", ko_path], stderr=subprocess.DEVNULL)

    if not os.path.exists(so_path) and not os.path.exists(ko_path):
        print("\033[31m[-] Hata: Derlenmiş kütüphane (.so) veya Kernel nesnesi (.ko) bulunamadı.\033[0m")
        return

    if os.path.exists(so_path):
        env["LD_PRELOAD"] = so_path
        
    env["RULEFUCKER_CONFIG_PATH"] = CONFIG_PATH
    env["RULEFUCKER_SPOOF_DIR"] = SPOOF_DIR
    
    print("\n\033[92m[Rulefucker God Mode]\033[0m İzole ve sahtelenmiş shell ortamına giriliyor.")
    print("Gerçek uname değerlerini manipüle etmek için kancalar aktif edildi. Çıkış için 'exit' yazın.")
    subprocess.run([os.environ.get("SHELL", "/bin/bash")], env=env)

def main():
    parser = argparse.ArgumentParser(description="Rulefucker CLI")
    subparsers = parser.add_subparsers(dest="command")
    
    # uname
    parser_uname = subparsers.add_parser("uname")
    parser_uname.add_argument("--sysname")
    parser_uname.add_argument("--nodename")
    parser_uname.add_argument("--release")
    parser_uname.add_argument("--version")
    parser_uname.add_argument("--machine")
    parser_uname.set_defaults(func=cmd_set_uname)
    
    # os (Bash scriptindeki 'os' çağrısı ile tam uyum için)
    parser_os = subparsers.add_parser("os")
    parser_os.set_defaults(func=cmd_os_identity)
    
    # file
    parser_file = subparsers.add_parser("file")
    parser_file.add_argument("target")
    parser_file.add_argument("content")
    parser_file.set_defaults(func=cmd_spoof_file)
    
    # shell
    parser_shell = subparsers.add_parser("shell")
    parser_shell.set_defaults(func=cmd_shell)
    
    # Bash'ten gelebilecek diğer komutların çökmemesi için sessiz geçiş sağlayan stubs
    for dummy in ["install", "git-install", "boot", "mac"]:
        subparsers.add_parser(dummy).set_defaults(func=lambda a: None)
    
    args = parser.parse_args()
    if hasattr(args, "func"):
        args.func(args)
    else:
        parser.print_help()

if __name__ == "__main__":
    main()
