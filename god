#!/data/data/com.termux/files/usr/bin/bash

# ==========================================
# 1. ล้างแคชและเตรียมหน้าจอ
# ==========================================
hash -r 2>/dev/null
stty sane 2>/dev/null

# กำหนดรหัสสี
C_RESET="\033[0m"
C_CYAN="\033[1;36m"
C_GREEN="\033[1;32m"
C_YELLOW="\033[1;33m"
C_RED="\033[1;31m"
C_PURPLE="\033[1;35m"
C_BLUE="\033[1;34m"
C_WHITE="\033[1;37m"
C_EMERALD="\033[1;92m"
CR="\r\033[K"

# เส้นคั่นความกว้าง 55 ตัวอักษร (พอดีกับโลโก้เป๊ะ)
C_DIV="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
C_SUB="───────────────────────────────────────────────────────"

OWNER_NAME="Suphawat"
DISCORD_LINK="https://discord.gg/VCPAaUy46C"
VALID_PASSWORDS=("1688" "BIG49" "wiwatz" "fku09")
MAX_ATTEMPTS=3
SCRIPT_VERSION="v1.0"

type_text() {
    local text="$1"
    local color="$2"
    echo -ne "${CR}${color}"
    for (( i=0; i<${#text}; i++ )); do
        echo -ne "${text:$i:1}"
        sleep 0.02
    done
    echo -e "${C_RESET}"
}

# ==========================================
# 2. ตรวจสอบสิทธิ์และโปรแกรมเสริม
# ==========================================
if ! command -v curl >/dev/null 2>&1; then
    clear
    echo -e "${CR}${C_YELLOW}⚙️ กำลังตั้งค่าระบบพื้นฐาน (Installing curl)...${C_RESET}"
    pkg install curl -y >/dev/null 2>&1
fi

if [ ! -d "/sdcard/Download" ] || ! touch "/sdcard/Download/.test_perm" 2>/dev/null; then
    clear
    echo -e "${CR}${C_YELLOW}⚠️ ระบบต้องการสิทธิ์เข้าถึงพื้นที่จัดเก็บข้อมูล...${C_RESET}"
    echo -e "${CR}${C_CYAN}กรุณากด 'อนุญาต (Allow)' ที่หน้าจอของคุณ${C_RESET}"
    termux-setup-storage
    sleep 3
fi
rm -f "/sdcard/Download/.test_perm" 2>/dev/null

get_device_info() {
    OS_VER=$(getprop ro.build.version.release 2>/dev/null || echo "?")
    ARCH=$(uname -m 2>/dev/null || echo "?")
    
    local RAM_KB=$(grep MemTotal /proc/meminfo 2>/dev/null || true)
    if [ -n "$RAM_KB" ]; then
        local mem_val=$(echo "$RAM_KB" | awk '{print $2}')
        RAM_GB=$(awk "BEGIN {printf \"%.1f\", $mem_val/1048576}" 2>/dev/null)" GB"
    else
        RAM_GB="?"
    fi
    
    local ROM_TOTAL=$(df -h /sdcard 2>/dev/null | awk 'NR==2 {print $2}')
    local ROM_FREE=$(df -h /sdcard 2>/dev/null | awk 'NR==2 {print $4}')
    if [ -n "$ROM_TOTAL" ]; then
        ROM_INFO="${ROM_TOTAL} (ว่าง ${ROM_FREE})"
    else
        ROM_INFO="?"
    fi
}

check_password() {
    clear
    echo -e "${C_EMERALD}${C_DIV}${C_RESET}"
    echo -e "          ${C_GREEN}⚡ SECURE SYSTEM AUTHENTICATION ⚡${C_RESET}"
    echo -e "${C_EMERALD}${C_DIV}${C_RESET}"
    
    local ATTEMPTS=0
    while [ $ATTEMPTS -lt $MAX_ATTEMPTS ]; do
        echo -ne "${CR} ${C_EMERALD}🔑 กรอกรหัสผ่านระบบ: ${C_RESET}"
        read -s USER_PASS
        echo ""
        
        USER_PASS=$(echo "$USER_PASS" | tr -d '[:space:]' | tr -d '\r')
        
        local IS_CORRECT=0
        for PASS in "${VALID_PASSWORDS[@]}"; do
            if [ "$USER_PASS" == "$PASS" ]; then
                IS_CORRECT=1
                break
            fi
        done
        
        if [ $IS_CORRECT -eq 1 ]; then
            type_text " ✔ รหัสผ่านถูกต้อง! กำลังเชื่อมต่อระบบ..." "$C_EMERALD"
            sleep 0.8
            get_device_info
            return 0
        else
            echo -e "${CR} ${C_RED}❌ รหัสผ่านไม่ถูกต้อง (เหลือโอกาสอีก $((MAX_ATTEMPTS - ATTEMPTS - 1)) ครั้ง)${C_RESET}"
            ATTEMPTS=$((ATTEMPTS + 1))
        fi
    done
    echo -e "${CR} ${C_RED}🚫 ใส่รหัสผิดเกินกำหนด ล็อกระบบชั่วคราว${C_RESET}"
    exit 1
}

# ==========================================
# 3. ระบบติดตั้งแอป
# ==========================================
install_apk() {
    local NAME="$1"
    local URL="$2"
    local TEMP_FILE="/sdcard/Download/temp_app.apk"
    local PID=""
    local DL_STATUS=0

    echo -e "${CR}${C_CYAN}${C_SUB}${C_RESET}"
    rm -f "$TEMP_FILE"
    
    curl -sL -A "Mozilla/5.0" "$URL" -o "$TEMP_FILE" &
    PID=$!
    
    local DOTS=""
    while kill -0 $PID 2>/dev/null; do
        if [ ${#DOTS} -ge 3 ]; then DOTS=""; else DOTS+="."; fi
        echo -ne "${CR} ${C_YELLOW}📥 กำลังดาวน์โหลด: ${C_WHITE}$NAME ${C_CYAN}${DOTS}${C_RESET}"
        sleep 0.4
    done
    wait $PID
    DL_STATUS=$?
    
    echo -e "${CR} ${C_YELLOW}📥 กำลังดาวน์โหลด: ${C_WHITE}$NAME${C_RESET}"

    if [ $DL_STATUS -eq 0 ] && [ -f "$TEMP_FILE" ]; then
        local FILE_SIZE=$(du -k "$TEMP_FILE" | cut -f1)
        if [ "$FILE_SIZE" -gt 1024 ]; then
            chmod 777 "$TEMP_FILE" 2>/dev/null
            
            echo -e "${CR} ${C_GREEN}⚡ กำลังดำเนินการติดตั้ง:${C_RESET} $NAME ..."
            
            if command -v su >/dev/null 2>&1 && su -c "true" >/dev/null 2>&1; then
                su -c "pm install -r \"$TEMP_FILE\"" >/dev/null 2>&1
                local PM_STATUS=$?
                stty sane 2>/dev/null
                
                if [ $PM_STATUS -eq 0 ]; then
                    echo -e "${CR} ${C_GREEN}✅ ติดตั้งแอปเสร็จสมบูรณ์ลงในเครื่องแล้ว!${C_RESET}"
                else
                    echo -e "${CR} ${C_RED}❌ ติดตั้งเบื้องหลังล้มเหลว เรียกหน้าต่างปกติ...${C_RESET}"
                    termux-open --content-type "application/vnd.android.package-archive" "$TEMP_FILE"
                    stty sane 2>/dev/null
                fi
            else
                termux-open --content-type "application/vnd.android.package-archive" "$TEMP_FILE"
                stty sane 2>/dev/null
                echo -e "${CR} ${C_GREEN}✅ เรียกหน้าต่างติดตั้งแล้ว:${C_RESET} (กด 'ติดตั้ง' บนจอ)"
            fi
        else
            echo -e "${CR} ${C_RED}❌ ไฟล์เสีย หรือลิงก์หมดอายุ (พบไฟล์ขนาดแค่ ${FILE_SIZE}KB)${C_RESET}"
            rm -f "$TEMP_FILE"
        fi
    else
        echo -e "${CR} ${C_RED}❌ ดาวน์โหลดล้มเหลว (Error Code: $DL_STATUS)${C_RESET}"
    fi
}

process_selection() {
    local CATEGORY_NAME=$1
    shift
    local APPS=("$@")
    local TOTAL=${#APPS[@]}

    while true; do
        clear
        stty sane 2>/dev/null
        echo -e "${C_CYAN}${C_DIV}${C_RESET}"
        echo -e "                📁 หมวดหมู่: ${C_YELLOW}$CATEGORY_NAME${C_RESET}"
        echo -e "${C_CYAN}${C_DIV}${C_RESET}"
        
        for i in "${!APPS[@]}"; do
            echo -e "${CR}  ${C_PURPLE}[$((i+1))]${C_RESET} ${C_BLUE}▸${C_RESET} $CATEGORY_NAME $((i+1))"
        done
        
        echo -e "${CR}${C_CYAN}${C_SUB}${C_RESET}"
        echo -e "${CR}  💡 ${C_YELLOW}พิมพ์หมายเลข (1-${TOTAL}), ช่วง (เช่น 1-3) หรือ all${C_RESET}"
        echo -e "${CR}     ${C_WHITE}(พิมพ์ 0 เพื่อกลับไปหน้าเมนูหลัก)${C_RESET}"
        echo -e "${CR}${C_CYAN}${C_SUB}${C_RESET}"

        echo -ne "${CR}  🎯 ${C_GREEN}เลือกรายการ: ${C_RESET}"
        read INPUT_CHOICE
        echo ""

        if [ "$INPUT_CHOICE" == "0" ]; then
            return 0
        fi

        local SELECTED_INDICES=()
        local VALID_INPUT=0

        if [ "$INPUT_CHOICE" == "all" ] || [ "$INPUT_CHOICE" == "ALL" ]; then
            for i in "${!APPS[@]}"; do
                SELECTED_INDICES+=($i)
            done
            VALID_INPUT=1
        else
            for ITEM in $INPUT_CHOICE; do
                if [[ "$ITEM" =~ ^([0-9]+)-([0-9]+)$ ]]; then
                    local START=${BASH_REMATCH[1]}
                    local END=${BASH_REMATCH[2]}
                    
                    if [ "$START" -gt "$END" ]; then
                        local TEMP_NUM=$START
                        START=$END
                        END=$TEMP_NUM
                    fi

                    for ((i=START; i<=END; i++)); do
                        if [ $((i-1)) -ge 0 ] && [ $((i-1)) -lt $TOTAL ]; then
                            SELECTED_INDICES+=($((i-1)))
                            VALID_INPUT=1
                        fi
                    done
                elif [[ "$ITEM" =~ ^[0-9]+$ ]]; then
                    if [ $((ITEM-1)) -ge 0 ] && [ $((ITEM-1)) -lt $TOTAL ]; then
                        SELECTED_INDICES+=($((ITEM-1)))
                        VALID_INPUT=1
                    fi
                fi
            done
        fi

        if [ $VALID_INPUT -eq 1 ]; then
            clear
            stty sane 2>/dev/null
            echo -e "${C_CYAN}${C_DIV}${C_RESET}"
            echo -e "                 ${C_GREEN}🚀 กำลังดำเนินการติดตั้ง${C_RESET}"
            echo -e "${C_CYAN}${C_DIV}${C_RESET}"

            for INDEX in "${SELECTED_INDICES[@]}"; do
                install_apk "$CATEGORY_NAME $((INDEX+1))" "${APPS[$INDEX]}"
            done
            
            echo -e "${CR}${C_CYAN}${C_SUB}${C_RESET}"
            echo -ne "${CR}  ✨ ${C_YELLOW}กด Enter เพื่อกลับไปหน้าเลือกแอป...${C_RESET}"
            read
        else
            echo -e "${CR}  ${C_RED}[!] หมายเลขไม่ถูกต้อง (เลือกได้เฉพาะ 1-${TOTAL} หรือ all)${C_RESET}"
            sleep 1.2
        fi
    done
}

DELTA_APPS=(
  "https://github.com/suphawatinf/INFINITESHOP/releases/download/V1.0/Delta.by.Suphawat.1_2.738.1397.apk"
  "https://github.com/suphawatinf/INFINITESHOP/releases/download/V1.0/Delta.by.Suphawat.2_2.738.1397.apk"
  "https://github.com/suphawatinf/INFINITESHOP/releases/download/V1.0/Delta.by.Suphawat.3_2.738.1397.apk"
  "https://github.com/suphawatinf/INFINITESHOP/releases/download/V1.0/Delta.by.Suphawat.4_2.738.1397.apk"
  "https://github.com/suphawatinf/INFINITESHOP/releases/download/V1.0/Delta.by.Suphawat.5_2.738.1397.apk"
  "https://github.com/suphawatinf/INFINITESHOP/releases/download/V1.0/Delta.by.Suphawat.6_2.738.1397.apk"
  "https://github.com/suphawatinf/INFINITESHOP/releases/download/V1.0/Delta.by.Suphawat.7_2.738.1397.apk"
  "https://github.com/suphawatinf/INFINITESHOP/releases/download/V1.0/Delta.by.Suphawat.8_2.738.1397.apk"
)

DELTA_LITE_APPS=(
  "https://github.com/suphawatinf/INFINITESHOP/releases/download/V1.0/Delta.lite.by.Suphawat.1_2.738.1397.apk"
  "https://github.com/suphawatinf/INFINITESHOP/releases/download/V1.0/Delta.lite.by.Suphawat.2_2.738.1397.apk"
  "https://github.com/suphawatinf/INFINITESHOP/releases/download/V1.0/Delta.lite.by.Suphawat.3_2.738.1397.apk"
  "https://github.com/suphawatinf/INFINITESHOP/releases/download/V1.0/Delta.lite.by.Suphawat.4_2.738.1397.apk"
  "https://github.com/suphawatinf/INFINITESHOP/releases/download/V1.0/Delta.lite.by.Suphawat.5_2.738.1397.apk"
  "https://github.com/suphawatinf/INFINITESHOP/releases/download/V1.0/Delta.lite.by.Suphawat.6_2.738.1397.apk"
  "https://github.com/suphawatinf/INFINITESHOP/releases/download/V1.0/Delta.lite.by.Suphawat.7_2.738.1397.apk"
  "https://github.com/suphawatinf/INFINITESHOP/releases/download/V1.0/Delta.lite.by.Suphawat.8_2.738.1397.apk"
)

ARCEUS_NORMAL_APPS=(
  "https://github.com/suphawatinf/INFINITESHOP/releases/download/V1.0/ArceusX.by.Suphawat.1_2.739.691.apk"
  "https://github.com/suphawatinf/INFINITESHOP/releases/download/V1.0/ArceusX.by.Suphawat.2_2.739.691.apk"
  "https://github.com/suphawatinf/INFINITESHOP/releases/download/V1.0/ArceusX.by.Suphawat.3_2.739.691.apk"
  "https://github.com/suphawatinf/INFINITESHOP/releases/download/V1.0/ArceusX.by.Suphawat.4_2.739.691.apk"
  "https://github.com/suphawatinf/INFINITESHOP/releases/download/V1.0/ArceusX.by.Suphawat.5_2.739.691.apk"
  "https://github.com/suphawatinf/INFINITESHOP/releases/download/V1.0/ArceusX.by.Suphawat.6_2.739.691.apk"
  "https://github.com/suphawatinf/INFINITESHOP/releases/download/V1.0/ArceusX.by.Suphawat.7_2.739.691.apk"
  "https://github.com/suphawatinf/INFINITESHOP/releases/download/V1.0/ArceusX.by.Suphawat.8_2.739.691.apk"
)

ARCEUS_LITE_APPS=(
  "https://github.com/suphawatinf/INFINITESHOP/releases/download/V1.0/ArceusX.lite.by.Suphawat.1_2.739.691.apk"
  "https://github.com/suphawatinf/INFINITESHOP/releases/download/V1.0/ArceusX.lite.by.Suphawat.2_2.739.691.apk"
  "https://github.com/suphawatinf/INFINITESHOP/releases/download/V1.0/ArceusX.lite.by.Suphawat.3_2.739.691.apk"
  "https://github.com/suphawatinf/INFINITESHOP/releases/download/V1.0/ArceusX.lite.by.Suphawat.4_2.739.691.apk"
  "https://github.com/suphawatinf/INFINITESHOP/releases/download/V1.0/ArceusX.lite.by.Suphawat.5_2.739.691.apk"
  "https://github.com/suphawatinf/INFINITESHOP/releases/download/V1.0/ArceusX.lite.by.Suphawat.6_2.739.691.apk"
  "https://github.com/suphawatinf/INFINITESHOP/releases/download/V1.0/ArceusX.lite.by.Suphawat.7_2.739.691.apk"
  "https://github.com/suphawatinf/INFINITESHOP/releases/download/V1.0/ArceusX.lite.by.Suphawat.8_2.739.691.apk"
)

check_password

while true; do
    clear
    stty sane 2>/dev/null
    echo -e "${C_CYAN} ██╗███╗   ██╗███████╗██╗███╗   ██╗██╗████████╗███████╗${C_RESET}"
    echo -e "${C_CYAN} ██║████╗  ██║██╔════╝██║████╗  ██║██║╚══██╔══╝██╔════╝${C_RESET}"
    echo -e "${C_CYAN} ██║██╔██╗ ██║█████╗  ██║██╔██╗ ██║██║   ██║   █████╗  ${C_RESET}"
    echo -e "${C_CYAN} ██║██║╚██╗██║██╔══╝  ██║██║╚██╗██║██║   ██║   ██╔══╝  ${C_RESET}"
    echo -e "${C_CYAN} ██║██║ ╚████║██║     ██║██║ ╚████║██║   ██║   ███████╗${C_RESET}"
    echo -e "${C_CYAN} ╚═╝╚═╝  ╚═══╝╚═╝     ╚═╝╚═╝  ╚═══╝╚═╝   ╚═╝   ╚══════╝${C_RESET}"
    echo -e "${C_YELLOW}                 [ INFINITE SHOP $SCRIPT_VERSION ]${C_RESET}"
    echo -e "${C_CYAN}${C_DIV}${C_RESET}"
    echo -e "  👑 ${C_WHITE}Dev${C_RESET}  : $OWNER_NAME"
    echo -e "  💬 ${C_WHITE}Disc${C_RESET} : $DISCORD_LINK"
    echo -e "${C_CYAN}${C_SUB}${C_RESET}"
    echo -e "  📱 ${C_GREEN}OS${C_RESET}   : Android $OS_VER | $ARCH"
    echo -e "  💾 ${C_GREEN}MEM${C_RESET}  : RAM $RAM_GB | ROM $ROM_INFO"
    echo -e "${C_CYAN}${C_DIV}${C_RESET}"
    
    echo -e "${CR}  ${C_PURPLE}[1]${C_RESET} Delta        (${C_GREEN}${#DELTA_APPS[@]}${C_RESET} Apps)"
    echo -e "${CR}  ${C_PURPLE}[2]${C_RESET} Delta lite   (${C_GREEN}${#DELTA_LITE_APPS[@]}${C_RESET} Apps)"
    echo -e "${CR}  ${C_PURPLE}[3]${C_RESET} ArceusX      (${C_GREEN}${#ARCEUS_NORMAL_APPS[@]}${C_RESET} Apps)"
    echo -e "${CR}  ${C_PURPLE}[4]${C_RESET} ArceusX lite (${C_GREEN}${#ARCEUS_LITE_APPS[@]}${C_RESET} Apps)"
    echo -e "${CR}  ${C_RED}[0] ออกจากระบบ${C_RESET}"
    echo -e "${CR}${C_CYAN}${C_SUB}${C_RESET}"
    echo -ne "${CR}  🎯 ${C_GREEN}เลือกหมวดหมู่ที่ต้องการ (0-4): ${C_RESET}"
    read MAIN_CHOICE
    echo ""

    case $MAIN_CHOICE in
        1) process_selection "Delta" "${DELTA_APPS[@]}" ;;
        2) process_selection "Delta lite" "${DELTA_LITE_APPS[@]}" ;;
        3) process_selection "ArceusX" "${ARCEUS_NORMAL_APPS[@]}" ;;
        4) process_selection "ArceusX lite" "${ARCEUS_LITE_APPS[@]}" ;;
        0) break ;;
        *) 
            echo -e "${CR}  ${C_RED}[!] เลือกเมนูไม่ถูกต้อง (เลือกได้เฉพาะ 0-4)${C_RESET}" 
            sleep 1.2
            ;;
    esac
done

stty sane 2>/dev/null
clear
echo -e "${C_CYAN}${C_DIV}${C_RESET}"
echo -e "                ${C_GREEN}✨ ออกจากระบบเรียบร้อย ✨${C_RESET}"
echo -e "${C_CYAN}${C_DIV}${C_RESET}"
echo ""
