# 🚀 Rulefucker v3.0

**Rulefucker**, Linux sisteminizin kimliğini (İşletim sistemi adı, Kernel bilgileri, Masaüstü ortamı vb.) **gerçekten** ve **kalıcı** olarak değiştiren (spoofing değil, mutasyon) güçlü bir sistem özelleştiricisidir. İnsanları kandırmaz, onların yükselişine basamak ekler!

LD_PRELOAD gibi geçici kancalar (hook) kullanmak yerine, doğrudan çekirdeğe (Kernel) modül yükleyerek hafızadaki bilgileri ezer ve sistemin her yerinde (başlangıç komut dosyalarından neofetch'e kadar) değişikliğin geçerli olmasını sağlar. Ayrıca distrolardan (Debian, Arch, Fedora) bağımsız olarak çalışır ve istediğiniz masaüstü ortamını kurabilir.

## ⚠️ Uyarı
Bu araç sistem dosyalarına (`/etc/os-release` vb.) doğrudan müdahale eder ve çekirdek modülü yükler. Her zaman **root (`sudo`)** yetkisi ile çalıştırılmalıdır. Sorumluluk kullanıcıya aittir.

## 🛠️ Kurulum
Bu araç bağımsız Python ve C dosyalarından oluşmaktadır. Herhangi bir derleme işlemine gerek yoktur, araç modülü kendisi derler (ancak sisteminizde `linux-headers` yüklü olmalıdır).

```bash
cd /path/to/rulefucker
chmod +x native_manager.py
sudo ln -sf native_manager.py /usr/local/bin/rulefucker
```

## 📚 Kullanım (Komutlar)

Rulefucker komutlarını terminalden interaktif veya argüman vererek kullanabilirsiniz.

### 1. Kernel (Uname) Değiştirme
Kernelin kendini nasıl tanıttığını değiştirmek için:
```bash
sudo ./rulefucker uname
```
*(Bu komut argümansız çalıştırıldığında size `Sysname ne olsun?`, `Nodename ne olsun?` gibi sorular sorarak interaktif bir deneyim sunar.)*

Alternatif olarak, doğrudan komut satırından da verebilirsiniz:
```bash
sudo ./rulefucker uname --sysname "RuleOS" --nodename "god-pc" --release "99.0.1"
```

### 2. İşletim Sistemi Kimliğini Değiştirme
`/etc/os-release` dosyasını kalıcı olarak değiştirip sisteminizin adını belirlemek için:
```bash
sudo ./rulefucker os --name "RuleOS" --id "ruleos"
```

### 3. Evrensel Masaüstü Ortamı (DE) Kurucu
Rulefucker, sisteminizin paket yöneticisini (`apt`, `pacman`, `dnf` vb.) otomatik algılar ve istediğiniz ortamı anında kurar.
```bash
sudo ./rulefucker install hyprland
sudo ./rulefucker install xfce
```

## ⚙️ Teknik Altyapı
- **LKM (Loadable Kernel Module):** `uname` sistem çağrısı değerlerini doğrudan kernel hafızasından (`init_uts_ns`) değiştirir.
- **Python CLI:** Kurulum, yedekleme (`.bak` oluşturma) ve yapılandırmaları otomatik yönetir.

---
*İnsanların yükselişine bir basamak.*
