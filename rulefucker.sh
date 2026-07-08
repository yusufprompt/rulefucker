#!/bin/bash
RED='\033[0;31m'
WHITE='\033[0;37m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Kök kullanıcı (root) kontrolü
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Hata: Rulefucker God Mode sistemin kalbine müdahale eder. Lütfen 'sudo ./rulefucker.sh' şeklinde çalıştırın.${NC}"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PYTHON_CLI="$SCRIPT_DIR/native_manager.py"

# native_manager.py dosyası var mı kontrol et
if [ ! -f "$PYTHON_CLI" ]; then
    echo -e "${RED}Hata: $PYTHON_CLI bulunamadı. Script'in yanında olduğundan emin olun.${NC}"
    exit 1
fi

# Evrensel Paket Yükleme Fonksiyonu
install_package() {
    local pkg=$1
    echo -e "${YELLOW}[+] $pkg paket yöneticisi üzerinden kuruluyor...${NC}"
    
    if command -v apt-get &>/dev/null; then
        apt-get update -y && apt-get install -y "$pkg"
    elif command -v pacman &>/dev/null; then
        pacman -Sy --noconfirm "$pkg"
    elif command -v dnf &>/dev/null; then
        dnf install -y "$pkg"
    else
        echo -e "${RED}Hata: Uygun bir paket yöneticisi bulunamadı. Lütfen $pkg paketini manuel kurun.${NC}"
        exit 1
    fi
}

echo -e "${CYAN}[*] Sistem gereksinimleri kontrol ediliyor...${NC}"

# Temel araçların kontrolü
for cmd in python3 git make gcc; do
    if ! command -v $cmd &>/dev/null; then
        echo -e "${YELLOW}[!] $cmd sistemde bulunamadı.${NC}"
        install_package "$cmd"
    fi
done

# --- OTOMATİK KERNEL HEADERS KONTROLÜ VE KURULUMU ---
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
        exit 1
    fi

    # Arch Linux için senkronizasyon uyarısı
    if [ ! -d "/lib/modules/$(uname -r)/build" ] && command -v pacman &>/dev/null; then
        echo -e "${RED}[!] Dikkat Yustea Bey: Kernel güncellenmiş fakat sistem yeniden başlatılmamış!${NC}"
        echo -e "${YELLOW}Modül derlemek için lütfen sistemi yeniden başlatın (sudo reboot).${NC}"
        read -p "Devam etmek için Enter'a basın (Derleme hata verebilir)..."
    fi
fi

echo -e "${GREEN}[✓] Tüm bağımlılıklar ve derleme ortamı hazır!${NC}"
sleep 1

run_python() {
    python3 "$PYTHON_CLI" "$@"
    local status=$?
    if [ $status -ne 0 ]; then
        echo -e "${RED}Hata: Komut başarısız oldu (çıkış kodu: $status).${NC}"
    fi
    return $status
}

show_menu() {
    clear
    echo -e "${CYAN}======================================================${NC}"
    echo -e "${GREEN}    🚀 RULEFUCKER v4.0 - ULTIMATE SYSTEM MUTATOR 🚀  ${NC}"
    echo -e "${CYAN}======================================================${NC}"
    echo -e "${YELLOW}İnsanları kandırmıyoruz, yükselişlerine basamak ekliyoruz.${NC}"
    echo ""
    echo -e "${GREEN}[ KİMLİK & ARAYÜZ ]${NC}"
    echo "1) Uname Customization (Kernel Hafızasındaki Kimliği Değiştir)"
    echo "2) OS Identity Customization (/etc/os-release Değiştir)"
    echo "3) DE / WM Kurulumu (Distro Bağımsız Evrensel Kurucu)"
    echo ""
    echo -e "${GREEN}[ GOD MODE ARAÇLARI ]${NC}"
    echo "4) Git Install (Herhangi bir Repoyu Otomatik Derle ve Kur)"
    echo "5) Bootloader & Init Manipülasyonu (GRUB Parametresi Ekle)"
    echo "6) MAC Adresi Değiştirme (Ağ Gizliliği)"
    echo "7) Varsayılan Kabuğu (Shell) Değiştirme (Zsh Kontrollü)"
    echo "8) Çıkış"
    echo -e "${CYAN}======================================================${NC}"
}

while true; do
    show_menu
    read -p "Seçiminiz (1-8): " choice
    case $choice in
        1)
            echo -e "\n${CYAN}[ Uname Customization ]${NC}"
            run_python "uname"
            read -p "Devam etmek için Enter'a basın..."
            ;;
        2)
            echo -e "\n${CYAN}[ OS Identity Customization ]${NC}"
            run_python "os"
            read -p "Devam etmek için Enter'a basın..."
            ;;
        3)
            echo -e "\n${CYAN}[ DE / WM Kurulumu ]${NC}"
            read -p "Kurulacak arayüzün adı (Örn: hyprland, xfce): " de_name
            if [ -n "$de_name" ]; then
                run_python "install" "$de_name"
            else
                echo -e "${RED}Arayüz adı boş bırakılamaz.${NC}"
            fi
            read -p "Devam etmek için Enter'a basın..."
            ;;
        4)
            echo -e "\n${CYAN}[ Git Install (Otomatik Derleyici) ]${NC}"
            run_python "git-install"
            read -p "Devam etmek için Enter'a basın..."
            ;;
        5)
            echo -e "\n${CYAN}[ Bootloader & Init Manipülasyonu ]${NC}"
            run_python "boot"
            read -p "Devam etmek için Enter'a basın..."
            ;;
        6)
            echo -e "\n${CYAN}[ MAC Adresi Değiştirme ]${NC}"
            run_python "mac"
            read -p "Devam etmek için Enter'a basın..."
            ;;
        7)
            echo -e "\n${CYAN}[ Kabuk (Shell) Değiştirme ]${NC}"
            # Zsh yükleme kontrolü sadece bu menü seçildiğinde tetiklenir
            if ! command -v zsh &>/dev/null; then
                echo -e "${YELLOW}[!] zsh sistemde bulunamadı. Kabuk menüsü seçildiği için şimdi kuruluyor...${NC}"
                install_package "zsh"
            fi
            run_python "shell"
            read -p "Devam etmek için Enter'a basın..."
            ;;
        8)
            echo -e "${GREEN}Görüşmek üzere Tanrı Modu kapatılıyor...${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Geçersiz seçim. Lütfen 1-8 arası bir değer girin.${NC}"
            sleep 2
            ;;
    esac
done
