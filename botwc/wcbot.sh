#!/bin/bash
# ─────────────────────────────────────────────────────────────
#  BOT WILDCARD CLOUDFLARE INSTALLER (Fixed for Debian/Ubuntu)
#  Diperbaiki: Python path, venv detection, systemd service
# ─────────────────────────────────────────────────────────────

clear

# === Warna & Gaya ===
BOLD="\033[1m"
DIM="\033[2m"
RESET="\033[0m"

FG_WHITE="\033[1;97m"
FG_GRAY="\033[0;37m"
FG_YELLOW="\033[1;33m"
FG_GREEN="\033[1;32m"
FG_RED="\033[1;31m"
FG_CYAN="\033[1;36m"
FG_MAGENTA="\033[1;35m"

BLINK_GREEN="\033[5;32m"

# Legacy vars
greenBe="\033[5;32m"
grenbo="\e[92;1m"
NC='\e[0m'

# === Ikon ===
ICO_START="🚀"
ICO_STEP="▸"
ICO_OK="✔"
ICO_FAIL="✖"
ICO_INFO="ℹ"
ICO_WARN="⚠"
ICO_GEAR="⚙"
ICO_BOX="◆"

URL="https://raw.githubusercontent.com/kcepu877/V1/main/botwc/botwildcard.zip"

# === Banner ===
line() { printf "${FG_WHITE}%s${RESET}\n" "──────────────────────────────────────────────────────────────"; }
title() {
  line
  printf "${FG_MAGENTA}${BOLD}✦ BOT WILDCARD CLOUDFLARE — INSTALLER ✦${RESET}\n"
  printf "${FG_GRAY}${DIM}OS-aware • Python venv fallback • systemd • cron uploader${RESET}\n"
  line
}

# === Notifikasi ringkas ===
ok()    { printf "${FG_GREEN}${ICO_OK} %s${RESET}\n" "$*"; }
fail()  { printf "${FG_RED}${ICO_FAIL} %s${RESET}\n" "$*"; }
info()  { printf "${FG_CYAN}${ICO_INFO} %s${RESET}\n" "$*"; }
warn()  { printf "${FG_YELLOW}${ICO_WARN} %s${RESET}\n" "$*"; }
step()  { printf "${FG_WHITE}${ICO_STEP} ${BOLD}%s${RESET}\n" "$*"; }

title

# === Stop & Bersih-bersih service lama ===
step "Membersihkan service & folder lama"
systemctl stop botcf >/dev/null 2>&1
systemctl disable botcf >/dev/null 2>&1
rm -rf /etc/systemd/system/botcf.service >/dev/null 2>&1
systemctl daemon-reload >/dev/null 2>&1
rm -rf /root/botcf >/dev/null 2>&1
ok "Service lama dibersihkan"

# === Deteksi OS ===
OS_ID=$(grep -oP '(?<=^ID=).+' /etc/os-release | tr -d '"')
OS_VERSION=$(grep -oP '(?<=^VERSION_ID=).+' /etc/os-release | tr -d '"')
OS_VERSION_CLEAN=${OS_VERSION//./}
OS_MAJOR="${OS_VERSION_CLEAN:0:2}"

printf "${FG_YELLOW}${BOLD}${ICO_GEAR} Deteksi OS:${RESET} %s %s\n" "$OS_ID" "$OS_VERSION"

# === Install Python dan dependencies ===
step "Mempersiapkan Python dan dependencies"
apt update && apt install -y python3 python3-pip python3-venv python3-dev curl jq unzip dos2unix git
ok "Dependencies terinstall"

# === Tentukan Python path berdasarkan kondisi ===
PYTHON_EXEC=""
VENV_PATH="/root/botcf/venv"

# Cek apakah Python 3 tersedia
if command -v python3 &> /dev/null; then
    # Buat virtual environment di folder botcf
    mkdir -p /root/botcf
    python3 -m venv "$VENV_PATH" 2>/dev/null
    
    if [ -f "$VENV_PATH/bin/python" ]; then
        PYTHON_EXEC="$VENV_PATH/bin/python"
        info "Menggunakan virtual environment: $PYTHON_EXEC"
        
        # Install packages di venv
        "$VENV_PATH/bin/pip" install --upgrade pip setuptools wheel
        "$VENV_PATH/bin/pip" install requests aiogram==2.25.1 aiohttp
        ok "Packages terinstall di venv"
    else
        # Fallback ke system python3
        PYTHON_EXEC="/usr/bin/python3"
        warn "Virtual environment gagal, menggunakan system Python"
        pip3 install --upgrade pip setuptools wheel
        pip3 install requests aiogram==2.25.1 aiohttp
    fi
else
    fail "Python3 tidak ditemukan!"
    exit 1
fi

# === Tools arsip & util ===
step "Instal utilitas pendukung (zip, git, unzip, dos2unix)"
apt install -y zip unzip dos2unix -qq
ok "Utilitas siap"

# === Unduh & ekstrak bot ===
step "Unduh paket bot: ${URL}"
cd /root
curl -sSL "$URL" -o botwildcard.zip 
if [ $? -eq 0 ]; then
    ok "Unduhan selesai"
else
    warn "Unduhan mungkin bermasalah, melanjutkan..."
fi

step "Ekstrak paket"
unzip -q botwildcard.zip -d botwildcard_temp 2>/dev/null || true

# Cari dan pindahkan file
if [ -d "botwildcard_temp" ]; then
    mkdir -p /root/botcf
    # Cari dan pindahkan semua file yang ada
    find botwildcard_temp -type f -name "*.py" -exec mv {} /root/botcf/ \;
    find botwildcard_temp -type f -name "*.sh" -exec mv {} /root/botcf/ \;
    find botwildcard_temp -type f -name "*.json" -exec mv {} /root/botcf/ \;
    
    # Pastikan add-wc.sh ada dan executable
    if [ -f "/root/botcf/add-wc.sh" ]; then
        dos2unix /root/botcf/add-wc.sh >/dev/null 2>&1
        chmod +x /root/botcf/add-wc.sh
        ok "Script add-wc.sh siap"
    else
        # Buat file add-wc.sh dummy jika tidak ada
        cat > /root/botcf/add-wc.sh << 'EOF'
#!/bin/bash
echo "Wildcard script placeholder"
echo "User ID: $1"
echo "Zone ID: $2"
echo "Subdomain: $3"
EOF
        chmod +x /root/botcf/add-wc.sh
        warn "add-wc.sh tidak ditemukan, membuat placeholder"
    fi
fi

# Bersihkan
rm -rf botwildcard_temp botwildcard.zip 2>/dev/null
ok "Paket terpasang di /root/botcf"

# === UI input ===
line
printf "${FG_WHITE}${BOLD}${ICO_BOX} ADD BOT WILDCARD CLOUDFLARE${RESET}\n"
line
printf "${FG_YELLOW}• Bisa masukkan lebih dari 1 Admin (pisahkan dengan koma)${RESET}\n"
printf "${FG_GRAY}  Contoh: 8166206712, 7114686701, 7109036965${RESET}\n\n"

read -e -p "$(printf "${FG_CYAN}Bot Token   : ${RESET}")" tokenbot
read -e -p "$(printf "${FG_CYAN}ID Telegram : ${RESET}")" idtele
printf "\n"
line

# === Inject token & admin list ke bot-cloudflare.py ===
step "Menulis konfigurasi bot ke bot-cloudflare.py"
if [ ! -f "/root/botcf/bot-cloudflare.py" ]; then
    # Jika file tidak ada, buat dari template
    cat > /root/botcf/bot-cloudflare.py << 'EOF'
import logging
import requests
import asyncio
import os
import json
import uuid
import re
from aiogram import types
import subprocess 
from typing import Union
from aiogram import Bot, Dispatcher, types
from aiogram.types import ReplyKeyboardMarkup, KeyboardButton
from aiogram.types import InlineKeyboardMarkup, InlineKeyboardButton
from aiogram.dispatcher import FSMContext
from aiogram.contrib.fsm_storage.memory import MemoryStorage
from aiogram.dispatcher.filters.state import State, StatesGroup
from aiogram.utils import executor
from aiogram.utils.callback_data import CallbackData

# ... (konten bot akan diisi otomatis dari zip)
EOF
    warn "File bot-cloudflare.py dibuat baru"
fi

# Escape karakter khusus untuk sed
escaped_token=$(printf '%s\n' "$tokenbot" | sed -e 's/[\/&]/\\&/g')
idtele_cleaned=$(echo "$idtele" | tr -d '[:space:]')

# Update token dan admin IDs
if grep -q "^API_TOKEN\s*=" /root/botcf/bot-cloudflare.py; then
    sed -i "s/^API_TOKEN\s*=.*/API_TOKEN = \"${escaped_token}\"/" /root/botcf/bot-cloudflare.py
else
    # Jika tidak ada line API_TOKEN, tambahkan di atas bot = Bot(...)
    sed -i "/^bot = Bot(/i API_TOKEN = \"${escaped_token}\"" /root/botcf/bot-cloudflare.py
fi

if grep -q "^ADMIN_IDS\s*=" /root/botcf/bot-cloudflare.py; then
    sed -i "s/^ADMIN_IDS\s*=.*/ADMIN_IDS = [${idtele_cleaned}]/" /root/botcf/bot-cloudflare.py
else
    # Jika tidak ada line ADMIN_IDS, tambahkan setelah API_TOKEN
    sed -i "/^API_TOKEN = /a ADMIN_IDS = [${idtele_cleaned}]" /root/botcf/bot-cloudflare.py
fi

ok "Konfigurasi tersimpan"

# === Buat service systemd yang FIX ===
step "Mendaftarkan service systemd: botcf"

# Tentukan working directory dan Python path yang benar
WORKING_DIR="/root/botcf"
if [ -f "$VENV_PATH/bin/python" ]; then
    PYTHON_CMD="$VENV_PATH/bin/python"
else
    PYTHON_CMD="/usr/bin/python3"
fi

cat > /etc/systemd/system/botcf.service << END
[Unit]
Description=Simple Bot Wildcard - Cloudflare DNS Manager
After=network.target
Wants=network.target

[Service]
Type=simple
User=root
WorkingDirectory=${WORKING_DIR}
ExecStart=${PYTHON_CMD} ${WORKING_DIR}/bot-cloudflare.py
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
Environment=PYTHONUNBUFFERED=1

[Install]
WantedBy=multi-user.target
END

ok "Service file dibuat di /etc/systemd/system/botcf.service"

# === Script kirim file user list via Telegram ===
idku=$(echo "$idtele" | cut -d',' -f1 | tr -d '[:space:]')

# === Konfigurasi ===
BOT_TOKEN="${tokenbot}"
CHAT_ID="${idku}"
SCRIPT_PATH="/usr/bin/list_all_userbot"
LOG_PATH="/var/log/list_all_userbot.log"

step "Menyiapkan helper uploader (list_all_userbot)"
if [ -f "$SCRIPT_PATH" ]; then
    warn "File script sudah ada. Menghapus lama..."
    rm -f "$SCRIPT_PATH"
fi

cat <<EOF > "$SCRIPT_PATH"
#!/bin/bash
# Auto upload user lists to Telegram
BOT_TOKEN="${BOT_TOKEN}"
CHAT_ID="${CHAT_ID}"
FILE="/root/botcf/all_users.json"
FILE_2="/root/botcf/allowed_users.json"

# Upload all_users.json jika ada
if [ -f "\$FILE" ] && [ -s "\$FILE" ]; then
  curl -s -F chat_id="\$CHAT_ID" -F document=@"\$FILE" "https://api.telegram.org/bot\$BOT_TOKEN/sendDocument" >/dev/null 2>&1
fi

# Upload allowed_users.json jika ada
if [ -f "\$FILE_2" ] && [ -s "\$FILE_2" ]; then
  curl -s -F chat_id="\$CHAT_ID" -F document=@"\$FILE_2" "https://api.telegram.org/bot\$BOT_TOKEN/sendDocument" >/dev/null 2>&1
fi

echo "\$(date): Upload script executed" >> "${LOG_PATH}"
EOF

chmod +x "$SCRIPT_PATH"
dos2unix "$SCRIPT_PATH" >/dev/null 2>&1
ok "Helper uploader siap: $SCRIPT_PATH"

# === Cron job setiap 5 jam pada menit 0 ===
step "Mengatur cron uploader (setiap 5 jam)"
TMP_CRON=$(mktemp)
crontab -l 2>/dev/null | grep -v "$SCRIPT_PATH" > "$TMP_CRON"
echo "0 */5 * * * $SCRIPT_PATH >> $LOG_PATH 2>&1" >> "$TMP_CRON"
crontab "$TMP_CRON"
rm "$TMP_CRON"
ok "Cron job diperbarui"

# === Enable & start service ===
step "Mengaktifkan service botcf"
systemctl daemon-reload
systemctl enable botcf >/dev/null 2>&1
systemctl start botcf
sleep 2

# Cek status service
if systemctl is-active --quiet botcf; then
    ok "Service botcf berjalan"
    
    # Cek logs awal
    echo ""
    info "Status service:"
    systemctl status botcf --no-pager -l | head -20
    
    echo ""
    info "Logs terakhir:"
    journalctl -u botcf -n 5 --no-pager 2>/dev/null || echo "Belum ada logs"
else
    warn "Service gagal start, cek manual:"
    echo "sudo systemctl status botcf"
    echo "sudo journalctl -u botcf -f"
fi

# === Finishing ===
step "Membersihkan file installer"
cd /root
rm -f bot-wildcard.sh 2>/dev/null

line
printf "${BLINK_GREEN}${BOLD}✅ SUCCESS: Bot Wildcard Cloudflare Terinstall!${RESET}\n"
line
echo ""
printf "${FG_CYAN}${BOLD}📋 INFORMASI INSTALASI:${RESET}\n"
printf "${FG_WHITE}• Bot Token    : ${FG_GREEN}${tokenbot:0:10}...${RESET}\n"
printf "${FG_WHITE}• Admin IDs    : ${FG_GREEN}${idtele}${RESET}\n"
printf "${FG_WHITE}• Python Path  : ${FG_GREEN}${PYTHON_EXEC}${RESET}\n"
printf "${FG_WHITE}• Service Name : ${FG_GREEN}botcf${RESET}\n"
printf "${FG_WHITE}• Folder Bot   : ${FG_GREEN}/root/botcf${RESET}\n"
printf "${FG_WHITE}• Uploader Cron: ${FG_GREEN}setiap 5 jam${RESET}\n"
echo ""
printf "${FG_YELLOW}${BOLD}🚀 PERINTAH MONITORING:${RESET}\n"
printf "${FG_WHITE}  sudo systemctl status botcf${RESET}\n"
printf "${FG_WHITE}  sudo journalctl -u botcf -f${RESET}\n"
printf "${FG_WHITE}  sudo systemctl restart botcf${RESET}\n"
echo ""
printf "${FG_GREEN}${BOLD}✅ BOT SIAP DIGUNAKAN!${RESET}\n"
printf "${FG_WHITE}Buka Telegram dan ketik /start ke bot Anda.${RESET}\n"
line

# Exit dengan success
exit 1
