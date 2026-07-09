#!/usr/bin/env python3
"""
Rulefucker Advanced Loader
- Parametreleri doğrudan modül parametresi olarak iletir (yeniden derleme yok)
- Kalıcılık için initramfs/systemd hook kurulumu
- Stealth mod desteği
"""
import os
import sys
import subprocess
import shutil
import argparse
import tempfile

KERNEL_MODULE_SRC = "rulefucker_kernel_advanced.c"
MAKEFILE_CONTENT = """obj-m += rulefucker_kernel_advanced.o

all:
\tmake -C /lib/modules/$(shell uname -r)/build M=$(PWD) modules

clean:
\tmake -C /lib/modules/$(shell uname -r)/build M=$(PWD) clean
"""


def require_root():
    if os.geteuid() != 0:
        print("[-] Root yetkisi gerekli. sudo ile çalıştırın.")
        sys.exit(1)


def build_module(build_dir: str) -> str:
    """Modülü derle ve .ko yolunu döndür."""
    src_path = os.path.join(build_dir, KERNEL_MODULE_SRC)
    makefile_path = os.path.join(build_dir, "Makefile")

    # Kaynak kodu build dizinine kopyala
    shutil.copy(KERNEL_MODULE_SRC, src_path)

    with open(makefile_path, "w") as f:
        f.write(MAKEFILE_CONTENT)

    print("[*] Kernel modülü derleniyor...")
    result = subprocess.run(
        ["make", "-C", f"/lib/modules/$(uname -r)/build",
         "M=" + build_dir, "modules"],
        capture_output=True, text=True
    )

    if result.returncode != 0:
        print("[-] Derleme hatası:")
        print(result.stderr)
        sys.exit(1)

    ko_path = os.path.join(build_dir, "rulefucker_kernel_advanced.ko")
    if not os.path.exists(ko_path):
        print("[-] .ko dosyası oluşturulamadı.")
        sys.exit(1)

    print("[+] Derleme başarılı.")
    return ko_path


def load_module(ko_path: str, params: dict, hidden: bool = False):
    """Modülü parametrelerle yükle."""
    cmd = ["insmod", ko_path]

    for key, val in params.items():
        cmd.append(f"{key}={val}")

    if hidden:
        cmd.append("hidden=1")

    print(f"[*] Modül yükleniyor: {' '.join(cmd)}")
    result = subprocess.run(cmd, capture_output=True, text=True)

    if result.returncode != 0:
        print(f"[-] Yükleme hatası: {result.stderr}")
        sys.exit(1)

    print("[+] Modül başarıyla yüklendi.")
    print("[*] Doğrulama: uname -a")
    subprocess.run(["uname", "-a"])


def setup_persistence(params: dict, hidden: bool = False):
    """
    Kalıcılık için /etc/modules-load.d/ ve /etc/modprobe.d/ kullan.
    Veya systemd service ile her bootta yeniden yükle.
    """
    module_name = "rulefucker_kernel_advanced"

    # modules-load.d
    modules_load = f"/etc/modules-load.d/{module_name}.conf"
    with open(modules_load, "w") as f:
        f.write(f"# Rulefucker - auto-load at boot\n")
        f.write(f"{module_name}\n")
    print(f"[+] {modules_load} oluşturuldu.")

    # modprobe.d - parametreler
    modprobe_conf = f"/etc/modprobe.d/{module_name}.conf"
    param_str = " ".join(f"{k}={v}" for k, v in params.items())
    if hidden:
        param_str += " hidden=1"

    with open(modprobe_conf, "w") as f:
        f.write(f"# Rulefucker kernel identity parameters\n")
        f.write(f"options {module_name} {param_str}\n")
    print(f"[+] {modprobe_conf} oluşturuldu.")

    # .ko dosyasını /lib/modules/ içine kopyala
    kernel_release = subprocess.run(
        ["uname", "-r"], capture_output=True, text=True
    ).stdout.strip()
    dest_dir = f"/lib/modules/{kernel_release}/extra/"
    os.makedirs(dest_dir, exist_ok=True)

    src_ko = f"{module_name}.ko"
    if os.path.exists(src_ko):
        shutil.copy(src_ko, os.path.join(dest_dir, f"{module_name}.ko"))
        subprocess.run(["depmod", "-a"])
        print(f"[+] {dest_dir} kopyalandı, depmod çalıştırıldı.")
    else:
        print(f"[-] {src_ko} bulunamadı. Kalıcılık için önce modülü yükleyin.")

    print("[+] Kalıcılık kurulumu tamam. Her rebootta modül otomatik yüklenecek.")


def remove_module():
    """Modülü kaldır ve kalıcılık dosyalarını temizle."""
    module_name = "rulefucker_kernel_advanced"

    # Kaldır
    subprocess.run(["rmmod", module_name], capture_output=True)
    print(f"[*] {module_name} kaldırıldı (eğer yüklüyse).")

    # Kalıcılık dosyalarını temizle
    for f in [
        f"/etc/modules-load.d/{module_name}.conf",
        f"/etc/modprobe.d/{module_name}.conf",
    ]:
        if os.path.exists(f):
            os.remove(f)
            print(f"[*] {f} silindi.")

    print("[+] Temizlik tamam.")


def main():
    parser = argparse.ArgumentParser(
        description="Rulefucker Advanced v5.0 - Kernel Identity Mutator"
    )
    parser.add_argument("--sysname", default="RuleOS",
                        help="Kernel sysname (uname -s)")
    parser.add_argument("--nodename", default="",
                        help="Kernel nodename (uname -n), boşsa otomatik alınır")
    parser.add_argument("--release", default="99.0.0-rulefucker",
                        help="Kernel release (uname -r)")
    parser.add_argument("--version", default="#1 SMP PREEMPT RuleFucker 5.0",
                        help="Kernel version (uname -v)")
    parser.add_argument("--machine", default="x86_64",
                        help="Machine arch (uname -m)")
    parser.add_argument("--domain", default="(none)",
                        help="NIS domain name")
    parser.add_argument("--hidden", action="store_true",
                        help="lsmod ve sysfs'ten modülü gizle")
    parser.add_argument("--persist", action="store_true",
                        help="Reboot sonrası da kalıcı yap")
    parser.add_argument("--remove", action="store_true",
                        help="Modülü kaldır ve temizle")

    args = parser.parse_args()

    if args.remove:
        require_root()
        remove_module()
        return

    require_root()

    if not args.nodename:
        args.nodename = subprocess.run(
            ["hostname"], capture_output=True, text=True
        ).stdout.strip()

    params = {
        "sysname": args.sysname,
        "nodename": args.nodename,
        "release": args.release,
        "version": args.version,
        "machine": args.machine,
        "domain": args.domain,
    }

    with tempfile.TemporaryDirectory() as build_dir:
        ko_path = build_module(build_dir)

        # Modülü yükle
        load_module(ko_path, params, hidden=args.hidden)

        # Kalıcılık
        if args.persist:
            ko_name = os.path.basename(ko_path)
            shutil.copy(ko_path, ko_name)
            setup_persistence(params, hidden=args.hidden)

    print("\n[✓] İşlem tamam. uname -a çıktısı değişmiş olmalı.")


if __name__ == "__main__":
    main()
