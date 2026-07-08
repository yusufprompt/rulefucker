#!/bin/bash
RED='\033[0;31m'
WHITE='\033[0;37m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Hata: Rulefucker God Mode sistemin kalbine müdahale eder. Lütfen 'sudo ./rulefucker.sh' şeklinde çalıştırın.${NC}"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PYTHON_CLI="$SCRIPT_DIR/native_manager.py"

# python3 bulunuyor mu kontrol et
if ! command -v python3 &>/dev/null; then
    echo -e "${RED}Hata: python3 sistemde bulunamadı. Lütfen kurun (örn: apt install python3).${NC}"
    exit 1
fi

# native_manager.py dosyası var mı kontrol et
if [ ! -f "$PYTHON_CLI" ]; then
    echo -e "${RED}Hata: $PYTHON_CLI bulunamadı. Script'in yanında olduğundan emin olun.${NC}"
    exit 1
fi

run_python() {
    # Doğrudan çalıştırma izni yerine her zaman python3 ile çağır (izin sorunlarını önler)
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
    echo "7) Varsayılan Kabuğu (Shell) Değiştirme"
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
