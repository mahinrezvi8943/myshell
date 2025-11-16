#!/bin/bash
# myshell_v4.sh - interactive mini-shell with an ACTIONABLE features menu,
# process suspension, and cache clearing.
# Save as: myshell_v4.sh
# Make executable: chmod +x myshell_v4.sh
# Run: ./myshell_v4.sh

LOGFILE="$HOME/.myshell.log"

# --- HELPER FUNCTIONS (Logging, Sudo, Confirm) ---

# Ensure log exists
touch "$LOGFILE"

# helper: log messages with timestamp
log() {
  echo "[$(date '+%F %T')] $*" >> "$LOGFILE"
}

# ensure we have a tty and warn if not run interactively
if [[ ! -t 0 ]]; then
  echo "Warning: not running in an interactive terminal. Some prompts may not work."
fi

# helper: require sudo for system actions
require_sudo() {
  if [[ $EUID -ne 0 ]]; then
    echo "This action requires root privileges. Asking sudo..."
    sudo -v || { echo "sudo failed or was cancelled."; return 1; }
  fi
  return 0
}

# helper: yes/no prompt (default: no)
confirm() {
  # usage: confirm "Are you sure?"
  local prompt="${1:-Are you sure?}"
  while true; do
    read -p "$prompt [y/N]: " ans
    case "${ans,,}" in
      y|yes) return 0 ;;
      n|no|"" ) return 1 ;;
      *) echo "Please answer 'y' or 'n'." ;;
    esac
  done
}

# --- HELP & FEATURE MENU FUNCTIONS ---

# Print help
print_help() {
  cat <<'HELP'
MyShell built-in commands:
  my_ls [opts]        - wrapper for ls (works with -l, -a)
  my_cat <file>       - displays file
  my_cat > <file>     - create/overwrite file (Ctrl+D to save)
  my_cp <src> <dst>   - copy file
  my_mv <src> <dst>   - move/rename file
  my_rm <file>        - remove file

Process Management:
  my_suspend <PID|Name> - Suspend (pause) a process using its PID or name
  my_resume <PID>       - Resume (un-pause) a suspended process by PID

System commands:
  update               - update package lists (apt/pacman detection)
  upgrade              - upgrade packages (apt/pacman detection)
  refresh              - clear system memory cache (requires sudo)
  restart              - reboot the machine
  shutdown             - shutdown the machine (alias: poweroff)
  poweroff             - poweroff the machine
  sleep                - suspend to RAM (systemctl suspend)
  features             - **NEW: Open interactive tweak menu**
  help                 - show this help text
  exit                 - exit MyShell
HELP
}

# --- TWEAK HELPER FUNCTIONS (for 'features' menu) ---

# [1]
install_performance_tweaks() {
  echo "Installing 'nohang' and 'preload'..."
  require_sudo || return 1
  sudo apt-get install nohang preload
  log "features: ran install_performance_tweaks"
  echo "Done."
}

# [2]
enable_performance_services() {
  echo "Enabling 'nohang' and 'preload' systemd services..."
  require_sudo || return 1
  sudo systemctl enable nohang
  sudo systemctl enable preload
  log "features: ran enable_performance_services"
  echo "Done."
}

# [3]
disable_oomd() {
  echo "Disabling systemd-oomd (replaced by nohang)..."
  require_sudo || return 1
  sudo systemctl disable systemd-oomd
  log "features: ran disable_oomd"
  echo "Done."
}

# [4]
set_cpu_governor() {
  echo "Setting CPU governor to 'performance'..."
  require_sudo || return 1
  echo 'w /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor - - - - performance' | sudo tee /usr/lib/tmpfiles.d/cpu-governor.conf > /dev/null
  log "features: ran set_cpu_governor"
  echo "CPU governor policy created. (May require reboot to apply)"
}

# [5]
set_power_policies() {
  echo "Setting various power policies to 'performance' (PCIe, SATA, etc.)..."
  require_sudo || return 1
  echo 'w /sys/devices/system/cpu/cpufreq/policy*/energy_performance_preference - - - - performance' | sudo tee /usr/lib/tmpfiles.d/energy_performance_preference.conf > /dev/null
  echo 'w /sys/module/pcie_aspm/parameters/policy - - - - performance' | sudo tee /usr/lib/tmpfiles.d/pcie_aspm_performance.conf > /dev/null
  echo 'w /sys/class/drm/card0/device/power_dpm_state - - - - performance' | sudo tee /usr/lib/tmpfiles.d/power_dpm_state.conf > /dev/null
  
  echo '# SATA Active Link Power Management' | sudo tee /usr/lib/udev/rules.d/50-sata.rules > /dev/null
  echo 'ACTION=="add", SUBSYSTEM=="scsi_host", KERNEL=="host*", ATTR{link_power_management_policy}="max_performance"' | sudo tee -a /usr/lib/udev/rules.d/50-sata.rules > /dev/null
  
  log "features: ran set_power_policies"
  echo "Power policies created. (May require reboot to apply)"
}

# [6]
install_sound_drivers() {
  echo "Installing sound packages (pulseaudio, jackd2)..."
  require_sudo || return 1
  sudo apt-get install alsa-firmware-loaders pulseaudio pulseaudio-module-jack jackd2
  log "features: ran install_sound_drivers"
  echo "Done."
}

# [7]
tweak_sound_config() {
  echo "This will open '/etc/pulse/daemon.conf' in 'nano'."
  echo "Per the guide, you must manually find and edit lines like:"
  echo "  ; resample-method = ... -> resample-method = soxr-vhq"
  echo "  ; default-sample-format = ... -> default-sample-format = float32le"
  echo "  ; default-sample-rate = ... -> default-sample-rate = 96000"
  confirm "Open nano to edit this file now?" || return 1
  require_sudo || return 1
  sudo nano /etc/pulse/daemon.conf
  log "features: opened daemon.conf for manual edit"
  echo "File edit complete. You may need to restart pulseaudio."
}

# [8]
install_fonts() {
  echo "Installing common fonts (Noto, DejaVu, Liberation)..."
  # Note: This is a translation of the `yay` command for Debian
  require_sudo || return 1
  sudo apt-get install fonts-noto fonts-noto-cjk fonts-dejavu fonts-liberation-sans fonts-opensans
  log "features: ran install_fonts"
  echo "Done."
}

# [9]
set_io_schedulers() {
  echo "Creating udev rule for I/O schedulers (bfq for SSD/HDD, none for NVMe)..."
  require_sudo || return 1
  {
    echo '# set scheduler for NVMe'
    echo 'ACTION=="add|change", KERNEL=="nvme[0-9]*", ATTR{queue/scheduler}="none"'
    echo '# set scheduler for SSD and eMMC'
    echo 'ACTION=="add|change", KERNEL=="sd[a-z]|mmcblk[0-9]*", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="bfq"'
    echo '# set scheduler for rotating disks'
    echo 'ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="bfq"'
  } | sudo tee /etc/udev/rules.d/60-ioschedulers.rules > /dev/null
  
  echo "Reloading udev rules..."
  sudo udevadm control --reload-rules && sudo udevadm trigger
  log "features: ran set_io_schedulers"
  echo "I/O scheduler rules applied."
}

# [10]
install_tlp() {
  echo "Installing and enabling 'tlp' for battery management..."
  require_sudo || return 1
  sudo apt-get install tlp
  sudo systemctl enable tlp.service
  sudo systemctl start tlp.service
  log "features: ran install_tlp"
  echo "TLP is now installed and running."
}

# [11]
install_fusuma() {
  echo "Installing 'fusuma' for touchpad gestures..."
  require_sudo || return 1
  sudo apt-get install ruby libinput-tools -y # Install prerequisites
  sudo gpasswd -a $USER input
  sudo gem install fusuma
  log "features: ran install_fusuma"
  echo "Fusuma installed. IMPORTANT: You must REBOOT for the group change to take effect."
}


# --- NEW: Interactive Features Menu ---
run_features_menu() {
  while true; do
    echo "--- Pop!_OS Tweak Menu (from) ---"
    echo " [1] Install Performance Tweaks (nohang, preload)"
    echo " [2] Enable Performance Services (nohang, preload)"
    echo " [3] Disable systemd-oomd (if using nohang)"
    echo " [4] Set CPU Governor to 'performance'"
    echo " [5] Set Power Policies to 'performance' (PCIe, SATA, etc.)"
    echo ""
    echo " [6] Install Sound Packages (pulseaudio, jackd2)"
    echo " [7] Edit Sound Config (soxr-vhq) (MANUAL EDIT)"
    echo " [8] Install Extra Fonts (Noto, DejaVu)"
    echo ""
    echo " [9] Set I/O Schedulers (bfq/none)"
    echo "[10] Install TLP (Laptop Battery Improvement)"
    echo "[11] Install Fusuma (Touchpad Gestures)"
    echo ""
    echo " [q] Quit Menu"
    echo "------------------------------------------------"
    
    read -p "Select an option (1-11 or q): " choice
    
    case $choice in
      1) install_performance_tweaks ;;
      2) enable_performance_services ;;
      3) disable_oomd ;;
      4) set_cpu_governor ;;
      5) set_power_policies ;;
      6) install_sound_drivers ;;
      7) tweak_sound_config ;;
      8) install_fonts ;;
      9) set_io_schedulers ;;
      10) install_tlp ;;
      11) install_fusuma ;;
      q|Q) echo "Exiting features menu..."; break ;;
      *) echo "Invalid option. Please try again." ;;
    esac
    echo "" # Add space before next menu display
  done
  log "features: exited menu"
}


# --- SYSTEM ACTION FUNCTIONS ---

# helper: detect package manager (apt or pacman)
detect_pkg_mgr() {
  if command -v pacman >/dev/null 2>&1; then
    echo "pacman"
  elif command -v apt >/dev/null 2>&1 || command -v apt-get >/dev/null 2>&1; then
    echo "apt"
  else
    echo "unknown"
  fi
}

# wrapper routines for update/upgrade
do_update() {
  local mgr
  mgr=$(detect_pkg_mgr)
  case "$mgr" in
    pacman)
      echo "Detected pacman. Running: sudo pacman -Syy"
      require_sudo || return 1
      sudo pacman -Syy
      ;;
    apt)
      echo "Detected apt. Running: sudo apt update"
      require_sudo || return 1
      sudo apt update
      ;;
    *)
      echo "Package manager not recognized. Please run your distro's update command manually."
      return 1
      ;;
  esac
  log "update run with pkgmgr=$mgr"
}

do_upgrade() {
  local mgr
  mgr=$(detect_pkg_mgr)
  case "$mgr" in
    pacman)
      echo "Detected pacman. Running: sudo pacman -Syu"
      require_sudo || return 1
      sudo pacman -Syu
      ;;
    apt)
      echo "Detected apt. Running: sudo apt full-upgrade (or apt-get upgrade)"
      require_sudo || return 1
      sudo apt full-upgrade -y || sudo apt-get upgrade -y
      ;;
    *)
      echo "Package manager not recognized. Please run your distro's upgrade command manually."
      return 1
      ;;
  esac
  log "upgrade run with pkgmgr=$mgr"
}

# safe shutdown/reboot/poweroff/suspend helpers
do_shutdown() {
  if confirm "Are you sure you want to shutdown the system now?"; then
    require_sudo || return 1
    log "shutdown requested by user"
    sudo systemctl poweroff
  else
    echo "Shutdown cancelled."
  fi
}

do_restart() {
  if confirm "Reboot the system now?"; then
    require_sudo || return 1
    log "reboot requested by user"
    sudo systemctl reboot
  else
    echo "Reboot cancelled."
  fi
}

do_poweroff() { do_shutdown; }

do_sleep() {
  if confirm "Suspend to RAM (sleep) now?"; then
    require_sudo || return 1
    log "suspend requested by user"
    sudo systemctl suspend
  else
    echo "Suspend cancelled."
  fi
}

# --- PROCESS & CACHE FUNCTIONS ---

# Suspend a process
do_suspend_process() {
  local target="$1"
  local pid
  
  if [[ -z "$target" ]]; then
    echo "Usage: my_suspend <PID_or_Name>"
    return 1
  fi

  # Check if target is a number (PID) or a name
  if [[ "$target" =~ ^[0-9]+$ ]]; then
    pid="$target"
  else
    # Find PID from name. -s gets a single PID.
    pid=$(pidof -s "$target")
    if [[ -z "$pid" ]]; then
      echo "Error: Process name '$target' not found or multiple instances exist."
      return 1
    fi
    echo "Found '$target' with PID: $pid"
  fi

  if kill -STOP "$pid"; then
    echo "Successfully suspended process $pid."
    log "my_suspend: suspended $pid ($target)"
  else
    echo "Error: Failed to suspend process $pid. Do you have permission?"
  fi
}

# Resume a process
do_resume_process() {
  local pid="$1"
  
  if [[ -z "$pid" || ! "$pid" =~ ^[0-9]+$ ]]; then
    echo "Usage: my_resume <PID>"
    echo "Note: You must use the PID, not the name."
    return 1
  fi

  if kill -CONT "$pid"; then
    echo "Successfully resumed process $pid."
    log "my_resume: resumed $pid"
  else
    echo "Error: Failed to resume process $pid."
  fi
}

# Refresh system cache
do_refresh() {
  echo "This will clear the system page cache, dentries, and inodes."
  if confirm "Are you sure you want to clear the system cache?"; then
    require_sudo || return 1
    echo "Syncing file systems..."
    sync
    echo "Clearing cache (echo 3 > /proc/sys/vm/drop_caches)..."
    if echo 3 | sudo tee /proc/sys/vm/drop_caches > /dev/null; then
      echo "System cache cleared."
      log "refresh: cache cleared"
    else
      echo "Error: Failed to clear cache."
    fi
  else
    echo "Refresh cancelled."
  fi
}


# --- MAIN SHELL LOOP ---

echo "Welcome to MyShell (v4 - Interactive Features)! Type 'help' for commands."
log "myshell started by $USER on $(hostname)"

while true; do
  # read command line into array to preserve arguments with spaces
  read -p "MyShell> " -r -a argv
  # if empty, continue
  [[ ${#argv[@]} -eq 0 ]] && continue

  cmd="${argv[0]}"

  case "$cmd" in

    my_ls)
      # allow options like -l -a
      if [[ ${#argv[@]} -gt 1 ]]; then
        ls "${argv[@]:1}" --color=auto
      else
        ls --color=auto
      fi
      ;;

    my_cat)
      if [[ ${argv[1]} == ">" ]]; then
        filename="${argv[2]}"
        if [[ -z "$filename" ]]; then
          echo "Usage: my_cat > filename"
        else
          echo "Enter content for '$filename'. Press Ctrl+D to save."
          cat > "$filename"
          echo "Saved '$filename'."
          log "my_cat: wrote $filename"
        fi
      else
        filename="${argv[1]}"
        if [[ -z "$filename" ]]; then
          echo "Usage: my_cat filename"
        else
          if [[ -f "$filename" ]]; then
            cat "$filename"
          else
            echo "File not found: $filename"
          fi
        fi
      fi
      ;;

    my_cp)
      src="${argv[1]}"; dst="${argv[2]}"
      if [[ -z "$src" || -z "$dst" ]]; then
        echo "Usage: my_cp source dest"
      else
        cp -v -- "$src" "$dst" && echo "Copied." || echo "Copy failed."
        log "my_cp: $src -> $dst"
      fi
      ;;

    my_mv)
      src="${argv[1]}"; dst="${argv[2]}"
      if [[ -z "$src" || -z "$dst" ]]; then
        echo "Usage: my_mv source dest"
      else
        mv -v -- "$src" "$dst" && echo "Moved/Renamed." || echo "Move failed."
        log "my_mv: $src -> $dst"
      fi
      ;;

    my_rm)
      target="${argv[1]}"
      if [[ -z "$target" ]]; then
        echo "Usage: my_rm filename"
      else
        if confirm "Really delete '$target' ?"; then
          rm -v -- "$target" && echo "Removed." || echo "Remove failed."
          log "my_rm: removed $target"
        else
          echo "Delete cancelled."
        fi
      fi
      ;;

    # --- Process & Cache Commands ---
    my_suspend)
      do_suspend_process "${argv[1]}"
      ;;

    my_resume)
      do_resume_process "${argv[1]}"
      ;;

    refresh)
      do_refresh
      ;;
      
    # --- System Commands ---
    update)
      do_update
      ;;

    upgrade)
      do_upgrade
      ;;

    shutdown|poweroff)
      do_shutdown
      ;;

    restart|reboot)
      do_restart
      ;;

    sleep|suspend)
      do_sleep
      ;;

    # --- UPDATED FEATURES COMMAND ---
    features)
      run_features_menu
      ;;

    help)
      print_help
      ;;

    exit)
      echo "Goodbye!"
      log "myshell exited by user"
      break
      ;;

    *)
      echo "Error: Command not found '$cmd'. Try 'help'."
      ;;
  esac

  echo ""
done
