#!/bin/bash
# ------------------------------------------------------------------------------
#  Pi.NMS
#  Open Source Network Guard / WIFI & LAN intrusion detector 
#
#  pinms_update.sh - Update script
# ------------------------------------------------------------------------------
#  lruiz9136 2026        pi.alert.application@gmail.com        GNU GPLv3
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
INSTALL_DIR="${PINMS_INSTALL_DIR:-$HOME}"
PIALERT_HOME="${PINMS_HOME:-$INSTALL_DIR/pialert}"
LOG_NAME="pinms_update_`date +"%Y-%m-%d_%H-%M"`.log"
LOG="$INSTALL_DIR/$LOG_NAME"
PYTHON_BIN=python
PINMS_REPO="${PINMS_REPO:-lruiz9136/Pi.NMS}"
PINMS_BRANCH="${PINMS_BRANCH:-main}"
PINMS_ARCHIVE_URL="${PINMS_ARCHIVE_URL:-https://github.com/$PINMS_REPO/archive/refs/heads/$PINMS_BRANCH.tar.gz}"
PINMS_ARCHIVE="$INSTALL_DIR/pinms_latest.tar.gz"
MAIN_IP=`ip -o route get 1 | sed 's/^.*src \([^ ]*\).*$/\1/;q'`
if [ "$MAIN_IP" = "" ] ; then
  MAIN_IP=`hostname -I 2>/dev/null | awk '{print $1}'`
fi
CHECK_ONLY=false

if [ "$1" = "--check" ] || [ "$PINMS_CHECK_ONLY" = "1" ] ; then
  CHECK_ONLY=true
fi


# ------------------------------------------------------------------------------
# Main
# ------------------------------------------------------------------------------
main() {
  if [ "$CHECK_ONLY" = true ] ; then
    preflight_update
    exit 0
  fi

  print_superheader "Pi.NMS Update"
  log "`date`"
  log "Logfile: `get_log_path`"
  log ""

  set -e

  check_pialert_home
  check_python_version

  create_backup
  move_files
  normalize_pialert_permissions "$PIALERT_HOME"
  clean_files

  check_packages
  download_pialert
  update_config
  update_db

  test_pialert
  write_source_metadata
  
  print_header "Update process finished"
  print_msg ""

  move_logfile
}

# ------------------------------------------------------------------------------
# Preflight update checks
# ------------------------------------------------------------------------------
preflight_update() {
  print_superheader "Pi.NMS Update Preflight"
  log "`date`"
  log "Logfile: `get_log_path`"
  log ""

  check_pialert_home
  check_required_command curl
  check_required_command tar
  check_required_command mktemp
  check_required_command find
  check_required_command sed
  check_required_command head
  check_required_command sudo
  check_python_version
  check_update_permissions
  check_package_access
  check_archive_access

  print_header "Preflight checks passed"
  print_msg "- Update script can run for $PINMS_REPO ($PINMS_BRANCH)"
}

# ------------------------------------------------------------------------------
# Check required command
# ------------------------------------------------------------------------------
check_required_command() {
  if ! command -v "$1" >/dev/null 2>&1 ; then
    process_error "Required command not found: $1"
  fi
}

# ------------------------------------------------------------------------------
# Check update permissions
# ------------------------------------------------------------------------------
check_update_permissions() {
  print_msg "- Checking update permissions..."

  if [ "$(id -u)" != "0" ] && ! can_write_install_paths ; then
    if sudo -n true >/dev/null 2>&1 ; then
      print_msg "  - Direct write access is unavailable; update can use sudo."
      return
    fi
  fi

  if [ ! -w "$PIALERT_HOME" ] ; then
    process_error "Update user cannot write to Pi.NMS directory: $PIALERT_HOME"
  fi

  if [ ! -w "$PIALERT_HOME/config" ] ; then
    process_error "Update user cannot write to Pi.NMS config directory: $PIALERT_HOME/config"
  fi

  if [ ! -w "$PIALERT_HOME/db" ] ; then
    process_error "Update user cannot write to Pi.NMS database directory: $PIALERT_HOME/db"
  fi

  if [ ! -w "$INSTALL_DIR" ] ; then
    process_error "Update user cannot write temporary update files to: $INSTALL_DIR"
  fi
}

# ------------------------------------------------------------------------------
# Can write install paths
# ------------------------------------------------------------------------------
can_write_install_paths() {
  [ -w "$PIALERT_HOME" ] && \
  [ -w "$PIALERT_HOME/config" ] && \
  [ -w "$PIALERT_HOME/db" ] && \
  [ -w "$INSTALL_DIR" ]
}

# ------------------------------------------------------------------------------
# Check package access
# ------------------------------------------------------------------------------
check_package_access() {
  print_msg "- Checking package access..."

  if sudo -n true >/dev/null 2>&1 ; then
    return
  fi

  check_required_command sqlite3

  if command -v apt-get >/dev/null 2>&1 ; then
    print_msg "  - sudo is unavailable; package installation will be skipped."
  else
    print_msg "  - apt-get is unavailable; package installation will be skipped."
  fi
}

# ------------------------------------------------------------------------------
# Check source archive access
# ------------------------------------------------------------------------------
check_archive_access() {
  print_msg "- Checking source archive access..."

  TMP_ARCHIVE=`mktemp`
  if ! curl -fsSL --max-time 30 -o "$TMP_ARCHIVE" "$PINMS_ARCHIVE_URL" ; then
    rm -f "$TMP_ARCHIVE"
    process_error "Unable to download Pi.NMS archive: $PINMS_ARCHIVE_URL"
  fi

  if ! tar tzf "$TMP_ARCHIVE" >/dev/null 2>&1 ; then
    rm -f "$TMP_ARCHIVE"
    process_error "Downloaded Pi.NMS archive could not be read"
  fi

  rm -f "$TMP_ARCHIVE"
}

# ------------------------------------------------------------------------------
# Create backup
# ------------------------------------------------------------------------------
create_backup() {
  # Previous backups are not deleted
  # print_msg "- Deleting previous Pi.NMS backups..."
  # rm "$INSTALL_DIR/"pinms_update_backup_*.tar  2>/dev/null || :
  
  print_msg "- Creating new Pi.NMS backup..."
  cd "$(dirname "$PIALERT_HOME")"
  tar cvf "$INSTALL_DIR"/pinms_update_backup_`date +"%Y-%m-%d_%H-%M"`.tar "$(basename "$PIALERT_HOME")" --checkpoint=100 --checkpoint-action="ttyout=."     2>&1 >> "$LOG"
  echo ""
}

# ------------------------------------------------------------------------------
# Move files to the new directory
# ------------------------------------------------------------------------------
move_files() {
  if [ -e "$PIALERT_HOME/back/pialert.conf" ] ; then
    print_msg "- Moving pialert.conf to the new directory..."
    mkdir -p "$PIALERT_HOME/config"
    mv "$PIALERT_HOME/back/pialert.conf" "$PIALERT_HOME/config"
  fi
}

# ------------------------------------------------------------------------------
# Move files to the new directory
# ------------------------------------------------------------------------------
clean_files() {
  print_msg "- Cleaning previous version..."
  rm -r "$PIALERT_HOME/back"    2>/dev/null || :
  rm -r "$PIALERT_HOME/doc"     2>/dev/null || :
  rm -r "$PIALERT_HOME/docs"    2>/dev/null || :
  rm -r "$PIALERT_HOME/front"   2>/dev/null || :
  rm -r "$PIALERT_HOME/install" 2>/dev/null || :
  rm -r "$PIALERT_HOME/"*.txt   2>/dev/null || :
  rm -r "$PIALERT_HOME/"*.md    2>/dev/null || :
}

# ------------------------------------------------------------------------------
# Check packages
# ------------------------------------------------------------------------------
check_packages() {
  if ! sudo -n true >/dev/null 2>&1 ; then
    print_msg "- Skipping package checks because sudo is unavailable..."
    check_required_command sqlite3
    return
  fi

  print_msg "- Checking package apt-utils..."
  sudo apt-get install apt-utils -y                               2>&1 >> "$LOG"

  print_msg "- Checking package sqlite3..."
  sudo apt-get install sqlite3 -y                                 2>&1 >> "$LOG"

  print_msg "- Checking packages dnsutils & net-tools..."
  sudo apt-get install dnsutils net-tools -y                      2>&1 >> "$LOG"
}


# ------------------------------------------------------------------------------
# Download and uncompress Pi.NMS
# ------------------------------------------------------------------------------
download_pialert() {
  if [ -f "$PINMS_ARCHIVE" ] ; then
    print_msg "- Deleting previous downloaded archive"
    rm -r "$PINMS_ARCHIVE"
  fi
  
  print_msg "- Downloading Pi.NMS from $PINMS_REPO ($PINMS_BRANCH)..."
  curl -L -o "$PINMS_ARCHIVE" "$PINMS_ARCHIVE_URL"
  echo ""

  print_msg "- Uncompressing source archive"
  TMP_DIR=`mktemp -d`
  tar xzf "$PINMS_ARCHIVE" -C "$TMP_DIR" --checkpoint=100 --checkpoint-action="ttyout=."  2>&1 >> "$LOG"
  echo ""

  SOURCE_DIR=`find "$TMP_DIR" -mindepth 1 -maxdepth 1 -type d | head -n 1`
  if [ "$SOURCE_DIR" = "" ] ; then
    process_error "Downloaded Pi.NMS archive did not contain a source directory"
  fi

  print_msg "- Installing updated Pi.NMS files..."
  cp -R "$SOURCE_DIR/back" "$PIALERT_HOME/"                         2>&1 >> "$LOG"
  cp -R "$SOURCE_DIR/docs" "$PIALERT_HOME/"                         2>&1 >> "$LOG"
  cp -R "$SOURCE_DIR/front" "$PIALERT_HOME/"                        2>&1 >> "$LOG"
  cp -R "$SOURCE_DIR/install" "$PIALERT_HOME/"                      2>&1 >> "$LOG"
  cp "$SOURCE_DIR/LICENSE.txt" "$PIALERT_HOME/"                     2>&1 >> "$LOG"
  cp "$SOURCE_DIR/README.md" "$PIALERT_HOME/"                       2>&1 >> "$LOG"
  if [ -f "$SOURCE_DIR/ROADMAP.md" ] ; then
    cp "$SOURCE_DIR/ROADMAP.md" "$PIALERT_HOME/"                    2>&1 >> "$LOG"
  fi
  cp "$SOURCE_DIR/config/version.conf" "$PIALERT_HOME/config/"      2>&1 >> "$LOG"

  verify_pialert_source
  normalize_pialert_permissions "$PIALERT_HOME"

  print_msg "- Deleting downloaded archive..."
  rm -r "$PINMS_ARCHIVE"
  rm -r "$TMP_DIR"
}

# ------------------------------------------------------------------------------
# Verify installed source
# ------------------------------------------------------------------------------
verify_pialert_source() {
  if [ ! -f "$PIALERT_HOME/front/php/templates/header.php" ] ; then
    process_error "Pi.NMS web files were not installed correctly"
  fi

  if ! grep -Fq "Pi.NMS" "$PIALERT_HOME/README.md" ; then
    process_error "Downloaded source does not appear to be Pi.NMS. Check PINMS_REPO, PINMS_BRANCH, or PINMS_ARCHIVE_URL."
  fi
}

# ------------------------------------------------------------------------------
# Write source metadata
# ------------------------------------------------------------------------------
write_source_metadata() {
  print_msg "- Recording source metadata..."
  SOURCE_COMMIT=`curl -fsSL "https://api.github.com/repos/$PINMS_REPO/commits/$PINMS_BRANCH" | $PYTHON_BIN -c 'import sys,json; sys.stdout.write(json.load(sys.stdin).get("sha", ""))'`
  if [ "$SOURCE_COMMIT" = "" ] ; then
    SOURCE_COMMIT="unknown"
  fi

  cat > "$PIALERT_HOME/config/source.conf" <<EOF
# Pi.NMS source metadata
SOURCE_REPO='$PINMS_REPO'
SOURCE_BRANCH='$PINMS_BRANCH'
SOURCE_ARCHIVE_URL='$PINMS_ARCHIVE_URL'
SOURCE_COMMIT='$SOURCE_COMMIT'
SOURCE_INSTALLED_AT='`date -u +"%Y-%m-%dT%H:%M:%SZ"`'
EOF
}

# ------------------------------------------------------------------------------
#  Update conf file
# ------------------------------------------------------------------------------
update_config() {
  print_msg "- Config backup..."
  cp "$PIALERT_HOME/config/pialert.conf" "$PIALERT_HOME/config/pialert.conf.back"  2>&1 >> "$LOG"

  print_msg "- Updating config file..."
  sed -i '/VERSION/d' "$PIALERT_HOME/config/pialert.conf"                          2>&1 >> "$LOG"
  sed -i 's/PA_FRONT_URL/REPORT_DEVICE_URL/g' "$PIALERT_HOME/config/pialert.conf"  2>&1 >> "$LOG"
  if [ "$MAIN_IP" != "" ] ; then
    sed -i "s|^REPORT_DEVICE_URL *= *['\"]http://pi.alert/deviceDetails.php?mac=['\"]|REPORT_DEVICE_URL = 'http://$MAIN_IP/pialert/deviceDetails.php?mac='|" "$PIALERT_HOME/config/pialert.conf"  2>&1 >> "$LOG"
  fi
  
  if ! grep -Fq PIALERT_PATH "$PIALERT_HOME/config/pialert.conf" ; then
    echo "PIALERT_PATH    = '$PIALERT_HOME'" >> "$PIALERT_HOME/config/pialert.conf"
  fi      

  if [ "$MAIN_IP" != "" ] && ! grep -Fq REPORT_DEVICE_URL "$PIALERT_HOME/config/pialert.conf" ; then
    echo "REPORT_DEVICE_URL = 'http://$MAIN_IP/pialert/deviceDetails.php?mac='" >> "$PIALERT_HOME/config/pialert.conf"
  fi

  if ! grep -Fq QUERY_MYIP_SERVER "$PIALERT_HOME/config/pialert.conf" ; then
    echo "QUERY_MYIP_SERVER = 'http://ipv4.icanhazip.com'" >> "$PIALERT_HOME/config/pialert.conf"
  fi      

  if ! grep -Fq SCAN_SUBNETS "$PIALERT_HOME/config/pialert.conf" ; then
    echo "SCAN_SUBNETS      = '--localnet'" >> "$PIALERT_HOME/config/pialert.conf"
  fi      
}

# ------------------------------------------------------------------------------
#  DB DDL
# ------------------------------------------------------------------------------
update_db() {
  print_msg "- Updating DB permissions..."
  normalize_pialert_permissions "$PIALERT_HOME/db"

  if can_use_sudo ; then
    print_msg "- Installing sqlite3..."
    sudo apt-get install sqlite3 -y                               2>&1 >> "$LOG"
  else
    print_msg "- Skipping sqlite3 install because sudo is unavailable..."
    check_required_command sqlite3
  fi

  print_msg "- Checking 'Parameters' table..."
  TAB=`sqlite3 $PIALERT_HOME/db/pialert.db "SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='Parameters' COLLATE NOCASE;"`              2>&1 >> "$LOG"
  if [ "$TAB" == "0" ] ; then
    print_msg "  - Creating 'Parameters' table..."
    sqlite3 $PIALERT_HOME/db/pialert.db "CREATE TABLE Parameters (par_ID STRING (50) PRIMARY KEY NOT NULL COLLATE NOCASE, par_Value STRING (250) );"   2>&1 >> "$LOG"
    sqlite3 $PIALERT_HOME/db/pialert.db "CREATE INDEX IDX_par_ID ON Parameters (par_ID COLLATE NOCASE);"                                               2>&1 >> "$LOG"
  fi
  
  print_msg "- Checking Devices new columns..."
  COL=`sqlite3 $PIALERT_HOME/db/pialert.db "SELECT COUNT(*) FROM PRAGMA_TABLE_INFO ('Devices') WHERE name='dev_NewDevice' COLLATE NOCASE";`            2>&1 >> "$LOG"
  if [ "$COL" == "0" ] ; then
    print_msg "  - Adding column 'NewDevice' to 'Devices'..."
    sqlite3 $PIALERT_HOME/db/pialert.db "ALTER TABLE Devices ADD COLUMN dev_NewDevice BOOLEAN NOT NULL DEFAULT (1) CHECK (dev_NewDevice IN (0, 1) );"  2>&1 >> "$LOG"
    sqlite3 $PIALERT_HOME/db/pialert.db "CREATE INDEX IDX_dev_NewDevice ON Devices (dev_NewDevice);"
  fi

  COL=`sqlite3 $PIALERT_HOME/db/pialert.db "SELECT COUNT(*) FROM PRAGMA_TABLE_INFO ('Devices') WHERE name='dev_Location' COLLATE NOCASE";`             2>&1 >> "$LOG"
  if [ "$COL" == "0" ] ; then
    print_msg "  - Adding column 'Location' to 'Devices'..."
    sqlite3 $PIALERT_HOME/db/pialert.db "ALTER TABLE Devices ADD COLUMN dev_Location STRING(250) COLLATE NOCASE;"                                      2>&1 >> "$LOG"
  fi

  COL=`sqlite3 $PIALERT_HOME/db/pialert.db "SELECT COUNT(*) FROM PRAGMA_TABLE_INFO ('Devices') WHERE name='dev_Archived' COLLATE NOCASE";`               2>&1 >> "$LOG"
  if [ "$COL" == "0" ] ; then
    print_msg "  - Adding column 'Archived / Hidden' to 'Devices'..."
    sqlite3 $PIALERT_HOME/db/pialert.db "ALTER TABLE Devices ADD COLUMN dev_Archived BOOLEAN NOT NULL DEFAULT (0) CHECK (dev_Archived IN (0, 1) );"    2>&1 >> "$LOG"
    sqlite3 $PIALERT_HOME/db/pialert.db "CREATE INDEX IDX_dev_Archived ON Devices (dev_Archived);"                                                     2>&1 >> "$LOG"
  fi

  print_msg "- Cheking Internet scancycle..."
  sqlite3 $PIALERT_HOME/db/pialert.db "UPDATE Devices set dev_ScanCycle=1, dev_AlertEvents=1, dev_AlertDeviceDown=1 WHERE dev_MAC='Internet' AND dev_ScanCycle=0;"  2>&1 >> "$LOG"
}

# ------------------------------------------------------------------------------
# Normalize Pi.NMS permissions
# ------------------------------------------------------------------------------
normalize_pialert_permissions() {
  TARGET_PATH="${1:-$PIALERT_HOME}"

  if [ ! -e "$TARGET_PATH" ] ; then
    return
  fi

  print_msg "- Setting update permissions for $TARGET_PATH..."
  if [ "$(id -u)" = "0" ] ; then
    chgrp -R www-data "$TARGET_PATH"                              2>&1 >> "$LOG"
    chmod -R g+rwX "$TARGET_PATH"                                 2>&1 >> "$LOG"
    find "$TARGET_PATH" -type d -exec chmod g+s {} \;             2>&1 >> "$LOG"
  elif can_use_sudo ; then
    sudo chown -R "`id -un`:www-data" "$TARGET_PATH"              2>&1 >> "$LOG"
    chmod -R g+rwX "$TARGET_PATH"                                 2>&1 >> "$LOG"
    find "$TARGET_PATH" -type d -exec chmod g+s {} \;             2>&1 >> "$LOG"
  else
    print_msg "  - Skipping group ownership update because sudo is unavailable."
    CURRENT_UID=`id -u`
    find "$TARGET_PATH" -user "$CURRENT_UID" -exec chmod g+rwX {} \; 2>&1 >> "$LOG"
    find "$TARGET_PATH" -type d -user "$CURRENT_UID" -exec chmod g+s {} \; 2>&1 >> "$LOG"
  fi
}

# ------------------------------------------------------------------------------
# Check for non-interactive sudo
# ------------------------------------------------------------------------------
can_use_sudo() {
  command -v sudo >/dev/null 2>&1 && sudo -n true >/dev/null 2>&1
}

# ------------------------------------------------------------------------------
# Test Pi.NMS
# ------------------------------------------------------------------------------
test_pialert() {
  print_msg "- Testing Pi.NMS HW vendors database update process..."
  print_msg "*** PLEASE WAIT A COUPLE OF MINUTES..."
  stdbuf -i0 -o0 -e0 $PYTHON_BIN $PIALERT_HOME/back/pialert.py update_vendors_silent  2>&1 | tee -ai "$LOG"

  echo ""
  print_msg "- Testing Pi.NMS Internet IP Lookup..."
  stdbuf -i0 -o0 -e0 $PYTHON_BIN $PIALERT_HOME/back/pialert.py internet_IP            2>&1 | tee -ai "$LOG"

  echo ""
  print_msg "- Testing Pi.NMS Network scan..."
  if [ "$(id -u)" != "0" ] && ! can_use_sudo ; then
    print_msg "  - Skipping network scan test because sudo is unavailable."
    return
  fi

  print_msg "*** PLEASE WAIT A COUPLE OF MINUTES..."
  stdbuf -i0 -o0 -e0 $PYTHON_BIN $PIALERT_HOME/back/pialert.py 1                      2>&1 | tee -ai "$LOG"
}

# ------------------------------------------------------------------------------
# Check Pi.NMS Installation Path
# ------------------------------------------------------------------------------
check_pialert_home() {
  if [ ! -e "$PIALERT_HOME" ] ; then
    process_error "Pi.NMS directory dosn't exists: $PIALERT_HOME"
  fi
}

# ------------------------------------------------------------------------------
# Check Python versions available
# ------------------------------------------------------------------------------
check_python_version() {
  print_msg "- Checking Python..."
  if [ -f /usr/bin/python ] ; then
    PYTHON_BIN="python"
  elif [ -f /usr/bin/python3 ] ; then
    PYTHON_BIN="python3"
  else
    process_error "Python NOT installed"
  fi
}


# ------------------------------------------------------------------------------
# Move Logfile
# ------------------------------------------------------------------------------
move_logfile() {
  NEWLOG="$PIALERT_HOME/log/$LOG_NAME"

  mkdir -p "$PIALERT_HOME/log"
  if [ "$LOG" != "$NEWLOG" ] ; then
    cp "$LOG" "$NEWLOG" 2>/dev/null || :
  fi

  LOG="$NEWLOG"
  NEWLOG=""
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
  log "**              ERROR UPDATING PI.NMS                     **"
  log "************************************************************"
  log "************************************************************"
  log ""
  log "$1"
  log ""
  log "Use 'cat `get_log_path`' to view update log"
  log ""

  exit 1
}

# ------------------------------------------------------------------------------
# Get log path
# ------------------------------------------------------------------------------
get_log_path() {
  case "$LOG" in
    /*) echo "$LOG" ;;
    *) echo "`pwd`/$LOG" ;;
  esac
}

# ------------------------------------------------------------------------------
  main
  exit 0
