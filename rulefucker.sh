#!/bin/bash
#===============================================================================
# RULEFUCKER v6.0 - ULTIMATE SYSTEM MUTATOR (UNIVERSAL EDITION)
#===============================================================================
# Desteklenen Distrolar:
#   - Arch Linux (pacman)
#   - Debian/Ubuntu (apt)
#   - Fedora/RHEL (dnf)
#   - OpenSUSE (zypper)
#   - NixOS (nixos-rebuild + configuration.nix)
#   - Alpine (apk)
#   - Void Linux (xbps)
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

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULE_SRC="$SCRIPT_DIR/legacy_v2/c_hook/rulefucker_kernel_advanced.c"
MODULE_DIR="$SCRIPT_DIR/legacy_v2/c_hook"
LOADER="$SCRIPT_DIR/rulefucker_loader.py"

#===============================================================================
# DISTRO TESPİT MOTORU
#===============================================================================
detect_distro() {
    if [ -f /etc/nixos/configuration.nix ] || command -v nixos-rebuild &>/dev/null; then
        echo "nixos"
    elif command -v pacman &>/dev/null; then
        echo "arch"
    elif command -v apt &>/dev/null; then
        echo "debian"
    elif command -v dnf &>/dev/null; then
        echo "fedora"
    elif command -v zypper &>/dev/null; then
        echo "opensuse"
    elif command -v apk &>/dev/null; then
        echo "alpine"
    elif command -v xbps-install &>/dev/null; then
        echo "void"
    elif command -v emerge &>/dev/null; then
        echo "gentoo"
    else
        echo "unknown"
    fi
}

DISTRO=$(detect_distro)

pm_install() {
    local pkg=$1
    echo -e "${YELLOW}[+] $pkg kuruluyor ($DISTRO)...${NC}"
    case $DISTRO in
        nixos)   nix-env -iA nixos."$pkg" 2>/dev/null || nix profile install nixpkgs#"$pkg" 2>/dev/null ;;
        arch)    pacman -Sy --noconfirm "$pkg" ;;
        debian)  apt-get update -y 2>/dev/null && apt-get install -y "$pkg" ;;
        fedora)  dnf install -y "$pkg" ;;
        opensuse) zypper install -y "$pkg" ;;
        alpine)  apk add "$pkg" ;;
        void)    xbps-install -Sy "$pkg" ;;
        gentoo)  emerge "$pkg" ;;
        *)       echo -e "${RED}Bilinmeyen dağıtım. $pkg'yi manuel kur.${NC}"; return 1 ;;
    esac
}

#===============================================================================
# ROOT KONTROL
#===============================================================================
if [ "$EUID" -ne 0 ] && [ "$DISTRO" != "nixos" ]; then
    echo -e "${RED}Hata: root yetkisi gerekli. sudo ile çalıştırın.${NC}"
    exit 1
fi

#===============================================================================
# NixOS ÖZEL: configuration.nix ENTEGRASYONU
#===============================================================================
nixos_setup_kernel_module() {
    echo -e "\n${CYAN}═══════════════════════════════════════════${NC}"
    echo -e "${GREEN}  NIXOS KERNEL MODÜL KURULUMU${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════${NC}"
    echo ""

    local sysname nodename release version machine domain
    read -p "$(echo -e $CYAN"Sysname"$NC" (uname -s): " )" sysname
    sysname=${sysname:-RuleOS}
    read -p "$(echo -e $CYAN"Nodename"$NC" (uname -n): " )" nodename
    nodename=${nodename:-$(hostname)}
    read -p "$(echo -e $CYAN"Release"$NC" (uname -r): " )" release
    release=${release:-99.0.0-nixos}
    read -p "$(echo -e $CYAN"Version"$NC" (uname -v): " )" version
    version=${version:-"#1 NixOS Rulefucker"}
    read -p "$(echo -e $CYAN"Machine"$NC" (uname -m): " )" machine
    machine=${machine:-x86_64}
    read -p "$(echo -e $CYAN"Domain"$NC": " )" domain
    domain=${domain:-"(none)"}

    # configuration.nix'e eklenecek blok
    read -p "configuration.nix yolu (/etc/nixos/configuration.nix): " nixpath
    nixpath=${nixpath:-/etc/nixos/configuration.nix}

    if [ ! -f "$nixpath" ]; then
        echo -e "${RED}[!] $nixpath bulunamadı.${NC}"
        return
    fi

    # Yedek al
    cp "$nixpath" "${nixpath}.rulefucker.bak"
    echo -e "${GREEN}[✓] Yedek: ${nixpath}.rulefucker.bak${NC}"

    # Modül kaynağını /etc/nixos/ altına kopyala
    mkdir -p /etc/nixos/rulefucker_module
    if [ -f "$MODULE_SRC" ]; then
        cp "$MODULE_SRC" /etc/nixos/rulefucker_module/
        echo -e "${GREEN}[✓] Modül kaynağı kopyalandı${NC}"
    fi

    # configuration.nix'e boot.extraModulePackages bloğu ekle
    cat >> "$nixpath" << NIXEOF

  # --- Rulefucker v6.0 Kernel Identity Mutation ---
  # Ekleyen: rulefucker.sh (tarih: $(date))
  # Kaldırmak için bu bloğu sil ve nixos-rebuild switch çalıştır

  boot.kernelModules = [ "rulefucker_kernel_advanced" ];

  boot.extraModulePackages = with config.boot.kernelPackages; [
    (callPackage ./rulefucker_module { })
  ];

  boot.kernelParams = [
    # Rulefucker module parameters via modprobe.d
  ];

  environment.etc."modprobe.d/rulefucker.conf".text = ''
    options rulefucker_kernel_advanced sysname="${sysname}" nodename="${nodename}" release="${release}" version="${version}" machine="${machine}" domain="${domain}" hidden=1
  '';
NIXEOF

    # Derleme için default.nix oluştur
    cat > /etc/nixos/rulefucker_module/default.nix << 'NIXDERIVE'
{ stdenv, kernel, fetchurl }:

stdenv.mkDerivation {
  name = "rulefucker_kernel_advanced";
  src = ./.;
  phases = [ "buildPhase" "installPhase" ];
  buildPhase = ''
    export LINUXINCLUDE="-I${kernel.dev}/lib/modules/${kernel.version}/build/include"
    make -C ${kernel.dev}/lib/modules/${kernel.version}/build M=$src modules
  '';
  installPhase = ''
    mkdir -p $out/lib/modules/${kernel.version}/extra
    cp $src/rulefucker_kernel_advanced.ko $out/lib/modules/${kernel.version}/extra/
  '';
}
NIXDERIVE

    # Makefile da kopyala
    cp "$MODULE_DIR/Makefile" /etc/nixos/rulefucker_module/ 2>/dev/null || true

    echo ""
    echo -e "${YELLOW}!!! UYARI: NixOS için modül derlemesi complex bir yapı.${NC}"
    echo -e "${YELLOW}Önerilen: Aşağıdaki alternatif yöntemleri kullan:${NC}"
    echo ""
    echo -e "  ${GREEN}1)${NC} NixOS'ta direkt insmod ile manuel yükleme:"
    echo -e "     ${CYAN}cd $MODULE_DIR && make && sudo insmod rulefucker_kernel_advanced.ko sysname=\"$sysname\" hidden=1${NC}"
    echo ""
    echo -e "  ${GREEN}2)${NC} systemd oneshot service ile her bootta yükle:"
    echo -e "     [Birim] bölümüne ekle:"
    echo -e "     ${CYAN}systemd.services.rulefucker = {${NC}"
    echo -e "     ${CYAN}  wantedBy = [ \"multi-user.target\" ];${NC}"
    echo -e "     ${CYAN}  serviceConfig.Type = \"oneshot\";${NC}"
    echo -e "     ${CYAN}  script = \"insmod /path/to/rulefucker_kernel_advanced.ko sysname=$sysname hidden=1\";${NC}"
    echo -e "     ${CYAN};};${NC}"
    echo ""
    read -p "Devam etmek için Enter..."
}

nixos_restore_config() {
    echo -e "\n${CYAN}[ NixOS config geri yükle ]${NC}"
    if [ -f /etc/nixos/configuration.nix.rulefucker.bak ]; then
        cp /etc/nixos/configuration.nix.rulefucker.bak /etc/nixos/configuration.nix
        echo -e "${GREEN}[✓] configuration.nix geri yüklendi.${NC}"
        echo -e "${YELLOW}nixos-rebuild switch çalıştırmayı unutma.${NC}"
    else
        echo -e "${RED}[!] Yedek bulunamadı.${NC}"
    fi
}

#===============================================================================
# BINARY'DEN KOD'A DÖNÜŞTÜRÜCÜ (BINARY TO C/ASM/RUST/PYTHON)
#===============================================================================
# Desteklenen araçlar:
#   - radare2 + r2ghidra (ELF/PE/Mach-O -> C)
#   - Ghidra headless (ELF/PE/Mach-O -> C)
#   - objdump (ELF -> ASM)
#   - LLM4Decompile (ELF -> C, AI destekli)
#   - strings (binary -> string çıkarma)
#   - elftoc (ELF -> C struct)
#===============================================================================

detect_binary_tools() {
    local tools=""
    command -v r2 &>/dev/null && tools="$tools radare2"
    command -v r2ghidra &>/dev/null && tools="$tools r2ghidra"
    command -v ghidra &>/dev/null && tools="$tools ghidra"
    command -v objdump &>/dev/null && tools="$tools objdump"
    command -v strings &>/dev/null && tools="$tools strings"
    command -v elftoc &>/dev/null && tools="$tools elftoc"
    [ -d "/opt/ghidra" ] && tools="$tools ghidra_headless"
    echo "$tools"
}

install_binary_tools() {
    echo -e "${CYAN}[*] Binary analiz araçları kontrol ediliyor...${NC}"
    
    local need_install=""
    command -v r2 &>/dev/null || need_install="$need_install radare2"
    command -v objdump &>/dev/null || need_install="$need_install binutils"
    command -v strings &>/dev/null || need_install="$need_install binutils"
    
    if [ -n "$need_install" ]; then
        echo -e "${YELLOW}[!] Eksik araçlar: $need_install${NC}"
        for tool in $need_install; do
            case $tool in
                radare2) pm_install "radare2" ;;
                binutils) pm_install "binutils" ;;
            esac
        done
    fi

    # r2ghidra plugin
    if command -v r2 &>/dev/null && ! r2 -q -c "e plugin" 2>/dev/null | grep -qi ghidra; then
        echo -e "${YELLOW}[!] r2ghidra plugin eksik. Kuruluyor...${NC}"
        if command -v r2pm &>/dev/null; then
            r2pm -ci r2ghidra 2>/dev/null || echo -e "${YELLOW}r2pm ile kurulamadı, elle derleme gerekli.${NC}"
        fi
    fi

    echo -e "${GREEN}[✓] Binary araçlar hazır.${NC}"
}

binary_to_code_menu() {
    echo -e "\n${CYAN}╔══════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}  ${GREEN}${BOLD}💀 BINARY'DEN KOD'A DÖNÜŞTÜRÜCÜ 💀${NC}      ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════╝${NC}"
    echo ""

    read -p "Hedef binary dosyası (ELF/PE/Mach-O): " binary_path
    if [ -z "$binary_path" ] || [ ! -f "$binary_path" ]; then
        echo -e "${RED}[!] Dosya bulunamadı.${NC}"
        return
    fi

    echo ""
    echo -e "${YELLOW}Dosya: $binary_path${NC}"
    echo -e "${YELLOW}Boyut: $(du -h "$binary_path" | cut -f1)${NC}"
    echo ""

    echo -e "${GREEN}Çıktı formatı seç:${NC}"
    echo "  1)  C Kodu (r2ghidra ile decompile)"
    echo "  2)  Assembly (objdump ile disassemble)"
    echo "  3)  C Kodu (Ghidra headless ile)"
    echo "  4)  C Struct tanımı (elftoc ile)"
    echo "  5)  String çıkar (strings)"
    echo "  6)  TÜMÜ (assembly + C + strings + struct)"
    echo "  7)  LLM4Decompile (AI destekli decompile)"
    echo "  8)  ELF detaylı analiz (readelf + objdump + strings)"
    echo ""
    read -p "Seçim (1-8): " fmt_choice

    local out_dir="${binary_path}.rulefucker_decomp"
    mkdir -p "$out_dir"

    case $fmt_choice in
        1)  # r2ghidra C
            echo -e "${YELLOW}[*] r2ghidra ile C koduna dönüştürülüyor...${NC}"
            if command -v r2 &>/dev/null; then
                r2 -q -c "aaa; pdg; quit" "$binary_path" > "$out_dir/decompiled.c" 2>/dev/null
                # Tek fonksiyonları da çıkar
                r2 -q -c "aaa; afl~[0-9]" "$binary_path" 2>/dev/null | while read func; do
                    fname=$(echo "$func" | awk '{print $NF}')
                    r2 -q -c "aaa; s $fname; pdg; quit" "$binary_path" > "$out_dir/func_${fname}.c" 2>/dev/null
                done
                echo -e "${GREEN}[✓] $out_dir/decompiled.c oluşturuldu.${NC}"
            else
                echo -e "${RED}[!] radare2 kurulu değil. Önce 0) Kurulum yapın.${NC}"
            fi
            ;;
        2)  # Assembly
            echo -e "${YELLOW}[*] objdump ile assembly çıkarılıyor...${NC}"
            if command -v objdump &>/dev/null; then
                objdump -d "$binary_path" > "$out_dir/disassembly.asm" 2>&1
                objdump -D "$binary_path" > "$out_dir/disassembly_full.asm" 2>&1
                objdump -t "$binary_path" > "$out_dir/symbol_table.txt" 2>&1
                objdump -R "$binary_path" > "$out_dir/relocations.txt" 2>&1
                echo -e "${GREEN}[✓] Assembly dosyaları oluşturuldu.${NC}"
            else
                echo -e "${RED}[!] objdump (binutils) kurulu değil.${NC}"
            fi
            ;;
        3)  # Ghidra headless
            echo -e "${YELLOW}[*] Ghidra headless decompile deneniyor...${NC}"
            GHIDRA_HOME="/opt/ghidra"
            if [ -d "$GHIDRA_HOME" ]; then
                "$GHIDRA_HOME/support/analyzeHeadless" \
                    /tmp/ghidra_proj \
                    -import "$binary_path" \
                    -postScript AverageGuidPatchProgram.java 2>/dev/null || true
                # Alternatif: Ghidra'nın built-in decompiler'ını kullan
                "$GHIDRA_HOME/support/analyzeHeadless" \
                    /tmp/ghidra_proj \
                    -import "$binary_path" \
                    -postScript DumpDecompiler.java 2>/dev/null || {
                    # Manuel Ghidra script çalıştır
                    cat > /tmp/DumpDecompiler.java << 'JAVA'
import ghidra.app.script.GhidraScript;
import ghidra.program.model.listing.*;
import ghidra.app.decompiler.*;

public class DumpDecompiler extends GhidraScript {
    public void run() throws Exception {
        DecompInterface decompiler = new DecompInterface();
        decompiler.openProgram(currentProgram);
        FunctionIterator functions = currentProgram.getFunctionManager().getFunctions(true);
        while (functions.hasNext()) {
            Function f = functions.next();
            DecompileResults res = decompiler.decompileFunction(f, 30, monitor);
            if (res != null && res.getDecompiledFunction() != null) {
                String name = f.getName().replaceAll("[^a-zA-Z0-9]", "_");
                writeFile("decomp_" + name + ".c", res.getDecompiledFunction().getC());
            }
        }
    }
}
JAVA
                    "$GHIDRA_HOME/support/analyzeHeadless" \
                        /tmp/ghidra_proj \
                        -import "$binary_path" \
                        -scriptPath /tmp \
                        -postScript DumpDecompiler.java \
                        -deleteProject 2>/dev/null
                }
                # Çıktıları kopyala
                find /tmp/ghidra_proj -name "*.c" -exec cp {} "$out_dir/" \; 2>/dev/null
                echo -e "${GREEN}[✓] Ghidra decompile tamamlandı (eğer Ghidra kuruluysa).${NC}"
            else
                echo -e "${RED}[!] Ghidra /opt/ghidra altında bulunamadı.${NC}"
                echo -e "${YELLOW}Şununla dene: ghidra headless analizi için Ghidra'yı kur.${NC}"
            fi
            ;;
        4)  # elftoc
            echo -e "${YELLOW}[*] elftoc ile C struct çıkarılıyor...${NC}"
            if command -v elftoc &>/dev/null; then
                elftoc "$binary_path" > "$out_dir/elf_struct.c" 2>&1
                echo -e "${GREEN}[✓] $out_dir/elf_struct.c oluşturuldu.${NC}"
            else
                echo -e "${YELLOW}[!] elftoc bulunamadı. elftoc, ELFKickers paketinde.${NC}"
                echo -e "${YELLOW}  NixOS: nix-env -iA nixos.elfkickers${NC}"
                echo -e "${YELLOW}  Arch:  yay -S elfkickers${NC}"
                echo -e "${YELLOW}  Diğer: https://www.muppetlabs.com/~breadbox/software/elfkickers/  ${NC}"
            fi
            ;;
        5)  # Sadece strings
            echo -e "${YELLOW}[*] Stringler çıkarılıyor...${NC}"
            if command -v strings &>/dev/null; then
                strings -a "$binary_path" > "$out_dir/strings.txt" 2>&1
                strings -a -n 10 "$binary_path" > "$outDir/strings_long.txt" 2>&1
                echo -e "${GREEN}[✓] $out_dir/strings.txt oluşturuldu.${NC}"
                echo -e "${YELLOW}Toplam $(wc -l < "$out_dir/strings.txt") string bulundu.${NC}"
            fi
            ;;
        6)  # TÜMÜ
            echo -e "${YELLOW}[*] Tüm formatlar çıkarılıyor...${NC}"
            # Assembly
            command -v objdump &>/dev/null && objdump -d "$binary_path" > "$out_dir/disassembly.asm" 2>&1
            # r2ghidra C
            if command -v r2 &>/dev/null; then
                r2 -q -c "aaa; pdg; quit" "$binary_path" > "$out_dir/decompiled.c" 2>/dev/null
                # Her fonksiyon için ayrı decompile
                r2 -q -c "aaa; afl" "$binary_path" 2>/dev/null | grep -E "^0x" | while read line; do
                    addr=$(echo "$line" | awk '{print $1}')
                    fname=$(echo "$line" | awk '{print $NF}' | tr -d '.')
                    [ -z "$fname" ] && continue
                    r2 -q -c "aaa; s $addr; pdg; quit" "$binary_path" > "$out_dir/func_${fname}.c" 2>/dev/null
                done
            fi
            # elftoc
            command -v elftoc &>/dev/null && elftoc "$binary_path" > "$out_dir/elf_struct.c" 2>&1
            # Strings
            command -v strings &>/dev/null && strings -a "$binary_path" > "$out_dir/strings.txt" 2>&1
            # readelf
            if command -v readelf &>/dev/null; then
                readelf -a "$binary_path" > "$out_dir/readelf_full.txt" 2>&1
                readelf -s "$binary_path" > "$out_dir/symbols.txt" 2>&1
            fi
            # Hexdump
            command -v xxd &>/dev/null && xxd "$binary_path" | head -500 > "$out_dir/hexdump.txt" 2>&1
            # file
            file "$binary_path" > "$out_dir/file_info.txt" 2>&1

            echo -e "${GREEN}[✓] Tüm çıktılar $out_dir/ altında:${NC}"
            ls -la "$out_dir/" | sed 's/^/  /'
            ;;
        7)  # LLM4Decompile
            echo -e "${YELLOW}[*] LLM4Decompile (AI destekli) deneniyor...${NC}"
            # Önce objdump ile assembly çıkar
            if command -v objdump &>/dev/null; then
                objdump -d "$binary_path" > "$out_dir/disassembly.asm" 2>&1
                echo -e "${GREEN}[✓] Assembly çıkarıldı.${NC}"
            fi
            # LLM4Decompile kontrol
            if python3 -c "import transformers" 2>/dev/null; then
                cat > /tmp/llm4decompile_run.py << 'PYEOF'
import sys, os, subprocess, json

# LLM4Decompile modelini kullanarak assembly'den C kodu üret
# Model: albertan017/LLM4Decompile-1.3b (veya daha büyüğü)
try:
    from transformers import AutoTokenizer, AutoModelForCausalLM
    import torch
    
    model_name = "albertan017/LLM4Decompile-1.3b"
    print(f"[*] {model_name} yükleniyor...")
    
    tokenizer = AutoTokenizer.from_pretrained(model_name)
    model = AutoModelForCausalLM.from_pretrained(model_name)
    
    asm_path = sys.argv[1]
    out_path = sys.argv[2]
    
    with open(asm_path, 'r') as f:
        asm_code = f.read()
    
    # Assembly'i prefix ile formatla
    prompt = f"# This is the assembly code:\n{asm_code}\n# What is the source code?\n"
    inputs = tokenizer(prompt, return_tensors="pt", truncation=True, max_length=2048)
    outputs = model.generate(**inputs, max_new_tokens=1024)
    c_code = tokenizer.decode(outputs[0], skip_special_tokens=True)
    
    with open(out_path, 'w') as f:
        f.write(c_code)
    
    print(f"[✓] C kodu oluşturuldu: {out_path}")
    
except ImportError:
    print("[!] transformers/torch kurulu değil.")
    print("[*] pip install transformers torch")
except Exception as e:
    print(f"[!] LLM4Decompile hatası: {e}")
PYEOF
                python3 /tmp/llm4decompile_run.py "$out_dir/disassembly.asm" "$out_dir/llm_decompiled.c" 2>&1 || {
                    echo -e "${YELLOW}[!] LLM4Decompile çalışmadı. Alternatif: elle https://huggingface.co/albertan017/LLM4Decompile${NC}"
                }
            else
                echo -e "${YELLOW}[!] transformers kütüphanesi eksik. pip install transformers${NC}"
                echo -e "${YELLOW}Alternatif: https://github.com/albertan017/LLM4Decompile${NC}"
            fi
            ;;
        8)  # ELF detaylı analiz
            echo -e "${YELLOW}[*] Detaylı ELF analizi yapılıyor...${NC}"
            file "$binary_path" > "$out_dir/file_info.txt" 2>&1
            if command -v readelf &>/dev/null; then
                readelf -a "$binary_path" > "$out_dir/readelf_full.txt" 2>&1
                readelf -h "$binary_path" > "$out_dir/elf_header.txt" 2>&1
                readelf -S "$binary_path" > "$out_dir/sections.txt" 2>&1
                readelf -s "$binary_path" > "$out_dir/symbols.txt" 2>&1
                readelf -r "$binary_path" > "$out_dir/relocations.txt" 2>&1
                readelf -d "$binary_path" > "$out_dir/dynamic.txt" 2>&1
                readelf -l "$binary_path" > "$out_dir/program_headers.txt" 2>&1
                readelf -n "$binary_path" > "$out_dir/notes.txt" 2>&1
            fi
            if command -v objdump &>/dev/null; then
                objdump -d "$binary_path" > "$out_dir/disassembly.asm" 2>&1
                objdump -D "$binary_path" > "$out_dir/disassembly_full.asm" 2>&1
                objdump -t "$binary_path" > "$out_dir/symbol_table.txt" 2>&1
                objdump -R "$binary_path" > "$out_dir/dynamic_relocations.txt" 2>&1
                objdump -p "$binary_path" > "$out_dir/program_info.txt" 2>&1
                objdump -s -j .rodata "$binary_path" > "$out_dir/rodata_hex.txt" 2>&1
                objdump -s -j .data "$binary_path" > "$out_dir/data_hex.txt" 2>&1
            fi
            if command -v strings &>/dev/null; then
                strings -a "$binary_path" > "$out_dir/strings.txt" 2>&1
                strings -a -n 15 "$binary_path" > "$out_dir/strings_long_only.txt" 2>&1
            fi
            if command -v nm &>/dev/null; then
                nm -a "$binary_path" > "$out_dir/nm_symbols.txt" 2>&1
                nm -C "$binary_path" > "$out_dir/demangled_symbols.txt" 2>&1
            fi
            if command -v ldd &>/dev/null; then
                ldd "$binary_path" > "$out_dir/shared_libs.txt" 2>&1
            fi
            # Hexdump
            command -v xxd &>/dev/null && xxd "$binary_path" > "$out_dir/full_hexdump.txt" 2>&1
            # ELF bölüm boyutları
            if command -v size &>/dev/null; then
                size "$binary_path" > "$out_dir/section_sizes.txt" 2>&1
            fi

            echo -e "${GREEN}[✓] Tüm analiz dosyaları oluşturuldu:${NC}"
            ls -lh "$out_dir/" | sed 's/^/  /'
            echo ""
            echo -e "${YELLOW}Özet:${NC}"
            echo -e "  Dosya türü: $(cat "$out_dir/file_info.txt")"
            if [ -f "$out_dir/strings.txt" ]; then
                echo -e "  String sayısı: $(wc -l < "$out_dir/strings.txt")"
            fi
            if [ -f "$out_dir/symbols.txt" ]; then
                echo -e "  Sembol sayısı: $(wc -l < "$out_dir/symbols.txt")"
            fi
            if [ -f "$out_dir/shared_libs.txt" ]; then
                echo -e "  Kullanılan kütüphaneler:"
                grep "=>" "$out_dir/shared_libs.txt" 2>/dev/null | sed 's/^/    /'
            fi
            if command -v r2 &>/dev/null; then
                echo -e "  Fonksiyon sayısı: $(r2 -q -c 'aaa; afl; quit' "$binary_path" 2>/dev/null | wc -l)"
            fi
            ;;
        *)
            echo -e "${RED}Geçersiz seçim.${NC}"
            rm -rf "$out_dir"
            return
            ;;
    esac

    echo ""
    echo -e "${GREEN}[✓] Tüm çıktılar: $out_dir/${NC}"
    echo -e "${YELLOW}Dosyalar:${NC}"
    ls -lh "$out_dir/" | sed 's/^/  /'
    echo ""
    echo -e "${YELLOW}İlk 50 satırlık önizleme (decompiled.c varsa):${NC}"
    [ -f "$out_dir/decompiled.c" ] && head -50 "$out_dir/decompiled.c" | sed 's/^/  /'
    [ -f "$out_dir/disassembly.asm" ] && head -30 "$out_dir/disassembly.asm" | sed 's/^/  /'
}

#===============================================================================
# BINARY KARŞILAŞTIRICI (DIFF ANALİZİ)
#===============================================================================
binary_diff_menu() {
    echo -e "\n${CYAN}═══════════════════════════════════════════${NC}"
    echo -e "${GREEN}  BINARY KARŞILAŞTIRICI (DIFF)${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════${NC}"
    echo ""

    read -p "Orijinal binary: " orig_bin
    read -p "Değiştirilmiş binary: " mod_bin

    if [ ! -f "$orig_bin" ] || [ ! -f "$mod_bin" ]; then
        echo -e "${RED}[!] Dosyalar bulunamadı.${NC}"
        return
    fi

    mkdir -p "/tmp/rulefucker_diff_$$"
    
    echo -e "${YELLOW}[*] Boyut karşılaştırması:${NC}"
    ls -l "$orig_bin" "$mod_bin" | sed 's/^/  /'
    
    echo ""
    echo -e "${YELLOW}[*] MD5/SHA256 karşılaştırması:${NC}"
    echo -e "  MD5    orig: $(md5sum "$orig_bin" | cut -d' ' -f1)"
    echo -e "  MD5    mod:  $(md5sum "$mod_bin" | cut -d' ' -f1)"
    echo -e "  SHA256 orig: $(sha256sum "$orig_bin" | cut -d' ' -f1)"
    echo -e "  SHA256 mod:  $(sha256sum "$mod_bin" | cut -d' ' -f1)"

    echo ""
    echo -e "${YELLOW}[*] Assembly diff:${NC}"
    if command -v objdump &>/dev/null; then
        objdump -d "$orig_bin" > "/tmp/rulefucker_diff_$$/orig.asm" 2>/dev/null
        objdump -d "$mod_bin" > "/tmp/rulefucker_diff_$$/mod.asm" 2>/dev/null
        if command -v diff &>/dev/null; then
            diff -u "/tmp/rulefucker_diff_$$/orig.asm" "/tmp/rulefucker_diff_$$/mod.asm" > "/tmp/rulefucker_diff_$$/asm_diff.txt" 2>&1
            local diff_lines=$(wc -l < "/tmp/rulefucker_diff_$$/asm_diff.txt")
            echo -e "  Assembly fark satırı: $diff_lines"
            if [ "$diff_lines" -gt 0 ] && [ "$diff_lines" -lt 100 ]; then
                cat "/tmp/rulefucker_diff_$$/asm_diff.txt" | sed 's/^/  /'
            fi
        fi
    fi

    echo ""
    echo -e "${YELLOW}[*] String diff:${NC}"
    strings -a "$orig_bin" > "/tmp/rulefucker_diff_$$/orig_strings.txt" 2>/dev/null
    strings -a "$mod_bin" > "/tmp/rulefucker_diff_$$/mod_strings.txt" 2>/dev/null
    diff "/tmp/rulefucker_diff_$$/orig_strings.txt" "/tmp/rulefucker_diff_$$/mod_strings.txt" 2>/dev/null | head -30 | sed 's/^/  /'

    echo ""
    echo -e "${YELLOW}[*] Hex karşılaştırması (ilk 64 byte):${NC}"
    echo -e "  Orijinal:     $(xxd -l 64 "$orig_bin" 2>/dev/null | cut -d' ' -f2- | head -1)"
    echo -e "  Değiştirilen: $(xxd -l 64 "$mod_bin" 2>/dev/null | cut -d' ' -f2- | head -1)"

    rm -rf "/tmp/rulefucker_diff_$$"
}

#===============================================================================
# ANA BAĞIMLILIKLAR
#===============================================================================
check_dependencies() {
    echo -e "${CYAN}[*] Sistem gereksinimleri kontrol ediliyor...${NC}"
    
    if [ "$DISTRO" = "nixos" ]; then
        echo -e "${GREEN}[✓] NixOS tespit edildi. NixOS modu kullanılacak.${NC}"
        # NixOS'ta bazı şeyler farklı
        return 0
    fi

    for cmd in python3 git make gcc; do
        if ! command -v $cmd &>/dev/null; then
            echo -e "${YELLOW}[!] $cmd eksik.${NC}"
            pm_install "$cmd" 2>/dev/null || true
        fi
    done

    # Kernel headers
    if [ ! -d "/lib/modules/$(uname -r)/build" ]; then
        echo -e "${YELLOW}[!] Kernel headers eksik.${NC}"
        case $DISTRO in
            arch)   pm_install "linux-headers" ;;
            debian) pm_install "linux-headers-$(uname -r)" 2>/dev/null || pm_install "linux-headers-generic" ;;
            fedora) pm_install "kernel-devel" ;;
            *)      echo -e "${RED}Headers manuel kurulmalı.${NC}" ;;
        esac
    fi

    # Binary analiz araçları (opsiyonel, sadece menüden seçilirse kurulur)
    echo -e "${GREEN}[✓] Temel bağımlılıklar tamam.${NC}"
}

#===============================================================================
# MENÜ
#===============================================================================
show_menu() {
    clear
    echo -e "${CYAN}╔═══════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}  ${GREEN}${BOLD}🚀 RULEFUCKER v6.0 - UNIVERSAL EDITION 🚀${NC}       ${CYAN}║${NC}"
    echo -e "${CYAN}╠═══════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC}  ${YELLOW}Dağıtım:${NC} ${BOLD}$DISTRO${NC}                                       ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${YELLOW}Kernel:${NC}  $(uname -r)                                   ${CYAN}║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════╝${NC}"
    echo ""

    # Aktif modül durumu
    if lsmod | grep -q "rulefucker_kernel_advanced"; then
        echo -e "  ${GREEN}[●] Kernel Modül (Advanced): AKTİF${NC}"
    elif lsmod | grep -q "rulefucker_kernel"; then
        echo -e "  ${GREEN}[●] Kernel Modül (Legacy): AKTİF${NC}"
    else
        echo -e "  ${RED}[○] Kernel Modül: YÜKLÜ DEĞİL${NC}"
    fi

    # Binary tools durumu
    local tools=$(detect_binary_tools)
    if [ -n "$tools" ]; then
        echo -e "  ${GREEN}[●] Binary Tools:${NC}$tools"
    else
        echo -e "  ${RED}[○] Binary Tools: kurulu değil${NC}"
    fi
    echo ""

    echo -e "  ${GREEN}${BOLD}[ KERNEL ENJEKSİYONU ]${NC}"
    echo "   1)  Kernel Enjeksiyonu (Derle + Yükle)"
    echo "   2)  Kernel Modülü Kaldır"
    echo "   3)  Kernel Durumunu Göster"
    echo ""
    echo -e "  ${GREEN}${BOLD}[ BINARY'DEN KOD'A ]${NC}"
    echo "   4)  Binary -> C/ASM/String Dönüştürücü"
    echo "   5)  Binary Karşılaştırıcı (Diff)"
    echo "   6)  Binary Analiz Araçlarını Kur"
    echo ""
    echo -e "  ${GREEN}${BOLD}[ SİSTEM KİMLİĞİ ]${NC}"
    echo "   7)  OS Identity (/etc/os-release değiştir)"
    echo "   8)  OS Identity Geri Yükle"
    echo ""
    echo -e "  ${GREEN}${BOLD}[ GOD MODE ]${NC}"
    echo "   9)  Bootloader Manipülasyonu"
    echo "  10)  MAC Adresi Değiştir"
    echo "  11)  Shell Değiştir"
    echo "  12)  Git Install (Otomatik Derleyici)"
    echo ""
    if [ "$DISTRO" = "nixos" ]; then
        echo -e "  ${MAGENTA}${BOLD}[ NIXOS ÖZEL ]${NC}"
        echo "   N1)  NixOS Kernel Module Kurulumu"
        echo "   N2)  NixOS Config Geri Yükle"
        echo ""
    fi
    echo "   0)  Çıkış"
    echo -e "${CYAN}────────────────────────────────────────────${NC}"
}

#===============================================================================
# ANA DÖNGÜ
#===============================================================================

check_dependencies

while true; do
    show_menu
    read -p "$(echo -e $CYAN"Seçim"$NC": " )" choice

    case $choice in
        1)  # Kernel Enjeksiyonu
            echo -e "\n${CYAN}[ Kernel Enjeksiyonu ]${NC}"
            if [ ! -f "$MODULE_SRC" ]; then
                echo -e "${RED}[!] Kaynak bulunamadı: $MODULE_SRC${NC}"
                read -p "Enter..."
                continue
            fi
            
            # Parametre al
            read -p "Sysname (uname -s): " s
            read -p "Nodename (uname -n, boş=hostname): " n
            read -p "Release (uname -r): " r
            read -p "Version (uname -v): " v
            read -p "Machine (uname -m): " m
            s=${s:-RuleOS}; n=${n:-$(hostname)}; r=${r:-99.0.0}; v=${v:-"#1 Rulefucker"}; m=${m:-x86_64}
            read -p "Gizli mod? (e/E): " h; hf=""; [[ "$h" =~ ^[Ee]$ ]] && hf="hidden=1"
            
            cd "$MODULE_DIR" && make rulefucker_kernel_advanced.ko 2>&1 | tail -5
            if [ -f "rulefucker_kernel_advanced.ko" ]; then
                insmod rulefucker_kernel_advanced.ko sysname="$s" nodename="$n" release="$r" version="$v" machine="$m" $hf
                echo -e "${GREEN}[✓] Yüklendi. uname -a: $(uname -a)${NC}"
            else
                echo -e "${RED}[!] Derleme hatası. dmesg'e bak.${NC}"
            fi
            cd "$SCRIPT_DIR"
            read -p "Enter..."
            ;;
        2)  # Kaldır
            for mod in rulefucker_kernel_advanced rulefucker_kernel; do
                lsmod | grep -q "$mod" && rmmod "$mod" 2>/dev/null && echo -e "${GREEN}[✓] $mod kaldırıldı${NC}"
            done
            read -p "Enter..."
            ;;
        3)  # Durum
            echo -e "\n${CYAN}[ Kernel Durumu ]${NC}"
            echo -e "  uname -a: $(uname -a)"
            lsmod | grep "rulefucker" | sed 's/^/  /'
            [ -f /proc/rulefucker ] && echo -e "  /proc/rulefucker:" && cat /proc/rulefucker | sed 's/^/    /'
            read -p "Enter..."
            ;;
        4)  # Binary -> Code
            install_binary_tools
            binary_to_code_menu
            read -p "Enter..."
            ;;
        5)  # Binary Diff
            binary_diff_menu
            read -p "Enter..."
            ;;
        6)  # Araç kurulumu
            echo -e "${CYAN}[ Binary Tools Kurulumu ]${NC}"
            echo "  1) Sadece radare2 + r2ghidra"
            echo "  2) Sadece Ghidra (tam)"
            echo "  3) Tüm araçlar (r2 + Ghidra + elftoc + binutils)"
            echo "  4) elftoc (ELF -> C struct)"
            read -p "Seçim (1-4): " tc
            case $tc in
                1) pm_install "radare2"; r2pm -ci r2ghidra 2>/dev/null || echo "r2ghidra elle kurulmalı" ;;
                2) echo -e "${YELLOW}Ghidra için: https://ghidra-sre.org/ adresinden indir, /opt/ghidra çıkar${NC}" ;;
                3) pm_install "radare2"; pm_install "binutils"; echo "Ghidra elle indirilmeli." ;;
                4) pm_install "elfkickers" 2>/dev/null || echo -e "${YELLOW}elfkickers reposunda yoksa: https://www.muppetlabs.com/~breadbox/software/elfkickers/${NC}" ;;
            esac
            read -p "Enter..."
            ;;
        7)  # OS identity
            read -p "Yeni OS adı: " osn; osn=${osn:-Kali}
            read -p "Yeni ID: " osi; osi=${osi:-kali}
            [ -f /etc/os-release ] && cp /etc/os-release /etc/os-release.rulefucker.bak 2>/dev/null
            echo "NAME=\"$osn\"" > /etc/os-release
            echo "ID=$osi" >> /etc/os-release
            echo "PRETTY_NAME=\"$osn (Rulefucker)\"" >> /etc/os-release
            echo -e "${GREEN}[✓] Değiştirildi${NC}"
            read -p "Enter..."
            ;;
        8)  # OS restore
            [ -f /etc/os-release.rulefucker.bak ] && cp /etc/os-release.rulefucker.bak /etc/os-release && echo -e "${GREEN}[✓] Geri yüklendi${NC}" || echo -e "${RED}[!] Yedek yok${NC}"
            read -p "Enter..."
            ;;
        9)  # Bootloader
            echo -e "\n${CYAN}[ Bootloader ]${NC}"
            echo "  1) init=/bin/bash  2) quiet  3) single  4) emergency  5) rd.break  6) kendi"
            read -p "Seçim (1-6): " bc
            p=""; case $bc in 1) p="init=/bin/bash" ;; 2) p="quiet" ;; 3) p="single" ;; 4) p="systemd.unit=emergency" ;; 5) p="rd.break" ;; 6) read -p "Parametre: " p ;; esac
            if [ -n "$p" ] && [ -f /etc/default/grub ]; then
                cp /etc/default/grub /etc/default/grub.rulefucker.bak 2>/dev/null
                cur=$(grep "^GRUB_CMDLINE_LINUX_DEFAULT=" /etc/default/grub | sed 's/GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"/\1/')
                sed -i "s|^GRUB_CMDLINE_LINUX_DEFAULT=.*|GRUB_CMDLINE_LINUX_DEFAULT=\"$cur $p\"|" /etc/default/grub
                command -v update-grub &>/dev/null && update-grub
                command -v grub-mkconfig &>/dev/null && grub-mkconfig -o /boot/grub/grub.cfg
                echo -e "${GREEN}[✓] $p eklendi${NC}"
            fi
            read -p "Enter..."
            ;;
        10) # MAC
            ip -o link show | awk -F': ' '{print $2}' | sed 's/@.*//'
            read -p "Arayüz: " iface
            [ -z "$iface" ] && { read -p "Enter..."; continue; }
            rm=$(printf '02:%02x:%02x:%02x:%02x:%02x' $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256)))
            read -p "MAC (boş=rastgele $rm): " nm; nm=${nm:-$rm}
            ip link set dev "$iface" down && ip link set dev "$iface" address "$nm" && ip link set dev "$iface" up
            echo -e "${GREEN}[✓] MAC: $nm${NC}"
            read -p "Enter..."
            ;;
        11) # Shell
            cat /etc/shells 2>/dev/null
            read -p "Kullanıcı (boş=root): " su; su=${su:-root}
            read -p "Shell yolu: " sp; [ -n "$sp" ] && chsh -s "$sp" "$su" && echo -e "${GREEN}[✓] Değiştirildi${NC}"
            read -p "Enter..."
            ;;
        12) # Git Install
            read -p "Repo URL: " url
            if [ -n "$url" ]; then
                bd="/tmp/rulefucker_build_$$"
                git clone "$url" "$bd" 2>/dev/null && cd "$bd" || continue
                [ -f Cargo.toml ] && cargo install --path .
                [ -f CMakeLists.txt ] && { mkdir -p build && cd build && cmake .. && make -j$(nproc) && make install; cd ..; }
                [ -f configure ] && ./configure && make -j$(nproc) && make install
                [ -f Makefile ] && make -j$(nproc) && make install
                [ -f setup.py ] && python3 setup.py install
                cd "$SCRIPT_DIR"; rm -rf "$bd"
                echo -e "${GREEN}[✓] Kurulum tamam${NC}"
            fi
            read -p "Enter..."
            ;;
        N1|n1)  # NixOS kernel module
            [ "$DISTRO" = "nixos" ] && nixos_setup_kernel_module || echo -e "${RED}[!] Bu özellik sadece NixOS için.${NC}"
            read -p "Enter..."
            ;;
        N2|n2)  # NixOS restore
            [ "$DISTRO" = "nixos" ] && nixos_restore_config || echo -e "${RED}[!] Bu özellik sadece NixOS için.${NC}"
            read -p "Enter..."
            ;;
        0)  echo -e "${GREEN}Görüşmek üzere.${NC}"; exit 0 ;;
        *)  echo -e "${RED}Geçersiz seçim.${NC}"; sleep 1 ;;
    esac
done
