#!/bin/bash


if [ "$(id -u)" -ne 0 ]; then
    echo "[ ! ] No Root Access"
    exit 1
fi

# 52 Character.

bold="\e[1m"
reset="\e[0m"
cyan="\e[96m"
green="\e[92m"
yellow="\e[93m"
purple="\e[95m"
blue="\e[94m"
grey="\e[90m"


package_name="com.mobile.legends"
backup_dir="/data/local/tmp/backup/"
file="/data/data/com.mobile.legends/shared_prefs/com.mobile.legends.v2.playerprefs.xml"

# Mencari direktori data aplikasi
data_dir=$(ls -d /data/data/$package_name /data/user/*/$package_name 2>/dev/null | head -n 1)

function header() {
  echo -e "\n "
  echo -e "\e[92m──(ML Switcher by)────────────────────\e[0m"
  echo '    __  ___     __    __     '
  echo '   /  |/  /__  / /__ / /____ '
  echo '  / /|_/ / _ \/ / -_) __/ _ \'
  echo ' /_/  /_/\___/_/\__/\__/\___/'  # ASCII Art by figlet
  echo " "
  echo -e "\e[92m───────────────────────────────────────\e[0m"
}

editFPS() {
  echo "Please Wait..."
  local file_path="/data/data/com.mobile.legends/shared_prefs/com.mobile.legends.v2.playerprefs.xml"
  local tag_updates="HighFpsMode=120;RecommendPicFPS_BestQuality_new=4;RecommendPicFPS_BestFrameRate_new=120;HighFpsModeSee=4;PerformanceDevice_BestFrameRate=120"
  local IFS=";"

  if [ ! -f "$file_path" ]; then
    menu "Error: File '$file_path' tidak ditemukan."
  fi

  local temp_file=$(mktemp)
  local tag_updated=false

  # Proses file, menimpa tag yang ada
  cat "$file_path" | while IFS= read -r line; do
    local line_matched=false
    for update in $tag_updates; do
      local current_tag_name=$(echo "$update" | cut -d'=' -f1)
      local current_tag_value=$(echo "$update" | cut -d'=' -f2)
      local expected_tag_start="<${current_tag_name} name=\""

      if echo "$line" | grep -q "^[[:space:]]*$expected_tag_start"; then
        echo "    <int name=\"${current_tag_name}\" value=\"${current_tag_value}\" />" >> "$temp_file"
        line_matched=true
        tag_updated=true # Setidaknya satu tag sudah diperbarui
        break
      fi
    done
    if [ "$line_matched" = false ]; then
      echo "$line" >> "$temp_file"
    fi
  done

  # Tambahkan tag yang tidak ditemukan
  local map_tag_found=false
  cat "$temp_file" | while IFS= read -r final_line; do
    echo "$final_line" >> "$file_path.new"
    if [[ "$final_line" == "<map>" ]] && [ "$map_tag_found" = false ]; then
      map_tag_found=true
      for update in $tag_updates; do
        local current_tag_name=$(echo "$update" | cut -d'=' -f1)
        local current_tag_value=$(echo "$update" | cut -d'=' -f2)
        local expected_tag_start="<${current_tag_name} name=\""
        if ! grep -q "$expected_tag_start" "$temp_file"; then
          echo "    <int name=\"${current_tag_name}\" value=\"${current_tag_value}\" />" >> "$file_path.new"
        fi
      done
    fi
  done

  mv "$file_path.new" "$file_path"
  rm "$temp_file"
  menu "Logs: \n Berhasil unlock FPS Ultra!"
}

# Mencadangkan akun lama
function backup() {
  clear
  header
  echo -e "\e[94mNew Backup Account!\e[0m"
  echo " "
  echo -e "Fungsi:\n"
  echo " - Menambahkan akun ke ganti akun"
  echo " - Mencadangkan akun yang belum dikaitkan"
  echo " "
  echo -e "\e[3m$1 \e[0m"  # Log pesan
  echo "┌──( Nama Akun: )─[ 0. Back ]"
  echo -n "└─❯ "
  read newBackup
  
  if echo "$folder" | grep -q '/'; then
    menu "Logs:\n Tidak boleh menggunakan garing(/)"
  fi
  
  if [ -z "$folder" ]; then
    menu "Logs: \n invalid input"
  fi
  
  # Memeriksa apakah input kosong
  if [[ -z "$newBackup" ]]; then
    echo "Masukkan nama akun saat ini."
    return
  fi

  # Memeriksa apakah input adalah angka 0
  if [[ "$newBackup" == "0" ]]; then
    echo "Kembali ke menu..."
    menu
    return
  fi

  # Variabel direktori cadangan (pastikan sudah didefinisikan sebelumnya)
  backup_dir="/data/local/tmp/backup"
  data_dir="/data/data/com.mobile.legends/"

  # Membuat folder cadangan
  mkdir -p "$backup_dir/$newBackup"
  cp -rp "$data_dir"/* "$backup_dir/$newBackup"

  # Memeriksa hasil pembuatan folder
  if [ -d "$backup_dir/$newBackup" ]; then
    menu "Logs:\n Akun '$newBackup' berhasil dicadangkan."
  else
    menu "Logs:\n Terjadi kesalahan saat membuat folder backup untuk $newBackup."
  fi
}

# Style List Account
function list_folders {
  for folder_path in /data/local/tmp/backup/*/ ; do
    if [[ -d "$folder_path" ]]; then
      folder_name=$(basename "$folder_path")
      echo "${yellow}    ➤ $folder_name${reset}"
    fi
  done
}
# Ganti akun
function switchAc() {
  # Memulai ganti akun
  su -c "am force-stop com.mobile.legends"
  clear
  header
  echo "Switch Account"
  echo " "
  echo -e "\e[96m List Account: \e[0m"
  list_folders
  echo " "
  echo -e "\e[3mmasukan angka 0 untuk kembali !!\e[0m"
  echo "┌──( Ganti ke: )"
  echo -n "└─❯ "
  read folder # Memilih akun

  if [ "$folder" == "0" ] || [ -z "$folder" ]; then
    menu "Log:\n Kembali ke menu.\n"
    return
  fi
  
  if echo "$folder" | grep -q '/'; then
    menu "Logs:\n Tidak boleh menggunakan garing(/)"
  fi
    
  backup_akun_dir="$backup_dir/$folder"

  # Periksa apakah akun yang dipilih ada
  if [ ! -d "$backup_akun_dir" ]; then
    menu "Log:\n Akun $folder Tidak Ditemukan\n"
    return
  fi

  # Periksa apakah direktori data aplikasi ditemukan (asumsi $data_dir dan $package_name sudah didefinisikan di luar potongan ini)
  if [ -z "$data_dir" ]; then
    menu "Log:\n Aplikasi $package_name Tidak Ditemukan!\n"
    return
  fi
  
  clear
  echo "Memulai ganti akun ke $folder..."
  sleep 1
  echo "Menghapus akun lama..."
  rm -rf "$data_dir"/*
  rm -rf "$data_dir"/.*
  sleep 1
  su -c "mv /sdcard/Android/data/com.mobile.legends /sdcard/Android/data/com.mobile.legends.bb"
  sleep 0.3
  pm clear com.mobile.legends
  echo "Mengganti dengan akun $folder..."
  cp -rp "$backup_akun_dir"/* "$data_dir"/

  # Setel ulang kepemilikan dan permission file/folder
  chown -R "$(stat -c "%u" /data/data)" "$(stat -c "%g" /data/data)" "$data_dir"
  sleep 0.5
  chmod -R 771 "$data_dir"
  find "$data_dir" -type f -exec chmod 660 {} \;
  echo "Memulihkan data..."
  su -c "mv /sdcard/Android/data/com.mobile.legends.bb /sdcard/Android/data/com.mobile.legends"
  sleep 0.2
  menu "Logs :\n Berhasil mengganti ke $folder"
}

function newAccount() {
  su -c "am force-stop com.mobile.legends"
  deleteAc(){
    
    clear
    echo "Memulai pembuatan akun..."
    sleep 1.0
    echo "Mengamankan data..."
    su -c "mv /sdcard/Android/data/com.mobile.legends /sdcard/Android/data/com.mobile.legends.bb"
    echo "Membersihkan GMS Core..."
    su -c "pm clear com.google.android.gms"
    echo "Menghapus akun lama dari folder root..."
    su -c "pm clear com.mobile.legends"
    sleep 5.0
    su -c "mv /sdcard/Android/data/com.mobile.legends.bb /sdcard/Android/data/com.mobile.legends"
  
    sleep 3.0
    menu "Logs :\n Buat akun Baru Success!"
    
  }

  clear
  
  echo "( ! ) Akun yang saat ini anda gunakan akan \n      kehapus/logout\n"
  echo ' • Apa kamu yakin?'
  
  echo "┌──( Y/N: )"
  echo -n "└─❯ "
  read lanjut # Memilih akun

  # Kembali ke menu jika input adalah 0
  case "$lanjut" in
    "Y"|"y")
      deleteAc ;; # Panggil fungsi switch
    "N"|"n")
      menu ;; # Panggil fungsi newAccount
    *)
      menu "Logs :\n Input tidak valid.\n" ;; # Default case
  esac

}


fpsUltra() {
  su -c "am force-stop com.mobile.legends"
  local file="/data/data/com.mobile.legends/shared_prefs/com.mobile.legends.v2.playerprefs.xml"

  if [ ! -f "$file" ]; then
    echo "Error: File '$file' tidak ditemukan."
    return 1
  fi

  local high_fps_line='<int name="HighFpsMode" value="120" />'
  local high_fps_see_line='<int name="HighFpsModeSee" value="4" />'
  local best_frame_rate_line='<int name="PerformanceDevice_BestFrameRate" value="120" />'

  local temp_file=$(mktemp)

  echo "Mulai memproses file: $file"

  while IFS= read -r line; do
    case "$line" in
      *"name=\"HighFpsMode\""* )
        echo "Mengganti baris HighFpsMode"
        echo "$high_fps_line" >> "$temp_file"
        ;;
      *"name=\"HighFpsModeSee\""* )
        echo "Mengganti baris HighFpsModeSee"
        echo "$high_fps_see_line" >> "$temp_file"
        ;;
      *"name=\"PerformanceDevice_BestFrameRate\""* )
        echo "Mengganti baris PerformanceDevice_BestFrameRate"
        echo "$best_frame_rate_line" >> "$temp_file"
        ;;
      "<map>" )
        echo "Menemukan tag <map>, menambahkan baris baru"
        echo "$line" >> "$temp_file"
        echo "    $high_fps_line" >> "$temp_file"
        echo "    $high_fps_see_line" >> "$temp_file"
        echo "    $best_frame_rate_line" >> "$temp_file"
        ;;
      *)
        echo "$line" >> "$temp_file"
        ;;
    esac
  done < "$file"

  if [ -f "$temp_file" ]; then
    echo "File temporary berhasil dibuat: $temp_file"
    mv "$temp_file" "$file"
    if [ $? -eq 0 ]; then
      echo "Berhasil mengganti file asli."
    else
      echo "Error saat mengganti file asli."
    fi
  else
    echo "Error: File temporary tidak dibuat."
  fi

  echo "Selesai."
}


function about() {
  clear

  echo -e "${cyan}===========================================${reset}"
  echo -e "${bold}                  CREDITS${reset}${cyan}         ${reset}"
  echo -e "${cyan}===========================================${reset}"

  echo -e "${yellow}    MoLeTol${reset}\n"
  echo -e "${bold} Versi           :${reset} 4.0"
  echo -e "${bold} Dibuat oleh     :${reset} Ihsan Sungkar\n"

  echo -e "${green}    Contact${reset}"
  echo -e "${bold} Telegram        :${reset} @iCansSungkar"
  echo -e "${bold} Email           :${reset} 0014cc08ff05@gmail.com"
  echo -e "${bold} YouTube         :${reset} youtube.com/@ihsan.sungkar\n"

  echo -e "${purple}    Pendukung${reset}"
  echo -e "${bold} •${reset} Ramadhan Sungkar\n\n"

  echo -e "${cyan}===========================================${reset}"
  echo -e "${grey}Copyright (c) 2024-2025 Ihsan Sungkar.${reset}"
  echo -e "${grey}All Rights Reserved.${reset}\n"

  echo -n "<---"
  read
  menu
  return
}

info() {
  clear
  bold=$(echo -e "\e[1m")
  reset=$(echo -e "\e[0m")
  cyan=$(echo -e "\e[96m")
  green=$(echo -e "\e[92m")
  yellow=$(echo -e "\e[93m")
  purple=$(echo -e "\e[95m")
  blue=$(echo -e "\e[94m")
  grey=$(echo -e "\e[90m")

  # Function untuk mendapatkan properti dan menangani "Unknown"
  get_prop() {
    local prop_name="$1"
    local value
    value=$(su -c "getprop '$prop_name'" 2>/dev/null)
    if [ -z "$value" ]; then
      echo "Unknown"
    else
      echo "$value"
    fi
  }

  # Function untuk mendapatkan informasi baterai dari sysfs
  get_battery_info() {
    local path="$1"
    local value
    value=$(cat "$path" 2>/dev/null)
    if [ -z "$value" ]; then
      echo "Unknown"
    else
      echo "$value"
    fi
  }

  # Function untuk mendapatkan level baterai (nilai saja)
  get_battery_level() {
    su -c "dumpsys battery | grep 'level:' | awk '{print $2}'" 2>/dev/null || get_battery_info /sys/class/power_supply/*/capacity
  }

  # Function untuk mendapatkan suhu baterai (nilai saja)
  get_battery_temperature() {
    su -c "dumpsys battery | grep 'temperature:' | awk '{print $2}'" 2>/dev/null || get_battery_info /sys/class/power_supply/*/temp
  }

  # Function untuk mendapatkan RAM Size (dalam GB)
  get_ram_size() {
    local ram_raw=$(su -c "cat /proc/meminfo | grep 'MemTotal:' | awk '{gsub(/[^0-9]/, "", \$2); print \$2}'" 2>/dev/null)
    if [ -n "$ram_raw" ]; then
      local ram_gb=$((ram_raw / (1024 * 1024)))
      echo "$ram_gb GB"
    else
      echo "Unknown"
    fi
  }

  # Function untuk mendapatkan nama GPU (mencoba beberapa properti umum)
  get_gpu_info() {
    local gpu=$(get_prop ro.opengles.version)
    if [[ "$gpu" != "Unknown" ]]; then
      # Coba ekstrak nama vendor dan model sederhana
      case "$gpu" in
        *"Mali"*) echo "$(echo "$gpu" | grep -o "Mali-[A-Z0-9]\+")";;
        *"Adreno"*) echo "$(echo "$gpu" | grep -o "Adreno[ ]*[0-9]\+")";;
        *"PowerVR"*) echo "$(echo "$gpu" | grep -o "PowerVR[ ]*GE[0-9]\+")";;
        *) echo "$gpu";; # Kembalikan nilai mentah jika tidak dikenali
      esac
    else
      echo "Unknown"
    fi
  }

  # Lebar maksimum untuk label
  label_width=20

  print_labeled_value() {
    local label="$1"
    local value="$2"
    printf "%-${label_width}s : %s\n" "${bold}${cyan}${label}${reset}" "${green}${value}${reset}"
  }

  print_section_title() {
    echo -e "${bold}${blue}$1${reset}"
  }

  echo ""
  print_labeled_value "$(get_prop ro.product.brand) $(get_prop ro.product.model)"
  echo ""

  print_labeled_value "Versi Android" "$(get_prop ro.build.version.release)"
  print_labeled_value "Model" "$(get_prop ro.product.model)"
  echo ""

  print_section_title "Display"
  print_labeled_value "GPU" "$(get_gpu_info)"
  print_labeled_value "Max frequency" "$(cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq 2>/dev/null | sed 's/\(.\)..\?$/\1 GHz/' || echo "Unknown")"
  resolution=$(su -c "wm size" 2>/dev/null | awk '{print $3}' || echo "Unknown")
  print_labeled_value "Resolution" "$resolution"
  density=$(su -c "wm density" 2>/dev/null | awk '{print $3}' || echo "Unknown")
  print_labeled_value "Screen Density" "$density"
  print_labeled_value "Frame rate" "60Hz" # Asumsi default 60Hz
  echo ""

  print_section_title "Battery"
  print_labeled_value "Battery Level" "$(get_battery_level)%"
  temperature=$(get_battery_temperature)
  if [[ "$temperature" != "Unknown" ]]; then
    print_labeled_value "Temperature" "$temperature C"
  else
    print_labeled_value "Temperature" "Unknown"
  fi
  print_labeled_value "Technology" "$(get_prop ro.power_supply.technology || get_battery_info /sys/class/power_supply/*/technology)"
  capacity_raw=$(su -c "dumpsys battery | grep 'charge counter:' | awk '{print $3}'" 2>/dev/null || get_battery_info /sys/class/power_supply/*/charge_full)
  if [ "$capacity_raw" != "Unknown" ]; then
    capacity_mah=$((capacity_raw / 1000))
    print_labeled_value "Capacity" "${capacity_mah} mAh"
  else
    print_labeled_value "Capacity" "Unknown"
  fi
  echo ""

  print_section_title "Memory"
  print_labeled_value "RAM Size" "$(get_ram_size)"
  print_labeled_value "Type" "Unknown" # Sulit didapatkan secara umum
  echo ""

  print_section_title "Hardware"
  print_labeled_value "Processor" "$(get_prop ro.soc.manufacturer) ($(get_prop ro.board.platform))"
  print_labeled_value "CPU" "$(get_prop ro.product.cpu.abi)"
  print_labeled_value "Architecture" "$(get_prop ro.arch)"
  print_labeled_value "ABI" "$(get_prop ro.product.cpu.abi)"
  echo ""
  echo -n "<-back"
  read
  menu
}

function clean(){
  clear
  sleep 0.3
  rm -rf "/storage/emulated/0/Android/data/com.mobile.legends/cache/"
  echo "Menghapus Cache..."
  sleep 0.5
  rm -rf "/storage/emulated/0/Android/data/com.mobile.legends/files/UnityCache/"
  echo "Menghapus Unity Cache..."
  sleep 2
  rm -rf "/storage/emulated/0/Android/data/com.mobile.legends/files/dragon2017/OfflineReport/"
  echo "Menghapus Offline Report"
  sleep 1
  rm -rf "/storage/emulated/0/Android/data/com.mobile.legends/files/dragon2017/FightHistory/"
  echo "Menghapus History Fight..."
  sleep 0.5
  rm -rf "/storage/emulated/0/Android/data/com.mobile.legends/files/dragon2017/BattleRecord/"
  echo "Menghapus Battle Record..."
  sleep 0.7
  rm -rf "/data/data/com.mobile.legends/cache/"
  rm -rf "/data/data/com.mobile.legends/files/rtc_log/"
  echo "Menghapus Cache di Folder Root !"
  sleep 0.5
  rm -rf "/data/data/com.mobile.legends/databases/LoggerDatabase"
  rm -rf "/data/data/com.mobile.legends/databases/LoggerDatabase-journal"
  echo "Menghapus Log Database..."
  sleep 0.7
  rm -rf "/data/user/0/com.mobile.legends/databases/ss_app_log.db"
  rm -rf "/data/user/0/com.mobile.legends/databases/ss_app_log.db-journal"
  echo "Menghapus 'ss_app_log' di Folder root... "
  sleep 0.5
  rm -rf "/data/user/0/com.mobile.legends/files/npth/"
  echo "Menghapus npth..."
  sleep 0.7
  echo "__________________________________________________"
  echo "Berhasil!..."
  menu "Berhasil Membersihkan!..."
}

#!/bin/bash

# Variabel untuk path backup dan output
backup_dir="/data/local/tmp/backup"
output_tar_gz="/sdcard/Downloads/AkunML.tar.gz"
output_tar="/sdcard/Download/AkunML.tar" # File tar sementara

# Fungsi untuk mengkompres semua file di $backup_dir menjadi $output_tar_gz
exprt() {
  clear
  echo "Buat salinan semua akun yang pernah di backup untuk di pindahkan ke folder Downloads?\n\n"
  echo "0. back"
  echo -e "${green}┌──( Next: )"
  echo -n "└─❯ "
  read conf
  if [ "$conf" == "0" ]; then
    menu "Export dibatalkan"
    return 0 # Mengembalikan status sukses karena pembatalan bukan error
  fi

  # Pastikan direktori backup ada
  if [ ! -d "$backup_dir" ]; then
    echo "Error: Direktori backup '$backup_dir' tidak ditemukan."
    return 1
  fi

  # Pastikan direktori output dapat diakses (mencoba membuatnya jika tidak ada)
  if [ ! -d "$(dirname "$output_tar")" ]; then
    echo "Direktori Download tidak ditemukan, mencoba membuatnya..."
    mkdir -p "$(dirname "$output_tar")"
    if [ $? -ne 0 ]; then
      menu "Error: \n Gagal membuat Direktori $(dirname "$output_tar")'."
    fi
  fi

  cd "$backup_dir" || { echo "Error: Gagal masuk ke direktori '$backup_dir'."; return 1; }
  tar -cvf "$output_tar" *
  if [ $? -eq 0 ]; then
    echo "Berhasil mengarsipkan file ke '$output_tar'."
    gzip "$output_tar"
    if [ $? -eq 0 ]; then
      echo "Berhasil mengkompres arsip menjadi '$output_tar_gz'."
      rm "$output_tar" # Hapus file .tar sementara
    else
      echo "Gagal mengkompres arsip."
      rm "$output_tar" # Bersihkan file .tar jika kompresi gagal
      return 1
    fi
  else
    menu "Logs: \n Gagal mengarsipkan file."
  fi
  cd - > /dev/null # Kembali ke direktori sebelumnya
}

# Fungsi untuk mengekstrak file $output_tar_gz ke $backup_dir
imprt() {
  clear
  echo "Memulai proses dekompresi..."
  if [ -f "$output_tar_gz" ]; then
    gzip -d -c "$output_tar_gz" | tar -xvf - -C "$backup_dir"
    if [ $? -eq 0 ]; then
      menu "Logs: \n Berhasil mengekstrak file dari '$output_tar_gz' ke '$backup_dir'."
    else
      menu "Logs: \n Gagal mengekstrak file."
    fi
  else
    menu "Error:\n File '$output_tar_gz' tidak ditemukan."
  fi
}

function hapusAkun(){

  remover(){
    echo "Memulai menghapus $1. Please wait..."
    rm -rf "$backup_dir/$1"
    if [ $? -eq 0 ]; then
      echo "Akun $1 berhasil dihapus."
    else
      menu "Logs:\n Gagal menghapus $1."
    fi
  }

  su -c "am force-stop com.mobile.legends"
  clear
  header
  echo "Remove Account"
  echo " "
  echo -e "\e[96m List Account: \e[0m"
  list_folders
  echo " "
  echo -e "\e[3m$1 \e[0m"               # <--- Log
  
  echo -e "\e[3mmasukan angka 0 untuk kembali !!\e[0m"
  echo "┌──( Akun Yang Ingin diHapus: )"
  echo -n "└─❯ "
  read hapus 
  
  if echo "$hapus" | grep -q '/'; then
    hapusAkun "Logs: \n Tidak boleh menggunakan (/)"
  fi
  
  case "$hapus" in
    "n"|0|""|" ")
      menu ;;
    *)
      if [ ! -d "$hapus" ]; then
        menu "Logs: \n Akun $hapus tidak ditemukan."
      fi
      remover "$hapus";;
    esac  
}

function more(){
  clear # :P
  header
  echo ""
  echo -e "${bold}${blue} Mobile Legends Tools 4.0 "
  sleep 0.05
  echo -e "${cyan}    6 . Unlock FPS Ultra"         # <--- switchAc()
  sleep 0.05
  echo "    7 . Clean Log & Cache ML"         # <--- backup()
  sleep 0.05
  echo -e "    8 . Devices Information${reset}\n" # <--- newAccount()
  sleep 0.05
  echo -e "${yellow}    9 . Export data"
  echo -e "    10. Import data ${reset}\n"
  
  echo "    0. back"
  sleep 0.05
  
  
  echo -e "\e[3m$1 \e[0m"               # <--- Logs
  echo -e "${green}┌──( Input Number: )"
  echo -n "└─❯ " 
  # get input
  read selMore
  case "$selMore" in
    0|00)
      menu
      ;;
    5|6|7|8|9)
      main "$selMore"
      ;;
    *)
      more
      ;;
  esac
}


function main() {
  case "$1" in
    1)
      switchAc ;; # --> switch
    2)
      backup ;; # --> backup
    3)
      newAccount ;; # --> newAccount
    4)
      hapusAkun ;;  
    5)
      more ;;  # --> more
    6)
      editFPS ;;  # -- editFPS
    7)
      clean ;;  # -- clean
    8)
      info ;;  # --> info
    9)
      exprt ;;
    9)
      imprt ;;
    99)
      about ;; # --> about
    0|00)  
      clear
      echo " Thanks You So Much ! "
      echo " Bye Bye !! "
      time
      exit &>/dev/null ;;
    *)
      menu "Logs :\n Input tidak valid.\n" ;; # Default case
  esac
  
}

# Memulai Skrip dengan input

function menu(){
  clear # :P
  header
  echo ""
 
  sleep 0.05
  echo -e "${bold}${blue} Mobile Legends Tools 4.0"
  sleep 0.05
  echo -e "${cyan}    1. Switch Account"         # <--- switchAc()
  sleep 0.05
  echo "    2. Backup Account"         # <--- backup()
  sleep 0.05
  echo "    3. Create New Account" # <--- newAccount()
  sleep 0.05
  echo -e "    4. Remove Account${reset}"
  echo -e "${green}    5. More Features -->${reset}" # <----- more()
  sleep 0.05
  echo -e "  ─────────────────────────────────────"
  sleep 0.05
  echo "    99. About"
  sleep 0.05
  echo "    00. Exit"
  sleep 0.05
  echo " "
  echo -e "\e[3m$1 \e[0m"               # <--- Log
  
  echo -e "${green}┌──( Input Number: )"
  echo -n "└─❯ "  # Menggunakan echo -n untuk tidak menambahkan newline
  
  read select
  case "$select" in
    0|1|2|3|4|5|99)
      main "$select"
      ;;
    *)
      menu "Logs: \nInvalid input."
      ;;
  esac
}

# Alhamdulilla Beres
# Jangan Lupa Bersyukur kepada Allah Swt yang telah memberikan ilmu yang bermanfaat
# Code by Ihsan Sungkar

# Contact :
#   WhatsApp  : 0838 0941 9831
#   Instagram : kitsune.mask_

su -c "am force-stop com.mobile.legends"
menu