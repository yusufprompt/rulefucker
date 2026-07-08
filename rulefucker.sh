#!/bin/bash

# Renkler
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Root yetkisi kontrolü
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Hata: Bu araç sistemin derinliklerine müdahale eder. Lütfen 'sudo ./rulefucker.sh' şeklinde çalıştırın.${NC}"
  exit 1
fi

PYTHON_CLI="$(dirname "$0")/native_manager.py"

if [ ! -f "$PYTHON_CLI" ]; then
    echo -e "${RED}Hata: native_manager.py bulunamadı!${NC}"
    exit 1
fi

show_menu() {
    clear
    echo -e "${CYAN}======================================================${NC}"
    echo -e "${GREEN}      🚀 RULEFUCKER v3.0 - NATIVE CUSTOMIZER 🚀     ${NC}"
    echo -e "${CYAN}======================================================${NC}"
    echo "İnsanları kandırmıyoruz, yükselişlerine basamak ekliyoruz."
    echo ""
    echo -e "${GREEN}Lütfen yapmak istediğiniz işlemi seçin:${NC}"
    echo "1) Uname Customization (Kernel Çekirdek Kimliğini Değiştir)"
    echo "2) OS Identity Customization (/etc/os-release Değiştir)"
    echo "3) Masaüstü Ortamı (DE) Yükle / Değiştir"
    echo "4) Pencere Yöneticisi (WM) Yükle / Değiştir"
    echo "5) Çıkış"
    echo -e "${CYAN}======================================================${NC}"
}

while true; do
    show_menu
    read -p "Seçiminiz (1-5): " choice

    case $choice in
        1)
            echo ""
            echo -e "${CYAN}[ Uname Customization ]${NC}"
            read -p "Sysname ne olsun? (örn: RuleOS) [Boş geçmek için Enter]: " sysname
            read -p "Nodename ne olsun? (örn: god-pc) [Boş geçmek için Enter]: " nodename
            read -p "Kernel Release ne olsun? (örn: 99.0.1) [Boş geçmek için Enter]: " release
            read -p "Kernel Version ne olsun? [Boş geçmek için Enter]: " version
            read -p "Machine Architecture ne olsun? (örn: x86_64) [Boş geçmek için Enter]: " machine
            
            CMD=("$PYTHON_CLI" "uname")
            [ -n "$sysname" ] && CMD+=("--sysname" "$sysname")
            [ -n "$nodename" ] && CMD+=("--nodename" "$nodename")
            [ -n "$release" ] && CMD+=("--release" "$release")
            [ -n "$version" ] && CMD+=("--version" "$version")
            [ -n "$machine" ] && CMD+=("--machine" "$machine")
            
            echo -e "${GREEN}Değişiklikler uygulanıyor...${NC}"
            "${CMD[@]}"
            
            echo ""
            read -p "Devam etmek için Enter'a basın..."
            ;;
        2)
            echo ""
            echo -e "${CYAN}[ OS Identity Customization ]${NC}"
            read -p "İşletim Sistemi Adı ne olsun? (Örn: RuleOS): " os_name
            read -p "İşletim Sistemi ID'si ne olsun? (Örn: ruleos) [Küçük harf]: " os_id
            
            if [ -n "$os_name" ] && [ -n "$os_id" ]; then
                "$PYTHON_CLI" "os" --name "$os_name" --id "$os_id"
            else
                echo -e "${RED}Hata: İsim ve ID boş bırakılamaz!${NC}"
            fi
            
            echo ""
            read -p "Devam etmek için Enter'a basın..."
            ;;
        3)
            echo ""
            echo -e "${CYAN}[ Desktop Environment (DE) Kurulumu ]${NC}"
            echo "Örnekler: xfce, gnome, kde, mate"
            read -p "Kurulacak DE adını girin: " de_name
            
            if [ -n "$de_name" ]; then
                "$PYTHON_CLI" "install" "$de_name"
            else
                echo -e "${RED}Hata: DE adı boş bırakılamaz!${NC}"
            fi
            
            echo ""
            read -p "Devam etmek için Enter'a basın..."
            ;;
        4)
            echo ""
            echo -e "${CYAN}[ Window Manager (WM) Kurulumu ]${NC}"
            echo "Örnekler: hyprland, i3, bspwm, sway"
            read -p "Kurulacak WM adını girin: " wm_name
            
            if [ -n "$wm_name" ]; then
                "$PYTHON_CLI" "install" "$wm_name"
            else
                echo -e "${RED}Hata: WM adı boş bırakılamaz!${NC}"
            fi
            
            echo ""
            read -p "Devam etmek için Enter'a basın..."
            ;;
        5)
            echo -e "${GREEN}Görüşmek üzere!${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Geçersiz seçim. Lütfen 1 ile 5 arasında bir sayı girin.${NC}"
            sleep 2
            ;;
    esac
done
