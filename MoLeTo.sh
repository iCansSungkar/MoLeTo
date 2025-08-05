#!/bin/bash


# Pastikan skrip dijalankan sebagai root
if [ "$(id -u)" -ne 0 ]; then
    echo "[ ! ] Tidak ada akses root. Silakan jalankan sebagai root."
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

# Fungsi untuk mencadangkan akun
function backup() {
  clear
  header
  echo -e "${cyan}Cadangkan Akun Baru!${reset}"
  echo " "
  echo -e "${yellow}Fungsi:${reset}"
  echo " - Menyimpan data akun saat ini untuk diganti nanti."
  echo " - Berguna untuk akun yang belum terhubung platform apapun."
  echo " "
  echo -e "\e[3m$1 \e[0m"
  echo "┌──( Nama Akun: )─[ 0. Kembali ]"
  echo -n "└─❯ "
  read newBackup
  
  if echo "$newBackup" | grep -q '/'; then
    menu "Logs:\nNama akun tidak boleh mengandung karakter '/'."
    return
  fi
  
  if [ -z "$newBackup" ]; then
    menu "Logs:\nNama akun tidak boleh kosong."
    return
  fi

  if [[ "$newBackup" == "0" ]]; then
    menu # Kembali ke menu utama
    return
  fi

  echo "Mencadangkan akun '$newBackup'..."
  mkdir -p "$backup_dir/$newBackup"
  cp -rp "$data_dir"/* "$backup_dir/$newBackup"

  if [ -d "$backup_dir/$newBackup" ]; then
    menu "Logs:\nAkun '$newBackup' berhasil dicadangkan."
  else
    menu "Logs:\nTerjadi kesalahan saat mencadangkan akun '$newBackup'."
  fi
}

# Fungsi untuk menampilkan daftar akun yang dicadangkan
function list_folders {
  for folder_path in "$backup_dir"/*/ ; do
    if [[ -d "$folder_path" ]]; then
      folder_name=$(basename "$folder_path")
      echo "${yellow}    ➤ $folder_name${reset}"
    fi
  done
}
# Fungsi untuk ganti akun
function switchAc() {
  su -c "am force-stop $package_name"
  clear
  header
  echo -e "${cyan}Ganti Akun${reset}"
  echo " "
  echo -e "${yellow}Daftar Akun:${reset}"
  list_folders
  echo " "
  echo -e "\e[3mMasukkan angka 0 untuk kembali!\e[0m"
  echo "┌──( Ganti ke Akun: )"
  echo -n "└─❯ "
  read folder

  if [ "$folder" == "0" ] || [ -z "$folder" ]; then
    menu "Log:\nKembali ke menu."
    return
  fi
  
  if echo "$folder" | grep -q '/'; then
    menu "Logs:\nNama akun tidak valid."
    return
  fi
    
  backup_akun_dir="$backup_dir/$folder"

  if [ ! -d "$backup_akun_dir" ]; then
    menu "Log:\nAkun '$folder' tidak ditemukan."
    return
  fi

  if [ -z "$data_dir" ]; then
    menu "Log:\nAplikasi '$package_name' tidak ditemukan."
    return
  fi
  
  local owner=$(stat -c '%u:%g' "$data_dir")

  clear
  echo "Memulai ganti akun ke '$folder'..."
  sleep 1

  echo "Menghapus data akun lama..."
  su -c "pm clear $package_name"
  if [ $? -ne 0 ]; then
    menu "Log:\nGagal menghapus data akun lama."
    return
  fi

  echo "Menyalin data akun '$folder'..."
  cp -rp "$backup_akun_dir"/* "$data_dir"/
  if [ $? -ne 0 ]; then
    menu "Log:\nGagal menyalin data akun baru."
    return
  fi

  echo "Menyetel ulang izin file..."
  chown -R "$owner" "$data_dir"
  chmod -R 771 "$data_dir"

  menu "Logs:\nBerhasil ganti ke akun '$folder'."
}

# Fungsi untuk membuat akun baru
function newAccount() {
  su -c "am force-stop $package_name"

  # Fungsi internal untuk proses pembuatan akun
  deleteAc(){
    clear
    echo "Memulai pembuatan akun baru..."
    sleep 1.0
    echo "Mengamankan data OBB..."
    su -c "mv /sdcard/Android/data/$package_name /sdcard/Android/data/$package_name.bak"
    echo "Menghapus data akun lama..."
    su -c "pm clear $package_name"
    sleep 5.0
    echo "Memulihkan data OBB..."
    su -c "mv /sdcard/Android/data/$package_name.bak /sdcard/Android/data/$package_name"
    sleep 3.0
    menu "Logs:\nBerhasil membuat akun baru!"
  }

  clear
  echo -e "${yellow}( ! ) Peringatan:${reset}"
  echo "Akun yang sedang Anda gunakan akan terhapus/logout."
  echo "Apakah Anda yakin ingin melanjutkan?"
  
  echo "┌──( Y/N: )"
  echo -n "└─❯ "
  read lanjut

  case "$lanjut" in
    "Y"|"y")
      deleteAc ;;
    "N"|"n")
      menu ;;
    *)
      menu "Logs:\nInput tidak valid." ;;
  esac
}


# Fungsi untuk menampilkan informasi kredit
function about() {
  clear
  echo -e "${cyan}===========================================${reset}"
  echo -e "${bold}                  KREDIT${reset}"
  echo -e "${cyan}===========================================${reset}"
  echo -e "${yellow}    MoLeTo${reset}\n"
  echo -e "${bold} Versi           :${reset} 5.0"
  echo -e "${bold} Dibuat oleh     :${reset} Ihsan Sungkar\n"
  echo -e "${green}    Kontak${reset}"
  echo -e "${bold} Telegram        :${reset} @iCansSungkar"
  echo -e "${bold} Email           :${reset} 0014cc08ff05@gmail.com"
  echo -e "${bold} YouTube         :${reset} youtube.com/@ihsan.sungkar\n"
  echo -e "${purple}    Pendukung${reset}"
  echo -e "${bold} •${reset} Ramadhan Sungkar\n\n"
  echo -e "${cyan}===========================================${reset}"
  echo -e "${grey}Hak Cipta (c) 2024-2025 Ihsan Sungkar.${reset}"
  echo -e "${grey}Semua Hak Dilindungi.${reset}\n"
  echo -n "Tekan Enter untuk kembali..."
  read
  menu
}

# Fungsi untuk menampilkan informasi perangkat
info() {
  clear

  # Fungsi internal untuk mendapatkan properti sistem
  get_prop() {
    su -c "getprop '$1'" 2>/dev/null || echo "Tidak diketahui"
  }

  # Fungsi internal untuk mendapatkan informasi baterai
  get_battery_info() {
    cat "$1" 2>/dev/null || echo "Tidak diketahui"
  }

  get_battery_level() {
    su -c "dumpsys battery | grep 'level:' | awk '{print \$2}'" 2>/dev/null || get_battery_info /sys/class/power_supply/*/capacity
  }

  get_battery_temperature() {
    local temp=$(su -c "dumpsys battery | grep 'temperature:' | awk '{print \$2}'" 2>/dev/null || get_battery_info /sys/class/power_supply/*/temp)
    if [ -n "$temp" ]; then
      echo "$((temp / 10)) C"
    else
      echo "Tidak diketahui"
    fi
  }

  get_ram_size() {
    local ram_kb=$(su -c "cat /proc/meminfo | grep 'MemTotal:' | awk '{print \$2}'" 2>/dev/null)
    if [ -n "$ram_kb" ]; then
      echo "$((ram_kb / 1024 / 1024)) GB"
    else
      echo "Tidak diketahui"
    fi
  }

  get_gpu_info() {
    get_prop ro.opengles.version | sed 's/.*(GPU-//; s/).*//' || echo "Tidak diketahui"
  }

  label_width=20
  print_labeled_value() {
    printf "%-${label_width}s : %s\n" "${bold}${cyan}$1${reset}" "${green}$2${reset}"
  }
  print_section_title() {
    echo -e "${bold}${blue}$1${reset}"
  }

  echo ""
  print_labeled_value "Perangkat" "$(get_prop ro.product.brand) $(get_prop ro.product.model)"
  echo ""
  print_labeled_value "Versi Android" "$(get_prop ro.build.version.release)"
  print_labeled_value "Model" "$(get_prop ro.product.model)"
  echo ""
  print_section_title "Tampilan"
  print_labeled_value "GPU" "$(get_gpu_info)"
  print_labeled_value "Frekuensi CPU Maks" "$(cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq 2>/dev/null | sed 's/\(.\)..\?$/\1 GHz/' || echo "Tidak diketahui")"
  print_labeled_value "Resolusi" "$(su -c "wm size" 2>/dev/null | awk '{print $3}' || echo "Tidak diketahui")"
  print_labeled_value "Kepadatan Layar" "$(su -c "wm density" 2>/dev/null | awk '{print $3}' || echo "Tidak diketahui")"
  echo ""
  print_section_title "Baterai"
  print_labeled_value "Level Baterai" "$(get_battery_level)%"
  print_labeled_value "Suhu" "$(get_battery_temperature)"
  print_labeled_value "Teknologi" "$(get_battery_info /sys/class/power_supply/*/technology)"
  print_labeled_value "Kapasitas" "$(( $(get_battery_info /sys/class/power_supply/*/charge_full) / 1000 )) mAh"
  echo ""
  print_section_title "Memori"
  print_labeled_value "Ukuran RAM" "$(get_ram_size)"
  echo ""
  print_section_title "Perangkat Keras"
  print_labeled_value "Prosesor" "$(get_prop ro.soc.manufacturer) ($(get_prop ro.board.platform))"
  print_labeled_value "Arsitektur CPU" "$(get_prop ro.product.cpu.abi)"
  echo ""
  echo -n "Tekan Enter untuk kembali..."
  read
  menu
}

# Fungsi untuk membersihkan cache dan log
function clean(){
  clear
  echo "Memulai pembersihan..."
  sleep 0.3
  rm -rf "/storage/emulated/0/Android/data/$package_name/cache/"
  echo "Menghapus Cache..."
  sleep 0.5
  rm -rf "/storage/emulated/0/Android/data/$package_name/files/UnityCache/"
  echo "Menghapus Unity Cache..."
  sleep 1
  rm -rf "/data/data/$package_name/cache/"
  rm -rf "/data/data/$package_name/files/rtc_log/"
  echo "Menghapus Cache di folder root!"
  sleep 0.5
  rm -rf "/data/data/$package_name/databases/LoggerDatabase"
  rm -rf "/data/data/$package_name/databases/LoggerDatabase-journal"
  echo "Menghapus Log Database..."
  sleep 0.5
  echo "__________________________________________________"
  echo "Pembersihan Selesai!"
  sleep 1
  menu "Berhasil membersihkan!"
}

# Fungsi untuk mengekspor data backup
function exprt() {
  local output_tar_gz="/sdcard/Downloads/AkunML_$(date +%Y%m%d).tar.gz"
  clear
  echo "Anda akan mengekspor semua akun ke file:"
  echo -e "${yellow}$output_tar_gz${reset}\n"
  echo "Lanjutkan?"
  echo "0. Kembali"
  echo -e "${green}┌──( Y/N: )"
  echo -n "└─❯ "
  read conf

  if [[ "$conf" != "Y" && "$conf" != "y" ]]; then
    menu "Ekspor dibatalkan."
    return
  fi

  if [ ! -d "$backup_dir" ] || [ -z "$(ls -A "$backup_dir")" ]; then
    menu "Error: Direktori backup '$backup_dir' tidak ada atau kosong."
    return
  fi

  echo "Mengompres data..."
  tar -czvf "$output_tar_gz" -C "$backup_dir" .
  if [ $? -eq 0 ]; then
    menu "Logs:\nBerhasil ekspor ke '$output_tar_gz'."
  else
    menu "Logs:\nGagal mengekspor data."
  fi
}

# Fungsi untuk mengimpor data backup
function imprt() {
  local default_path="/sdcard/Downloads/"
  clear
  echo "Masukkan path lengkap ke file .tar.gz yang ingin diimpor,"
  echo "atau tekan Enter untuk mencari di direktori default:"
  echo -e "(${yellow}$default_path${reset})"
  echo -n "└─❯ "
  read file_path

  if [ -z "$file_path" ]; then
    file_path=$(find "$default_path" -name "AkunML*.tar.gz" | head -n 1)
    if [ -z "$file_path" ]; then
        menu "Error:\nTidak ada file backup 'AkunML*.tar.gz' yang ditemukan di '$default_path'."
        return
    fi
    echo "File ditemukan: $file_path"
  fi

  if [ ! -f "$file_path" ]; then
    menu "Error:\nFile '$file_path' tidak ditemukan."
    return
  fi

  echo "Mengekstrak data..."
  tar -xzvf "$file_path" -C "$backup_dir"
  if [ $? -eq 0 ]; then
    menu "Logs:\nBerhasil impor dari '$file_path'."
  else
    menu "Logs:\nGagal mengimpor data."
  fi
}

# Fungsi untuk menghapus akun dari backup
function hapusAkun(){
  remover(){
    echo "Menghapus akun '$1'. Mohon tunggu..."
    rm -rf "$backup_dir/$1"
    if [ $? -eq 0 ]; then
      menu "Akun '$1' berhasil dihapus."
    else
      menu "Logs:\nGagal menghapus '$1'."
    fi
  }

  su -c "am force-stop $package_name"
  clear
  header
  echo -e "${cyan}Hapus Akun${reset}"
  echo " "
  echo -e "${yellow}Daftar Akun:${reset}"
  list_folders
  echo " "
  echo -e "\e[3m$1 \e[0m"
  echo -e "\e[3mMasukkan angka 0 untuk kembali!\e[0m"
  echo "┌──( Akun yang Ingin Dihapus: )"
  echo -n "└─❯ "
  read hapus 
  
  if echo "$hapus" | grep -q '/'; then
    hapusAkun "Logs:\nTidak boleh menggunakan karakter '/'."
    return
  fi
  
  case "$hapus" in
    "0"|"")
      menu ;;
    *)
      if [ ! -d "$backup_dir/$hapus" ]; then
        menu "Logs:\nAkun '$hapus' tidak ditemukan."
        return
      fi
      remover "$hapus";;
    esac  
}

# Menu untuk fitur tambahan
function more(){
  clear
  header
  echo ""
  echo -e "${bold}${blue} Mobile Legends Tools 5.0 ${reset}"
  sleep 0.05
  echo -e "${cyan}    6 . Buka FPS Ultra"
  sleep 0.05
  echo "    7 . Bersihkan Log & Cache ML"
  sleep 0.05
  echo -e "    8 . Informasi Perangkat${reset}\n"
  sleep 0.05
  echo -e "${yellow}    9 . Ekspor Data"
  echo -e "    10. Impor Data${reset}\n"
  echo "    0 . Kembali"
  sleep 0.05
  
  echo -e "\e[3m$1 \e[0m"
  echo -e "${green}┌──( Masukkan Nomor: )"
  echo -n "└─❯ " 
  read selMore
  case "$selMore" in
    0|00)
      menu ;;
    6|7|8|9|10)
      main "$selMore" ;;
    *)
      more "Logs:\nInput tidak valid." ;;
  esac
}

# Fungsi utama untuk routing
function main() {
  case "$1" in
    1) switchAc ;;
    2) backup ;;
    3) newAccount ;;
    4) hapusAkun ;;
    5) more ;;
    6) editFPS ;;
    7) clean ;;
    8) info ;;
    9) exprt ;;
    10) imprt ;;
    99) about ;;
    0|00)  
      clear
      echo " Terima Kasih Banyak! "
      echo " Sampai Jumpa !! "
      exit 0 ;;
    *)
      menu "Logs:\nInput tidak valid." ;;
  esac
}

# Menu utama
function menu(){
  clear
  header
  echo ""
  sleep 0.05
  echo -e "${bold}${blue} Mobile Legends Tools 5.0${reset}"
  sleep 0.05
  echo -e "${cyan}    1. Ganti Akun"
  sleep 0.05
  echo "    2. Cadangkan Akun"
  sleep 0.05
  echo "    3. Buat Akun Baru"
  sleep 0.05
  echo -e "    4. Hapus Akun${reset}"
  sleep 0.05
  echo -e "${green}    5. Fitur Lainnya -->${reset}"
  sleep 0.05
  echo -e "  ─────────────────────────────────────"
  sleep 0.05
  echo "    99. Tentang"
  sleep 0.05
  echo "    00. Keluar"
  sleep 0.05
  echo " "
  echo -e "\e[3m$1 \e[0m"
  
  echo -e "${green}┌──( Masukkan Nomor: )"
  echo -n "└─❯ "
  
  read select
  case "$select" in
    1|2|3|4|5|99|0|00)
      main "$select" ;;
    *)
      menu "Logs:\nInput tidak valid." ;;
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
