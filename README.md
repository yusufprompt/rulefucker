<img width="220" height="220" alt="laptop-hacking" src="https://github.com/user-attachments/assets/610d7b4f-1ff7-4729-b183-4c1caeb2b2cf" />
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


##  🔥 Aradığın Paketi Bulma 

Aradığınız Bir Paket Var Fakat Bulamıyorsunuz Çok karmaşık şeyler le de uğraşmak **İstemiyorsunuz** İşte tam Burda Bu Script Size Yardım ediyor 
İstediğin Paketi Arayın Biraz Bekleyin Ve **BOM!** İstediğiniz Paketi Buldunuz!

### ❓ Nasıl Çalışıyor?
Bu Script **if** mantığı ile çalışıyor:

- **İşletim Sistemi Tespit Etme**: Kullandığınız İşletim Sistemini(Arch,Fedora,Ubuntu/Debian,NixOS vb.) Algılar.
- **Yapay Zeka Destekli Sorgulama**:
İstediğiniz Paketı Yazdığınızda Paketi **SwoxAI** ya İletir ve Cevap Bekler. SwoxAI Cevap Verdiğinde Cevabı Kullanıcıya İletir.
- **Doğrulama**:
Paketi Kullanıcıya sorar (Paket Bu mu?<y-n>) Kullanıcı Eyer **Y** derse Paketi İşletim Sistemine göre İndirir.
Eyer N derse Paketi Bulana Kadar sorgular Kullanıcıya sorar AI ya iletir.
- **NixOS Kullanıcıları İçin**
Biliyorsunuzki Nix Kullanıcıları Paketleri Paket Yöneticisi İle indirmez Onun Yerine **configuration.nix** adlı dosyayi değiştirip **nixos-rebuild switch** İle Sistemi inşa edip O Paketi Kurar
Peki Bu Script Nasıl indiriyor? Kullanıcı Onay verdiğinde EDITOR ile 
'environment.systemPackages' Kısmının en Altına O Paketi **Ekler** ve Kaydet Ve çık Yapıp sudo nixos-rebuild switch Komutunu Çalıştırır 
---
*İnsanların yükselişine bir basamak.*
