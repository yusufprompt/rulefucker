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
LOADER="$SCRIPT_DIR/rulefucker_loader.py"
MODULE_SRC="$SCRIPT_DIR/rulefucker_kernel_advanced.c"

# Gerekli dosyaların varlığını kontrol et
if [ ! -f "$LOADER" ]; then
    echo -e "${YELLOW}[!] rulefucker_loader.py bulunamadı. Kernel enjeksiyonu devre dışı.${NC}"
    echo -e "${YELLOW}[!} Sadece sistem kimliği ve yardımcı araçlar kullanılabilir.${NC}"
fi

if [ ! -f "$MODULE_SRC" ]; then
    echo -e "${YELLOW}[!] rulefucker_kernel_advanced.c bulunamadı. Kernel modül derlenemeyecek.${NC}"
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
# KERNEL MODÜLÜ YÜKLEME/KALDIRMA
#===============================================================================
run_loader() {
    if [ ! -f "$LOADER" ]; then
        echo -e "${RED}Hata: rulefucker_loader.py bulunamadı.${NC}"
        return 1
    fi
    python3 "$LOADER" "$@"
    local status=$?
    if [ $status -ne 0 ]; then
        echo -e "${RED}Hata: Komut başarısız oldu (çıkış kodu: $status).${NC}"
    fi
    return $status
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
    
    # Modül yüklü mü kontrol et
    if lsmod | grep -q "rulefucker_kernel_advanced"; then
        echo -e "${GREEN}[✓] Rulefucker kernel modülü: YÜKLÜ${NC}"
        if [ -f /proc/rulefucker ]; then
            echo -e "${YELLOW}/proc/rulefucker:${NC}"
            cat /proc/rulefucker 2>/dev/null | sed 's/^/  /'
        fi
    elif lsmod | grep -q "rulefucker_kernel"; then
        echo -e "${GREEN}[✓] Rulefucker kernel modülü (legacy): YÜKLÜ${NC}"
    else
        echo -e "${RED}[✗] Rulefucker kernel modülü: YÜKLÜ DEĞİL${NC}"
    fi
    echo ""
}

#===============================================================================
# INTERAKTİF MENÜ FONKSİYONLARI
#===============================================================================

# 1) Gelişmiş Kernel Enjeksiyonu
menu_kernel_inject() {
    echo -e "\n${CYAN}═══════════════════════════════════════════${NC}"
    echo -e "${GREEN}  GELİŞMİŞ KERNEL ENJEKSİYONU${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════${NC}"
    echo ""
    echo -e "${YELLOW}Not: Modül yüklendiğinde uname çıktısı anında değişir.${NC}"
    echo -e "${YELLOW}Reboot sonrası da kalıcı olması için 'Kalıcılık' seçeneğini kullanın.${NC}"
    echo ""

    # Parametreleri al
    read -p "$(echo -e $CYAN"Sysname"$NC" (uname -s, örn: PentestOS): " )" inp_sysname
    inp_sysname=${inp_sysname:-PentestOS}

    read -p "$(echo -e $CYAN"Nodename"$NC" (uname -n, boş=hostname): " )" inp_nodename
    [ -z "$inp_nodename" ] && inp_nodename="$(hostname)"

    read -p "$(echo -e $CYAN"Release"$NC" (uname -r, örn: 99.0.0-pentest): " )" inp_release
    inp_release=${inp_release:-99.0.0-pentest}

    read -p "$(echo -e $CYAN"Version"$NC" (uname -v, örn: #1 SMP RuleFucker): " )" inp_version
    inp_version=${inp_version:-"#1 SMP PREEMPT RuleFucker 5.0"}

    read -p "$(echo -e $CYAN"Machine"$NC" (uname -m, örn: x86_64): " )" inp_machine
    inp_machine=${inp_machine:-x86_64}

    read -p "$(echo -e $CYAN"Domain"$NC" (NIS domain, örn: (none)): " )" inp_domain
    inp_domain=${inp_domain:-"(none)"}

    echo ""
    echo -e "${YELLOW}Stealth Mod Seçenekleri:${NC}"
    echo "  1) Normal - Modül lsmod ile görünür"
    echo "  2) Gizli - Modül lsmod ve sysfs'ten gizlenir"
    read -p "Seçiminiz (1/2, varsayılan: 1): " stealth_choice
    local hidden_flag=""
    [ "$stealth_choice" = "2" ] && hidden_flag="--hidden"

    echo ""
    echo -e "${YELLOW}Kalıcılık:${NC}"
    echo "  1) Sadece şimdilik (reboot sonrası kaybolur)"
    echo "  2) Kalıcı olsun (reboot sonrası da yüklensin)"
    read -p "Seçiminiz (1/2, varsayılan: 1): " persist_choice
    local persist_flag=""
    [ "$persist_choice" = "2" ] && persist_flag="--persist"

    echo ""
    echo -e "${BLUE}[*] Parametre özeti:${NC}"
    echo "  sysname : $inp_sysname"
    echo "  nodename: $inp_nodename"
    echo "  release : $inp_release"
    echo "  version : $inp_version"
    echo "  machine : $inp_machine"
    echo "  domain  : $inp_domain"
    echo "  hidden  : $([ -n "$hidden_flag" ] && echo "EVET" || echo "HAYIR")"
    echo "  persist : $([ -n "$persist_flag" ] && echo "EVET" || echo "HAYIR")"
    echo ""

    read -p "Onaylıyor musunuz? (E/h): " confirm
    confirm=${confirm:-E}
    if [[ "$confirm" =~ ^[Ee]$ ]]; then
        run_loader \
            --sysname "$inp_sysname" \
            --nodename "$inp_nodename" \
            --release "$inp_release" \
            --version "$inp_version" \
            --machine "$inp_machine" \
            --domain "$inp_domain" \
            $hidden_flag \
            $persist_flag
    else
        echo -e "${YELLOW}İşlem iptal edildi.${NC}"
    fi
}

# 2) Modül Kaldırma
menu_kernel_remove() {
    echo -e "\n${CYAN}═══════════════════════════════════════════${NC}"
    echo -e "${RED}  KERNEL MODÜLÜNÜ KALDIR${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════${NC}"
    echo ""
    echo -e "${YELLOW}Bu işlem:${NC}"
    echo "  - Kernel modülünü kaldırır (rmmod)"
    echo "  - Kalıcılık dosyalarını temizler (/etc/modules-load.d, /etc/modprobe.d)"
    echo "  - NOT: uname değişiklikleri reboot'a kadar kalır"
    echo ""
    read -p "Devam etmek istiyor musunuz? (e/H): " confirm
    if [[ "$confirm" =~ ^[Ee]$ ]]; then
        run_loader --remove
        echo -e "${GREEN}[✓] Modül kaldırma işlemi tamamlandı.${NC}"
    else
        echo -e "${YELLOW}İşlem iptal edildi.${NC}"
    fi
}

# 3) OS Identity
menu_os_identity() {
    echo -e "\n${CYAN}═══════════════════════════════════════════${NC}"
    echo -e "${GREEN}  OS KİMLİK ÖZELLEŞTİRME${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════${NC}"
    echo ""

    # Mevcut durumu göster
    if [ -f /etc/os-release ]; then
        echo -e "${YELLOW}Mevcut /etc/os-release:${NC}"
        grep -E "^(NAME|ID|VERSION|PRETTY_NAME)=" /etc/os-release 2>/dev/null | sed 's/^/  /'
    fi

    echo ""
    read -p "Yeni işletim sistemi adı (NAME, örn: Kali Linux): " os_name
    os_name=${os_name:-"Kali Linux"}

    read -p "Yeni ID (örn: kali): " os_id
    os_id=${os_id:-kali}

    # Yedekle
    if [ -f /etc/os-release ]; then
        cp /etc/os-release /etc/os-release.rulefucker.bak 2>/dev/null
        echo -e "${GREEN}[✓] Orijinal /etc/os-release yedeklendi -> /etc/os-release.rulefucker.bak${NC}"
    fi

    cat > /etc/os-release <<-EOF
NAME="${os_name}"
ID=${os_id}
VERSION="99.0"
PRETTY_NAME="${os_name} 99.0 (Rulefucker)"
VERSION_ID="99.0"
ID_LIKE=""
ANSI_COLOR="38;2;255;0;0"
HOME_URL="https://rulefucker.local"
SUPPORT_URL="https://rulefucker.local/support"
BUG_REPORT_URL="https://rulefucker.local/bugs"
EOF

    echo -e "${GREEN}[✓] /etc/os-release başarıyla değiştirildi!${NC}"
    echo -e "${YELLOW}Yeni OS kimliği:${NC}"
    cat /etc/os-release | head -4 | sed 's/^/  /'
}

# 4) OS Identity Geri Yükle
menu_os_restore() {
    echo -e "\n${CYAN}═══════════════════════════════════════════${NC}"
    echo -e "${GREEN}  ORİJİNAL OS KİMLİĞİNİ GERİ YÜKLE${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════${NC}"
    echo ""

    if [ -f /etc/os-release.rulefucker.bak ]; then
        cp /etc/os-release.rulefucker.bak /etc/os-release
        echo -e "${GREEN}[✓] Orijinal /etc/os-release geri yüklendi.${NC}"
    else
        echo -e "${RED}[!] Yedek dosyası bulunamadı: /etc/os-release.rulefucker.bak${NC}"
    fi
}

# 5) Bootloader Manipülasyonu
menu_bootloader() {
    echo -e "\n${CYAN}═══════════════════════════════════════════${NC}"
    echo -e "${GREEN}  BOOTLOADER & INIT MANİPÜLASYONU${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════${NC}"
    echo ""

    # Bootloader tespiti
    if [ -f /etc/default/grub ]; then
        echo -e "${GREEN}[✓] GRUB tespit edildi.${NC}"
    elif [ -d /boot/loader ]; then
        echo -e "${GREEN}[✓] systemd-boot tespit edildi.${NC}"
    else
        echo -e "${RED}[!] Bilinen bir bootloader bulunamadı.${NC}"
        return
    fi

    echo ""
    echo -e "${YELLOW}Ön Tanımlı Kernel Parametreleri:${NC}"
    echo "  1) init=/bin/bash         (Tek kullanıcı modu bypass)"
    echo "  2) quiet                  (Sessiz boot)"
    echo "  3) single                 (Single user mode)"
    echo "  4) 1                      (Runlevel 1 - kurtarma modu)"
    echo "  5) systemd.unit=emergency (Acil durum shell'i)"
    echo "  6) rd.break               (Initramfs shell)"
    echo "  7) Kendi parametremi gireceğim"
    echo ""
    read -p "Seçiminiz (1-7): " boot_choice

    local param=""
    case $boot_choice in
        1) param="init=/bin/bash" ;;
        2) param="quiet" ;;
        3) param="single" ;;
        4) param="1" ;;
        5) param="systemd.unit=emergency" ;;
        6) param="rd.break" ;;
        7) read -p "Kernel parametresi: " param ;;
        *) echo -e "${RED}Geçersiz seçim.${NC}"; return ;;
    esac

    if [ -z "$param" ]; then
        echo -e "${RED}Parametre boş. İşlem iptal.${NC}"
        return
    fi

    # GRUB düzenleme
    if [ -f /etc/default/grub ]; then
        cp /etc/default/grub /etc/default/grub.rulefucker.bak 2>/dev/null
        echo -e "${GREEN}[✓] /etc/default/grub yedeklendi.${NC}"

        # Mevcut satırı al ve parametre ekle
        local current_line=$(grep "^GRUB_CMDLINE_LINUX_DEFAULT=" /etc/default/grub)
        if [ -n "$current_line" ]; then
            # Tırnak içindeki mevcut parametreleri al
            local current_params=$(echo "$current_line" | sed 's/GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"/\1/')
            local new_params="$current_params $param"
            sed -i "s|^GRUB_CMDLINE_LINUX_DEFAULT=.*|GRUB_CMDLINE_LINUX_DEFAULT=\"$new_params\"|" /etc/default/grub
        else
            echo "GRUB_CMDLINE_LINUX_DEFAULT=\"$param\"" >> /etc/default/grub
        fi

        echo ""
        echo -e "${YELLOW}GRUB güncelleniyor...${NC}"
        if command -v update-grub &>/dev/null; then
            update-grub
        elif command -v grub-mkconfig &>/dev/null; then
            grub-mkconfig -o /boot/grub/grub.cfg
        else
            echo -e "${RED}[!] GRUB config güncelleyici bulunamadı. Manuel çalıştırın.${NC}"
        fi

        echo -e "${GREEN}[✓] '$param' parametresi GRUB_CMDLINE_LINUX_DEFAULT'a eklendi.${NC}"
        echo -e "${YELLOW}Yeni başlatmada aktif olacak.${NC}"
    fi
}

# 6) MAC Adresi Değiştirme
menu_mac_change() {
    echo -e "\n${CYAN}═══════════════════════════════════════════${NC}"
    echo -e "${GREEN}  MAC ADRESİ DEĞİŞTİRME${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════${NC}"
    echo ""

    # Ağ arayüzlerini listele
    echo -e "${YELLOW}Mevcut ağ arayüzleri:${NC}"
    ip -o link show | awk -F': ' '{print $2}' | sed 's/@.*//' | while read iface; do
        mac=$(ip link show "$iface" 2>/dev/null | grep "ether" | awk '{print $2}')
        echo "  $iface  $([ -n "$mac" ] && echo "$mac" || echo "(yok)")"
    done

    echo ""
    read -p "Değiştirilecek arayüz: " iface
    if [ -z "$iface" ]; then
        echo -e "${RED}Arayüz adı gerekli.${NC}"
        return
    fi

    # Rastgele MAC üret
    local rand_mac=$(printf '02:%02x:%02x:%02x:%02x:%02x' $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256)))
    read -p "Yeni MAC (boş=rastgele $rand_mac): " new_mac
    new_mac=${new_mac:-$rand_mac}

    echo ""
    echo -e "${YELLOW}[*] $iface kapatılıyor...${NC}"
    ip link set dev "$iface" down 2>/dev/null || {
        echo -e "${RED}Hata: Arayüz kapatılamadı.${NC}"
        return
    }

    echo -e "${YELLOW}[*] MAC $new_mac olarak değiştiriliyor...${NC}"
    ip link set dev "$iface" address "$new_mac" 2>/dev/null || {
        echo -e "${RED}Hata: MAC değiştirilemedi.${NC}"
        ip link set dev "$iface" up 2>/dev/null
        return
    }

    echo -e "${YELLOW}[*] $iface açılıyor...${NC}"
    ip link set dev "$iface" up 2>/dev/null

    echo -e "${GREEN}[✓] MAC adresi başarıyla $new_mac olarak değiştirildi!${NC}"
}

# 7) Shell Değiştirme
menu_shell_change() {
    echo -e "\n${CYAN}═══════════════════════════════════════════${NC}"
    echo -e "${GREEN}  KABUK (SHELL) DEĞİŞTİRME${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════${NC}"
    echo ""

    echo -e "${YELLOW}Mevcut shell'ler:${NC}"
    cat /etc/shells 2>/dev/null | sed 's/^/  /'

    echo ""
    read -p "Kullanıcı adı (boş=root): " shell_user
    shell_user=${shell_user:-root}

    echo ""
    echo -e "${YELLOW}Seçenekler:${NC}"
    echo "  1) /bin/bash"
    echo "  2) /bin/zsh"
    echo "  3) /bin/fish"
    echo "  4) /bin/sh"
    echo "  5) /bin/dash"
    echo "  6) Kendi shell yolumu gireceğim"
    read -p "Seçiminiz (1-6): " shell_choice

    local shell_path=""
    case $shell_choice in
        1) shell_path="/bin/bash" ;;
        2) shell_path="/bin/zsh" ;;
        3) shell_path="/bin/fish" ;;
        4) shell_path="/bin/sh" ;;
        5) shell_path="/bin/dash" ;;
        6) read -p "Shell yolu (örn: /usr/local/bin/fish): " shell_path ;;
        *) echo -e "${RED}Geçersiz seçim.${NC}"; return ;;
    esac

    if [ ! -f "$shell_path" ]; then
        echo -e "${YELLOW}[!] $shell_path bulunamadı. Kurulum deneniyor...${NC}"
        local pkg_name=$(basename "$shell_path")
        install_package "$pkg_name" || return
    fi

    chsh -s "$shell_path" "$shell_user"
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}[✓] $shell_user kullanıcısının shell'i $shell_path olarak değiştirildi.${NC}"
    else
        echo -e "${RED}[!] Shell değiştirilemedi. $shell_path /etc/shells içinde olmayabilir.${NC}"
        echo -e "${YELLOW}Önce shell'i /etc/shells dosyasına ekleyin.${NC}"
    fi
}

# 8) Git Install
menu_git_install() {
    echo -e "\n${CYAN}═══════════════════════════════════════════${NC}"
    echo -e "${GREEN}  GIT INSTALL (OTOMATİK DERLEYİCİ)${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════${NC}"
    echo ""

    read -p "GitHub/GitLab repo URL'si: " repo_url
    if [ -z "$repo_url" ]; then
        echo -e "${RED}URL gerekli.${NC}"
        return
    fi

    echo -e "${YELLOW}[*] Depo klonlanıyor...${NC}"
    local build_dir="/tmp/rulefucker_build_$$"
    rm -rf "$build_dir"

    git clone "$repo_url" "$build_dir" 2>/dev/null
    if [ $? -ne 0 ]; then
        echo -e "${RED}Hata: Depo klonlanamadı.${NC}"
        return
    fi

    cd "$build_dir" || return

    # Derleme sistemi tespiti
    echo -e "${YELLOW}[*] Derleme sistemi taranıyor...${NC}"

    if [ -f "Cargo.toml" ]; then
        echo -e "${GREEN}[Cargo/Rust] tespit edildi.${NC}"
        cargo install --path .
    elif [ -f "CMakeLists.txt" ]; then
        echo -e "${GREEN}[CMake] tespit edildi.${NC}"
        mkdir -p build && cd build
        cmake .. && make -j$(nproc) && make install
    elif [ -f "configure" ]; then
        echo -e "${GREEN}[Autotools] tespit edildi.${NC}"
        ./configure && make -j$(nproc) && make install
    elif [ -f "Makefile" ] || [ -f "makefile" ]; then
        echo -e "${GREEN}[Make] tespit edildi.${NC}"
        make -j$(nproc) && make install
    elif [ -f "setup.py" ]; then
        echo -e "${GREEN}[Python] tespit edildi.${NC}"
        python3 setup.py install
    elif [ -f "PKGBUILD" ]; then
        echo -e "${GREEN}[PKGBUILD/Arch] tespit edildi.${NC}"
        makepkg -si --noconfirm
    else
        echo -e "${RED}Bilinen bir derleme sistemi tespit edilemedi.${NC}"
        echo -e "${YELLOW}Depo şuraya klonlandı: $build_dir${NC}"
        return
    fi

    echo -e "${GREEN}[✓] Kurulum tamamlandı!${NC}"
    cd "$SCRIPT_DIR" 2>/dev/null
    rm -rf "$build_dir" 2>/dev/null
}

# 9) Durum Göster
menu_status() {
    show_kernel_status
    echo ""
    echo -e "${YELLOW}Modül yüklü mü:${NC}"
    if lsmod | grep -q "rulefucker"; then
        lsmod | grep "rulefucker" | sed 's/^/  /'
    else
        echo "  (yok)"
    fi
    echo ""
    echo -e "${YELLOW}OS Release:${NC}"
    cat /etc/os-release 2>/dev/null | sed 's/^/  /'
    echo ""
    echo -e "${YELLOW}Bootloader:${NC}"
    if [ -f /etc/default/grub ]; then
        grep "^GRUB_CMDLINE_LINUX_DEFAULT=" /etc/default/grub | sed 's/^/  /'
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
        echo -e "  ${GREEN}[●] Kernel Modül: AKTİF${NC}"
    elif lsmod | grep -q "rulefucker_kernel"; then
        echo -e "  ${GREEN}[●] Kernel Modül (Legacy): AKTİF${NC}"
    else
        echo -e "  ${RED}[○] Kernel Modül: YÜKLÜ DEĞİL${NC}"
    fi
    echo ""

    echo -e "  ${GREEN}${BOLD}[ KERNEL & SİSTEM KİMLİĞİ ]${NC}"
    echo "   1)  Kernel Enjeksiyonu (Gelişmiş - uname değiştir)"
    echo "   2)  Kernel Modülünü Kaldır & Temizle"
    echo "   3)  OS Identity (/etc/os-release değiştir)"
    echo "   4)  OS Identity Geri Yükle"
    echo ""
    echo -e "  ${GREEN}${BOLD}[ GOD MODE ARAÇLARI ]${NC}"
    echo "   5)  Bootloader & Init Manipülasyonu"
    echo "   6)  MAC Adresi Değiştir"
    echo "   7)  Varsayılan Kabuğu (Shell) Değiştir"
    echo "   8)  Git Install (Otomatik Derleyici/Kurucu)"
    echo ""
    echo -e "  ${GREEN}${BOLD}[ DURUM & ÇIKIŞ ]${NC}"
    echo "   9)  Sistem Durumunu Göster"
    echo "   0)  Çıkış"
    echo ""
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
            menu_kernel_inject
            read -p "Devam etmek için Enter'a basın..."
            ;;
        2)
            menu_kernel_remove
            read -p "Devam etmek için Enter'a basın..."
            ;;
        3)
            menu_os_identity
            read -p "Devam etmek için Enter'a basın..."
            ;;
        4)
            menu_os_restore
            read -p "Devam etmek için Enter'a basın..."
            ;;
        5)
            menu_bootloader
            read -p "Devam etmek için Enter'a basın..."
            ;;
        6)
            menu_mac_change
            read -p "Devam etmek için Enter'a basın..."
            ;;
        7)
            menu_shell_change
            read -p "Devam etmek için Enter'a basın..."
            ;;
        8)
            menu_git_install
            read -p "Devam etmek için Enter'a basın..."
            ;;
        9)
            menu_status
            read -p "Devam etmek için Enter'a basın..."
            ;;
        0)
            echo -e "${GREEN}"
            echo "  ╔══════════════════════════════════╗"
            echo "  ║  Görüşmek üzere Tanrı Modu       ║"
            echo "  ║  kapatılıyor...                   ║"
            echo "  ╚══════════════════════════════════╝"
            echo -e "${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Geçersiz seçim. Lütfen 0-9 arası bir değer girin.${NC}"
            sleep 2
            ;;
    esac
done
