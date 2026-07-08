#!/usr/bin/env python3
import os
import sys
import argparse
import subprocess

# Yapılandırma yolları (çevre değişkenlerinden alınır)
CONFIG_PATH = os.environ.get("RULEFUCKER_CONFIG_PATH", "/home/yusuf/rulefucker/config/rulefucker.conf")
SPOOF_DIR = os.environ.get("RULEFUCKER_SPOOF_DIR", "/home/yusuf/rulefucker/config/rulefucker_spoof")

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

def cmd_set_uname(args):
    config = parse_config()
    if args.sysname: config["sysname"] = args.sysname
    if args.nodename: config["nodename"] = args.nodename
    if args.release: config["release"] = args.release
    if args.version: config["version"] = args.version
    if args.machine: config["machine"] = args.machine
    write_config(config)
    print("Uname değerleri güncellendi.")

def cmd_spoof_file(args):
    target = args.target
    content = args.content
    
    if not target.startswith("/"):
        print("Hata: Hedef dosya yolu mutlak (/ ile başlayan) olmalıdır.")
        return
        
    spoofed_path = os.path.join(SPOOF_DIR, target.lstrip("/"))
    os.makedirs(os.path.dirname(spoofed_path), exist_ok=True)
    
    with open(spoofed_path, "w") as f:
        f.write(content)
        
    print(f"'{target}' dosyası başarıyla sahtelendi. Spoof yolu: {spoofed_path}")

def cmd_shell(args):
    env = os.environ.copy()
    so_path = os.path.abspath(os.path.join(os.path.dirname(__file__), "../c_hook/rulefucker.so"))
    
    if not os.path.exists(so_path):
        print(f"Hata: C kütüphanesi bulunamadı ({so_path}). Lütfen c_hook dizininde 'make' çalıştırın.")
        return

    env["LD_PRELOAD"] = so_path
    env["RULEFUCKER_CONFIG_PATH"] = CONFIG_PATH
    env["RULEFUCKER_SPOOF_DIR"] = SPOOF_DIR
    
    print("\033[92m[Rulefucker]\033[0m İzole ve sahtelenmiş shell ortamına giriliyor.")
    print("Çıkmak için 'exit' yazın.")
    subprocess.run([os.environ.get("SHELL", "/bin/bash")], env=env)

def main():
    parser = argparse.ArgumentParser(description="Rulefucker CLI")
    subparsers = parser.add_subparsers(dest="command")
    
    # uname
    parser_uname = subparsers.add_parser("uname", help="Uname değerlerini ayarla")
    parser_uname.add_argument("--sysname", help="Sysname (örn. Linux)")
    parser_uname.add_argument("--nodename", help="Nodename (örn. custom-pc)")
    parser_uname.add_argument("--release", help="Kernel release (örn. 9.9.9)")
    parser_uname.add_argument("--version", help="Kernel version")
    parser_uname.add_argument("--machine", help="Machine architecture (örn. x86_64)")
    parser_uname.set_defaults(func=cmd_set_uname)
    
    # file
    parser_file = subparsers.add_parser("file", help="Bir dosyanın içeriğini sahtele")
    parser_file.add_argument("target", help="Hedef dosya yolu (örn. /etc/os-release)")
    parser_file.add_argument("content", help="Dosyanın yeni sahte içeriği")
    parser_file.set_defaults(func=cmd_spoof_file)
    
    # shell
    parser_shell = subparsers.add_parser("shell", help="Özelleştirilmiş değerlerle shell başlat")
    parser_shell.set_defaults(func=cmd_shell)
    
    args = parser.parse_args()
    if hasattr(args, "func"):
        args.func(args)
    else:
        parser.print_help()

if __name__ == "__main__":
    main()
