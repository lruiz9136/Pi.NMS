#!/bin/bash
# ------------------------------------------------------------------------------
#  Pi.NMS
#  Open Source Network Guard / WIFI & LAN intrusion detector 
#
#  pinms_uninstall.sh - Uninstallation script
# ------------------------------------------------------------------------------
#  lruiz9136 2026        GNU GPLv3
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
  COLS=70
  ROWS=12
  
  INSTALL_DIR=~
  PIALERT_HOME="$INSTALL_DIR/pialert"
  PINMS_ARCHIVE="$INSTALL_DIR/pinms_latest.tar.gz"
  LEGACY_ARCHIVE="$INSTALL_DIR/pialert_latest.tar.gz"
  
  LIGHTTPD_CONF_DIR="/etc/lighttpd"
  WEBROOT="/var/www/html"
  
  LOG="pinms_uninstall_`date +"%Y-%m-%d_%H-%M"`.log"

# ------------------------------------------------------------------------------
# Main
# ------------------------------------------------------------------------------
main() {
  print_superheader "Pi.NMS Uninstallation"
  log "`date`"
  log "Logfile: $LOG"

  # Ask uninstallation
  ask_yesno "This script will uninstall Pi.NMS from this system.\nUninstall path:  $PIALERT_HOME" \
            "Do you want to continue ?"
  if ! $ANSWER ; then
    exit 1
  fi

  msgbox "" "The uninstallation process will start now"

  # Uninstall prrocess
  print_header "Removing files"
  remove_path "$PIALERT_HOME"
  remove_path "$WEBROOT/pialert"
  remove_path "$LIGHTTPD_CONF_DIR/conf-available/pialert_front.conf"
  remove_path "$LIGHTTPD_CONF_DIR/conf-enabled/pialert_front.conf"
  remove_path "/var/cache/lighttpd/compress/pialert"
  remove_path "$PINMS_ARCHIVE"
  remove_path "$LEGACY_ARCHIVE"

  # Uninstall crontab jobs
  print_header "Removing crontab jobs"
  if command -v crontab >/dev/null 2>&1 ; then
    crontab -l 2>/dev/null | sed '/pialert.py/d' | sed ':a;N;$!ba;s/#-------------------------------------------------------------------------------\n#  Pi.Alert\n#  Open Source Network Guard \/ WIFI & LAN intrusion detector \n#\n#  pialert.cron - Back module. Crontab jobs\n#-------------------------------------------------------------------------------\n#  Puche 2021        pi.alert.application@gmail.com        GNU GPLv3\n#-------------------------------------------------------------------------------//g' | crontab - >> "$LOG" 2>&1
  fi

  # final message
  print_header "Uninstallation process finished"
  print_msg "Note: lighttpd, PHP, arp-scan & Python have not been uninstalled."
  print_msg "       They may be required by other software"
  print_msg "       You can uninstall them manually with command 'apt-get remove XX'"
}


# ------------------------------------------------------------------------------
# ASK
# ------------------------------------------------------------------------------
msgbox() {
  LINE1=$(printf "%*s" $(((${#1}+$COLS-5)/2)) "$1")
  LINE2=$(printf "%*s" $(((${#2}+$COLS-5)/2)) "$2")

  END_DIALOG=false
  while ! $END_DIALOG ; do
    whiptail --title "Pi.NMS Uninstallation" --msgbox "$LINE1\\n\\n$LINE2" $ROWS $COLS
    BUTTON=$?
    ask_cancel
    ANSWER=true
  done
}

ask_yesno() {
  LINE1=$(printf "%*s" $(((${#1}+$COLS-5)/2)) "$1")
  LINE2=$(printf "%*s" $(((${#2}+$COLS-5)/2)) "$2")

  if [ "$3" = "YES" ]; then
    DEF_BUTTON=""
  else
    DEF_BUTTON="--defaultno"
  fi

  END_DIALOG=false
  while ! $END_DIALOG ; do
    whiptail --title "Pi.NMS Uninstallation" --yesno $DEF_BUTTON "$LINE1\\n\\n$LINE2" $ROWS $COLS
    BUTTON=$?
    ask_cancel
  done

  if [ "$BUTTON" = "0" ] ; then
    ANSWER=true
  else
    ANSWER=false
  fi
}

ask_option() {
  MENU_ARGS=("$@")
  MENU_ARGS=("${MENU_ARGS[@]:1}")

  END_DIALOG=false
  while ! $END_DIALOG ; do
    ANSWER=$(whiptail --title "Pi.NMS Uninstallation" --menu "$1" $ROWS $COLS "${MENU_ARGS[@]}"  3>&2 2>&1 1>&3 )
    BUTTON=$?
    ask_cancel CANCEL
  done
}

ask_input() {
  LINE1=$(printf "%*s" $(((${#1}+$COLS-5)/2)) "$1")
  LINE2=$(printf "%*s" $(((${#2}+$COLS-5)/2)) "$2")

  END_DIALOG=false
  while ! $END_DIALOG ; do
    ANSWER=$(whiptail --title "Pi.NMS Uninstallation" --inputbox "$LINE1\\n\\n$LINE2" $ROWS $COLS "$3" 3>&2 2>&1 1>&3 )
    BUTTON=$?
    ask_cancel CANCEL

    if $END_DIALOG && [ "$ANSWER" = "" ] ; then
      msgbox "" "You must enter a value"
      END_DIALOG=false
    fi
  done
}

ask_cancel() {
  LINE0="Do you want to cancel the uninstallation process"
  LINE0=$(printf "\n\n%*s" $(((${#LINE0}+$COLS-5)/2)) "$LINE0")

  if [ "$BUTTON" = "1" ] && [ "$1" = "CANCEL" ] ; then BUTTON="255"; fi

  if [ "$BUTTON" = "255" ] ; then
    whiptail --title "Pi.NMS Uninstallation" --yesno --defaultno "$LINE0" $ROWS $COLS

    if [ "$?" = "0" ] ; then
      process_error "Uninstallation Aborted by User"
    fi
  else
    END_DIALOG=true
  fi
}

# ------------------------------------------------------------------------------
# Remove
# ------------------------------------------------------------------------------
remove_path() {
  local TARGET="$1"

  case "$TARGET" in
    "$PIALERT_HOME"|"$WEBROOT/pialert"|"$LIGHTTPD_CONF_DIR/conf-available/pialert_front.conf"|"$LIGHTTPD_CONF_DIR/conf-enabled/pialert_front.conf"|"/var/cache/lighttpd/compress/pialert"|"$PINMS_ARCHIVE"|"$LEGACY_ARCHIVE")
      ;;
    *)
      log_no_screen "Skipped out-of-scope uninstall path: $TARGET"
      return
      ;;
  esac

  if [ -e "$TARGET" ] || [ -L "$TARGET" ] ; then
    sudo rm -rf -- "$TARGET"                                      >> "$LOG" 2>&1
  fi
}

# ------------------------------------------------------------------------------
# Log
# ------------------------------------------------------------------------------
log() {
  echo "$1" | tee -a "$LOG"
}

log_no_screen () {
  echo "$1" >> "$LOG"
}

log_only_screen () {
  echo "$1"
}

print_msg() {
  log_no_screen ""
  log "$1"
}

print_superheader() {
  log ""
  log "############################################################"
  log " $1"
  log "############################################################"  
}

print_header() {
  log ""
  log "------------------------------------------------------------"
  log " $1"
  log "------------------------------------------------------------"
}

process_error() {
  log ""
  log "************************************************************"
  log "************************************************************"
  log "**             ERROR UNINSTALLING PI.NMS                  **"
  log "************************************************************"
  log "************************************************************"
  log ""

  # msgbox "****** ERROR UNINSTALLING Pi.NMS ******" "$1"
  exit 1
}

# ------------------------------------------------------------------------------
  main
  exit 0
