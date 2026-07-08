# 🚀 Rulefucker v4.0 - Ultimate System Mutator (God Mode)

**Rulefucker**, Linux sisteminizin kimliğini ve temel yapıtaşlarını **gerçekten** ve **kalıcı** olarak değiştiren (spoofing değil, mutasyon) "Tanrı Modu" özelliklerine sahip güçlü bir sistem evrim aracıdır. İnsanları kandırmaz, onların yükselişine basamak ekler!

## ⚠️ Dikkat: Tanrı Modu
Bu sürüm, sistemin bootloader (GRUB), init parametreleri, ağ (MAC adresi) ve çekirdek (Kernel) hafızası gibi en kritik ve tehlikeli bölgelerine müdahale etme yeteneğine sahiptir. Her zaman **root (`sudo`)** yetkisi ile çalıştırılmalıdır. Sorumluluk tamamen kullanıcıya aittir.

## 🛠️ Kurulum
GCC ve Make gereklidir
Herhangi bir manuel derlemeye gerek yoktur, araç bağımlılıkları kendisi yönetir.
```bash
cd /path/to/rulefucker
chmod +x native_manager.py rulefucker.sh
```

## 📚 Kullanım ve Özellikler

En kolay ve interaktif kullanım için hazırlanan ana menüyü başlatmanız yeterlidir:
```bash
sudo ./rulefucker.sh
```

Menüden yapabileceğiniz işlemler:

### 1. Kimlik ve Arayüz (Identity & UI)
- **Uname Değiştirici:** Linux Çekirdeğine (Kernel) bir modül enjekte ederek hafızadaki kimliğini (Sysname, Release vb.) anında ve kalıcı ezer.
- **OS Identity:** `/etc/os-release` dosyasını otomatik yedekler ve sisteminizi istediğiniz isimle yeniden yapılandırır.
- **DE/WM Evrensel Kurucu:** Sisteminizi otomatik tarar (`apt`, `pacman`, `dnf` vb. hangisi kullanılıyorsa bulur) ve belirttiğiniz masaüstü ortamını (örn. Hyprland) anında kurar (ek özellikleri isteğe bağlı kurar ve kurulumda sana bunları sorar).

### 2. God Mode Araçları
- **Git Install (Otomatik Derleyici):** Sadece Github/Gitlab linkini verin. Araç depoyu klonlar, içindeki `Makefile`, `CMake`, `Cargo` veya `Autotools` altyapısını otomatik algılar, derler ve sisteme kurar.
- **Bootloader & Init Manipülasyonu:** `/etc/default/grub` dosyasına doğrudan müdahale ederek bir sonraki başlatmada geçerli olacak `init=/bin/bash` veya `quiet` gibi kernel parametreleri ekler.
- **MAC Adresi Yöneticisi:** Ağ kartınızın donanım adresini (MAC) saniyeler içinde gizlilik amacıyla değiştirir.
- **Kabuk (Shell) Evrimi:** Sistemin varsayılan terminal kabuğunu (örn. `bash`'ten `zsh`'e) kalıcı olarak değiştirir.
- **Ses Servisi Değişimi:** Sistemdeki  Kullanılan Ses Servisini (örnek pipewire) Servisini İstenilen Ses Servisi (örnek PulseAudio) Servisi olarak değiştirir.

---
*İnsanların yükselişine bir basamak.*
