#!/bin/bash
#===============================================================================
# RULEFUCKER v5.0 - ULTIMATE SYSTEM MUTATOR (ADVANCED EDITION)
#===============================================================================
# Geliştirilmiş kernel enjeksiyonu, stealth mod, kalıcılık desteği
#===============================================================================

RED='\033[0;31m'
WHITE='\033[0;37m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

#===============================================================================
# KONTROLLER
#===============================================================================

# Root kontrolü
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Hata: Rulefucker God Mode sistemin kalbine müdahale eder. Lütfen 'sudo ./rulefucker.sh' şeklinde çalıştırın.${NC}"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- DOĞRU YOLLAR ---
LOADER="$SCRIPT_DIR/rulefucker_loader.py"
MODULE_SRC="$SCRIPT_DIR/legacy_v2/c_hook/rulefucker_kernel_advanced.c"
MODULE_DIR="$SCRIPT_DIR/legacy_v2/c_hook"

# Gerekli dosyaların varlığını kontrol et
if [ ! -f "$LOADER" ]; then
    echo -e "${YELLOW}[!] rulefucker_loader.py bulunamadı. Ana dizine koymayı unutmayın.${NC}"
fi

if [ ! -f "$MODULE_SRC" ]; then
    echo -e "${YELLOW}[!] $MODULE_SRC bulunamadı.${NC}"
    echo -e "${YELLOW}[!] Dosyayı legacy_v2/c_hook/ dizinine koyun.${NC}"
fi

#===============================================================================
# EVRENSEL PAKET YÜKLEME
#===============================================================================
install_package() {
    local pkg=$1
    echo -e "${YELLOW}[+] $pkg paket yöneticisi üzerinden kuruluyor...${NC}"
    
    if command -v apt-get &>/dev/null; then
        apt-get update -y 2>/dev/null && apt-get install -y "$pkg"
    elif command -v pacman &>/dev/null; then
        pacman -Sy --noconfirm "$pkg"
    elif command -v dnf &>/dev/null; then
        dnf install -y "$pkg"
    else
        echo -e "${RED}Hata: Uygun bir paket yöneticisi bulunamadı. Lütfen $pkg paketini manuel kurun.${NC}"
        return 1
    fi
    return 0
}

#===============================================================================
# BAĞIMLILIK KONTROLÜ
#===============================================================================
check_dependencies() {
    echo -e "${CYAN}[*] Sistem gereksinimleri kontrol ediliyor...${NC}"

    local missing=0
    for cmd in python3 git make gcc; do
        if ! command -v $cmd &>/dev/null; then
            echo -e "${YELLOW}[!] $cmd sistemde bulunamadı.${NC}"
            install_package "$cmd" || missing=1
        fi
    done

    # Kernel headers kontrolü
    if [ ! -d "/lib/modules/$(uname -r)/build" ]; then
        echo -e "${YELLOW}[!] Kernel başlık dosyaları (headers) eksik. Dağıtıma uygun paket otomatik kuruluyor...${NC}"
        
        if command -v pacman &>/dev/null; then
            pacman -Sy --noconfirm linux-headers
        elif command -v apt-get &>/dev/null; then
            apt-get update -y && apt-get install -y linux-headers-$(uname -r)
        elif command -v dnf &>/dev/null; then
            dnf install -y kernel-devel
        else
            echo -e "${RED}Hata: Headers paketi otomatik kurulamadı. Lütfen manuel yükleyin.${NC}"
            return 1
        fi

        # Arch Linux için senkronizasyon uyarısı
        if [ ! -d "/lib/modules/$(uname -r)/build" ] && command -v pacman &>/dev/null; then
            echo -e "${RED}[!] Dikkat: Kernel güncellenmiş fakat sistem yeniden başlatılmamış!${NC}"
            echo -e "${YELLOW}Modül derlemek için lütfen sistemi yeniden başlatın (sudo reboot).${NC}"
            echo -e "${YELLOW}Ya da mevcut kernel ile derlemeyi dene: /lib/modules/$(uname -r)/build${NC}"
            read -p "Devam etmek için Enter'a basın (Derleme hata verebilir)..."
        fi
    fi

    if [ $missing -eq 0 ]; then
        echo -e "${GREEN}[✓] Tüm bağımlılıklar ve derleme ortamı hazır!${NC}"
    else
        echo -e "${RED}[!] Bazı bağımlılıklar kurulamadı. İşlemler sınırlı olabilir.${NC}"
    fi
    sleep 1
}

#===============================================================================
# MANUEL DERLEME (Loader olmadan direkt)
#===============================================================================
build_and_load_module_direct() {
    echo -e "\n${CYAN}═══════════════════════════════════════════${NC}"
    echo -e "${GREEN}  MANUEL KERNEL MODÜLÜ DERLEME & YÜKLEME${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════${NC}"
    echo ""

    if [ ! -f "$MODULE_SRC" ]; then
        echo -e "${RED}Hata: $MODULE_SRC bulunamadı.${NC}"
        echo -e "${YELLOW}Dosyayı şuraya koy: $MODULE_DIR/rulefucker_kernel_advanced.c${NC}"
        return 1
    fi

    # Parametreleri al
    read -p "$(echo -e $CYAN"Sysname"$NC" (uname -s): " )" inp_sysname
    inp_sysname=${inp_sysname:-RuleOS}
    read -p "$(echo -e $CYAN"Nodename"$NC" (uname -n, boş=hostname): " )" inp_nodename
    [ -z "$inp_nodename" ] && inp_nodename="$(hostname)"
    read -p "$(echo -e $CYAN"Release"$NC" (uname -r): " )" inp_release
    inp_release=${inp_release:-99.0.0-rule}
    read -p "$(echo -e $CYAN"Version"$NC" (uname -v): " )" inp_version
    inp_version=${inp_version:-"#1 SMP PREEMPT RuleFucker"}
    read -p "$(echo -e $CYAN"Machine"$NC" (uname -m, boş=x86_64): " )" inp_machine
    inp_machine=${inp_machine:-x86_64}
    read -p "$(echo -e $CYAN"Domain"$NC" (NIS domain): " )" inp_domain
    inp_domain=${inp_domain:-"(none)"}

    echo ""
    read -p "$(echo -e $CYAN"Modül gizli mi olsun? (E/h): " )" inp_hidden
    local hidden_flag=""
    [[ "$inp_hidden" =~ ^[Ee]$ ]] && hidden_flag="hidden=1"

    echo ""
    echo -e "${BLUE}[*] Parametreler:${NC}"
    echo "  sysname=$inp_sysname  nodename=$inp_nodename"
    echo "  release=$inp_release  version=$inp_version"
    echo "  machine=$inp_machine  domain=$inp_domain"
    echo "  hidden=${hidden_flag:-"0"}"
    echo ""

    read -p "Onaylıyor musun? (E/h): " confirm
    confirm=${confirm:-E}
    [[ ! "$confirm" =~ ^[Ee]$ ]] && { echo -e "${YELLOW}İptal.${NC}"; return; }

    # Makefile'ı oluştur (eğer yoksa)
    local makefile_path="$MODULE_DIR/Makefile"
    if [ ! -f "$makefile_path" ]; then
        cat > "$makefile_path" << 'MAKEEOF'
CC = gcc
CFLAGS = -Wall -fPIC -shared
LDFLAGS = -ldl
TARGET = rulefucker.so

all: $(TARGET)

$(TARGET): rulefucker.c
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)

rulefucker_kernel_advanced.ko: rulefucker_kernel_advanced.c
	make -C /lib/modules/$(shell uname -r)/build M=$(PWD) modules

clean:
	rm -f $(TARGET) *.o *.ko *.mod* Module.symvers modules.order
MAKEEOF
        echo -e "${GREEN}[✓] Makefile oluşturuldu: $makefile_path${NC}"
    fi

    # Derle
    echo -e "${YELLOW}[*] Kernel modülü derleniyor...${NC}"
    cd "$MODULE_DIR" || return
    make rulefucker_kernel_advanced.ko 2>&1 | tail -20

    local ko_path="$MODULE_DIR/rulefucker_kernel_advanced.ko"
    if [ ! -f "$ko_path" ]; then
        echo -e "${RED}[!] Derleme başarısız!${NC}"
        echo -e "${YELLOW}Muhtemel sebep: Kernel headers uyumsuz veya reboot gerekli.${NC}"
        echo -e "${YELLOW}Mevcut kernel: $(uname -r)${NC}"
        echo -e "${YELLOW}Headers: $(pacman -Q linux-headers 2>/dev/null)${NC}"
        cd "$SCRIPT_DIR"
        return 1
    fi
    echo -e "${GREEN}[✓] Derleme başarılı: $ko_path${NC}"

    # Yükle
    echo -e "${YELLOW}[*] Modül yükleniyor...${NC}"
    local cmd="insmod $ko_path sysname=\"$inp_sysname\" nodename=\"$inp_nodename\" release=\"$inp_release\" version=\"$inp_version\" machine=\"$inp_machine\" domain=\"$inp_domain\" $hidden_flag"
    echo -e "${BLUE}  $cmd${NC}"
    eval "$cmd" 2>&1
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}[✓] Modül başarıyla yüklendi!${NC}"
        echo -e "${GREEN}[✓] uname -a: $(uname -a)${NC}"
    else
        echo -e "${RED}[!] Yükleme başarısız. dmesg kontrol et.${NC}"
        dmesg | tail -5
    fi

    cd "$SCRIPT_DIR"
}

#===============================================================================
# KERNEL DURUMUNU GÖSTER
#===============================================================================
show_kernel_status() {
    echo -e "\n${CYAN}═══════════════════════════════════════════${NC}"
    echo -e "${GREEN}  MEVCUT KERNEL KİMLİK DURUMU${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════${NC}"
    echo -e "${YELLOW}uname -a:${NC}  $(uname -a 2>/dev/null || echo 'Bilinmiyor')"
    echo -e "${YELLOW}uname -s:${NC}  $(uname -s)"
    echo -e "${YELLOW}uname -n:${NC}  $(uname -n)"
    echo -e "${YELLOW}uname -r:${NC}  $(uname -r)"
    echo -e "${YELLOW}uname -v:${NC}  $(uname -v)"
    echo -e "${YELLOW}uname -m:${NC}  $(uname -m)"
    
    if lsmod | grep -q "rulefucker_kernel_advanced"; then
        echo -e "${GREEN}[✓] Rulefucker kernel modülü: YÜKLÜ${NC}"
        [ -f /proc/rulefucker ] && echo -e "${YELLOW}/proc/rulefucker:${NC}" && cat /proc/rulefucker 2>/dev/null | sed 's/^/  /'
    elif lsmod | grep -q "rulefucker_kernel"; then
        echo -e "${GREEN}[✓] Rulefucker kernel modülü (legacy): YÜKLÜ${NC}"
    else
        echo -e "${RED}[✗] Rulefucker kernel modülü: YÜKLÜ DEĞİL${NC}"
    fi
    echo ""
}

#===============================================================================
# MODÜLÜ KALDIR
#===============================================================================
menu_kernel_remove() {
    echo -e "\n${CYAN}═══════════════════════════════════════════${NC}"
    echo -e "${RED}  KERNEL MODÜLÜNÜ KALDIR${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════${NC}"
    echo ""
    
    local module_name=""
    lsmod | grep "rulefucker_kernel_advanced" &>/dev/null && module_name="rulefucker_kernel_advanced"
    lsmod | grep "rulefucker_kernel" &>/dev/null && module_name="rulefucker_kernel"
    
    if [ -z "$module_name" ]; then
        echo -e "${YELLOW}[!] Yüklü rulefucker modülü bulunamadı.${NC}"
        return
    fi
    
    echo -e "Modül: ${CYAN}$module_name${NC}"
    read -p "Kaldırılsın mı? (e/H): " confirm
    if [[ "$confirm" =~ ^[Ee]$ ]]; then
        rmmod "$module_name" 2>/dev/null
        echo -e "${GREEN}[✓] $module_name kaldırıldı.${NC}"
    fi
}

#===============================================================================
# MENÜ EKRANI
#===============================================================================
show_menu() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}  ${GREEN}${BOLD}🚀 RULEFUCKER v5.0 - ADVANCED EDITION 🚀${NC}        ${CYAN}║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC}  ${YELLOW}İnsanları kandırmıyoruz, yükselişlerine basamak ekliyoruz.${NC}  ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════╝${NC}"
    echo ""

    # Kernel durum özeti
    if lsmod | grep -q "rulefucker_kernel_advanced"; then
        echo -e "  ${GREEN}[●] Kernel Modül (Advanced): AKTİF${NC}"
    elif lsmod | grep -q "rulefucker_kernel"; then
        echo -e "  ${GREEN}[●] Kernel Modül (Legacy): AKTİF${NC}"
    else
        echo -e "  ${RED}[○] Kernel Modül: YÜKLÜ DEĞİL${NC}"
    fi
    
    # LD_PRELOAD durumu
    if [ -n "$LD_PRELOAD" ] && echo "$LD_PRELOAD" | grep -qi "rulefucker"; then
        echo -e "  ${GREEN}[●] LD_PRELOAD Hook: AKTİF${NC}"
    fi
    echo ""

    echo -e "  ${GREEN}${BOLD}[ KERNEL & SİSTEM KİMLİĞİ ]${NC}"
    echo "   1)  Kernel Enjeksiyonu (Derle + Yükle - Advanced LKM)"
    echo "   2)  Kernel Modülünü Kaldır"
    echo "   3)  Kernel Durumunu Göster"
    echo ""
    echo -e "  ${GREEN}${BOLD}[ DİĞER ARAÇLAR ]${NC}"
    echo "   4)  OS Identity (/etc/os-release değiştir)"
    echo "   5)  OS Identity Geri Yükle"
    echo "   6)  Bootloader & Init Manipülasyonu"
    echo "   7)  MAC Adresi Değiştir"
    echo "   8)  Shell Değiştir"
    echo "   9)  Git Install (Otomatik Derleyici)"
    echo ""
    echo "   0)  Çıkış"
    echo -e "${CYAN}────────────────────────────────────────────${NC}"
}

#===============================================================================
# ANA DÖNGÜ
#===============================================================================

# İlk başta bağımlılıkları kontrol et
check_dependencies

while true; do
    show_menu
    read -p "$(echo -e $CYAN"Seçiminiz"$NC" (0-9): " )" choice

    case $choice in
        1)
            build_and_load_module_direct
            read -p "Devam etmek için Enter'a basın..."
            ;;
        2)
            menu_kernel_remove
            read -p "Devam etmek için Enter'a basın..."
            ;;
        3)
            show_kernel_status
            read -p "Devam etmek için Enter'a basın..."
            ;;
        4)
            echo -e "\n${CYAN}[ OS Identity Değiştir ]${NC}"
            read -p "Yeni OS adı (örn: Kali Linux): " os_name
            os_name=${os_name:-"Kali Linux"}
            read -p "Yeni ID (örn: kali): " os_id
            os_id=${os_id:-kali}
            [ -f /etc/os-release ] && cp /etc/os-release /etc/os-release.rulefucker.bak 2>/dev/null
            cat > /etc/os-release <<-EOF
NAME="${os_name}"
ID=${os_id}
VERSION="99.0"
PRETTY_NAME="${os_name} 99.0 (Rulefucker)"
VERSION_ID="99.0"
HOME_URL="https://rulefucker.local"
EOF
            echo -e "${GREEN}[✓] /etc/os-release değiştirildi${NC}"
            read -p "Devam etmek için Enter'a basın..."
            ;;
        5)
            if [ -f /etc/os-release.rulefucker.bak ]; then
                cp /etc/os-release.rulefucker.bak /etc/os-release
                echo -e "${GREEN}[✓] Orijinal geri yüklendi${NC}"
            else
                echo -e "${RED}[!] Yedek bulunamadı${NC}"
            fi
            read -p "Devam etmek için Enter'a basın..."
            ;;
        6)
            echo -e "\n${CYAN}[ Bootloader Manipülasyonu ]${NC}"
            echo "  1) init=/bin/bash"
            echo "  2) quiet"
            echo "  3) single"
            echo "  4) systemd.unit=emergency"
            echo "  5) rd.break"
            echo "  6) Kendi parametrem"
            read -p "Seçim (1-6): " bc
            param=""
            case $bc in 1) param="init=/bin/bash" ;; 2) param="quiet" ;; 3) param="single" ;; 4) param="systemd.unit=emergency" ;; 5) param="rd.break" ;; 6) read -p "Parametre: " param ;; esac
            if [ -n "$param" ] && [ -f /etc/default/grub ]; then
                cp /etc/default/grub /etc/default/grub.rulefucker.bak 2>/dev/null
                current=$(grep "^GRUB_CMDLINE_LINUX_DEFAULT=" /etc/default/grub | sed 's/GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"/\1/')
                sed -i "s|^GRUB_CMDLINE_LINUX_DEFAULT=.*|GRUB_CMDLINE_LINUX_DEFAULT=\"$current $param\"|" /etc/default/grub
                echo -e "${GREEN}[✓] Parametre eklendi: $param${NC}"
                command -v update-grub &>/dev/null && update-grub
                command -v grub-mkconfig &>/dev/null && grub-mkconfig -o /boot/grub/grub.cfg
            fi
            read -p "Devam etmek için Enter'a basın..."
            ;;
        7)
            echo -e "\n${CYAN}[ MAC Adresi Değiştir ]${NC}"
            ip -o link show | awk -F': ' '{print $2}' | sed 's/@.*//'
            read -p "Arayüz: " iface
            [ -z "$iface" ] && { echo -e "${RED}Arayüz gerekli${NC}"; read -p "Enter..."; continue; }
            rand_mac=$(printf '02:%02x:%02x:%02x:%02x:%02x' $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256)))
            read -p "MAC (boş=rastgele $rand_mac): " new_mac
            new_mac=${new_mac:-$rand_mac}
            ip link set dev "$iface" down && ip link set dev "$iface" address "$new_mac" && ip link set dev "$iface" up
            echo -e "${GREEN}[✓] MAC değiştirildi: $new_mac${NC}"
            read -p "Devam etmek için Enter'a basın..."
            ;;
        8)
            echo -e "\n${CYAN}[ Shell Değiştir ]${NC}"
            cat /etc/shells 2>/dev/null
            read -p "Kullanıcı (boş=root): " suser
            suser=${suser:-root}
            read -p "Shell yolu (örn: /bin/zsh): " spath
            [ -n "$spath" ] && chsh -s "$spath" "$suser" && echo -e "${GREEN}[✓] Shell değiştirildi${NC}"
            read -p "Devam etmek için Enter'a basın..."
            ;;
        9)
            echo -e "\n${CYAN}[ Git Install ]${NC}"
            read -p "Repo URL: " repourl
            if [ -n "$repourl" ]; then
                bd="/tmp/rulefucker_build_$$"
                git clone "$repourl" "$bd" 2>/dev/null && cd "$bd" || continue
                [ -f Cargo.toml ] && cargo install --path .
                [ -f CMakeLists.txt ] && { mkdir -p build && cd build && cmake .. && make -j$(nproc) && make install; cd ..; }
                [ -f configure ] && { ./configure && make -j$(nproc) && make install; }
                [ -f Makefile ] && make -j$(nproc) && make install
                [ -f setup.py ] && python3 setup.py install
                cd "$SCRIPT_DIR"
                rm -rf "$bd"
                echo -e "${GREEN}[✓] Kurulum tamam${NC}"
            fi
            read -p "Devam etmek için Enter'a basın..."
            ;;
        0)
            echo -e "${GREEN}Görüşmek üzere Tanrı Modu kapatılıyor...${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Geçersiz seçim.${NC}"
            sleep 2
            ;;
    esac
done
