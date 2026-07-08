#!/bin/bash

RED='\033[0;31m'
WHITE='\033[0;37'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Hata: Rulefucker God Mode sistemin kalbine müdahale eder. Lütfen 'sudo ./rulefucker.sh' şeklinde çalıştırın.${NC}"
  exit 1
fi

PYTHON_CLI="$(dirname "$0")/native_manager.py"

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
            "$PYTHON_CLI" "uname"
            read -p "Devam etmek için Enter'a basın..."
            ;;
        2)
            echo -e "\n${CYAN}[ OS Identity Customization ]${NC}"
            "$PYTHON_CLI" "os"
            read -p "Devam etmek için Enter'a basın..."
            ;;
        3)
            echo -e "\n${CYAN}[ DE / WM Kurulumu ]${NC}"
            read -p "Kurulacak arayüzün adı (Örn: hyprland, xfce): " de_name
            [ -n "$de_name" ] && "$PYTHON_CLI" "install" "$de_name"
            read -p "Devam etmek için Enter'a basın..."
            ;;
        4)
            echo -e "\n${CYAN}[ Git Install (Otomatik Derleyici) ]${NC}"
            "$PYTHON_CLI" "git-install"
            read -p "Devam etmek için Enter'a basın..."
            ;;
        5)
            echo -e "\n${CYAN}[ Bootloader & Init Manipülasyonu ]${NC}"
            "$PYTHON_CLI" "boot"
            read -p "Devam etmek için Enter'a basın..."
            ;;
        6)
            echo -e "\n${CYAN}[ MAC Adresi Değiştirme ]${NC}"
            "$PYTHON_CLI" "mac"
            read -p "Devam etmek için Enter'a basın..."
            ;;
        7)
            echo -e "\n${CYAN}[ Kabuk (Shell) Değiştirme ]${NC}"
            "$PYTHON_CLI" "shell"
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
