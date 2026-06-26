#!/bin/bash
# ------------------------------------------------------------------------------
#  Pi.NMS
#  One-time migration helper for root-owned test installs.
#
#  This script is not part of the normal Pi.NMS install/update lifecycle.
#  It exists to move a test install out of /root/pialert so the web UI updater
#  can write application files without granting the web server sudo access.
# ------------------------------------------------------------------------------

set -e

SOURCE_HOME="${SOURCE_HOME:-/root/pialert}"
PINMS_USER="${PINMS_USER:-pinms}"
PINMS_GROUP="${PINMS_GROUP:-pinms}"
WEB_USER="${WEB_USER:-www-data}"
TARGET_BASE="${TARGET_BASE:-/home/$PINMS_USER}"
TARGET_HOME="${TARGET_HOME:-$TARGET_BASE/pialert}"
WEBROOT="${WEBROOT:-/var/www/html}"
WEB_LINK="$WEBROOT/pialert"
LIGHTTPD_SERVICE="${LIGHTTPD_SERVICE:-lighttpd}"
LOG="pinms_migrate_root_install_`date +"%Y-%m-%d_%H-%M"`.log"

main() {
  require_root

  print_header "Pi.NMS Root Install Migration"
  log "Source: $SOURCE_HOME"
  log "Target: $TARGET_HOME"
  log "Logfile: `pwd`/$LOG"
  log ""

  validate_paths
  create_pinms_user
  copy_install
  update_config_path
  update_permissions
  update_web_link
  migrate_crontab
  restart_lighttpd
  sanity_check

  print_header "Migration complete"
  log "Pi.NMS was copied to: $TARGET_HOME"
  log "The original root install was kept at: $SOURCE_HOME"
  log "After testing, remove the old root install manually if you no longer need it."
}

require_root() {
  if [ "$(id -u)" != "0" ] ; then
    echo "This one-time migration helper must be run as root."
    exit 1
  fi
}

validate_paths() {
  print_step "Validating source install"

  if [ ! -d "$SOURCE_HOME" ] ; then
    fail "Source install was not found: $SOURCE_HOME"
  fi

  if [ ! -f "$SOURCE_HOME/front/php/templates/header.php" ] ; then
    fail "Source install does not look like Pi.NMS: $SOURCE_HOME"
  fi

  if [ -e "$TARGET_HOME" ] || [ -L "$TARGET_HOME" ] ; then
    fail "Target already exists: $TARGET_HOME"
  fi

  case "$SOURCE_HOME" in
    /root/pialert) ;;
    *) fail "Refusing to migrate unexpected source path: $SOURCE_HOME" ;;
  esac

  case "$TARGET_HOME" in
    /home/*/pialert|/opt/*/pialert) ;;
    *) fail "Refusing to migrate to unexpected target path: $TARGET_HOME" ;;
  esac
}

create_pinms_user() {
  print_step "Creating migration user/group"

  if ! getent group "$PINMS_GROUP" >/dev/null 2>&1 ; then
    groupadd "$PINMS_GROUP"
  fi

  if ! id "$PINMS_USER" >/dev/null 2>&1 ; then
    NOLOGIN_SHELL="/usr/sbin/nologin"
    if [ ! -x "$NOLOGIN_SHELL" ] ; then
      NOLOGIN_SHELL="/bin/false"
    fi

    useradd --system --home-dir "$TARGET_BASE" --create-home --gid "$PINMS_GROUP" --shell "$NOLOGIN_SHELL" "$PINMS_USER"
  fi

  if id "$WEB_USER" >/dev/null 2>&1 ; then
    usermod -a -G "$PINMS_GROUP" "$WEB_USER"
  else
    log "Warning: web user not found, skipped group membership: $WEB_USER"
  fi

  mkdir -p "$TARGET_BASE"
  chown "$PINMS_USER:$PINMS_GROUP" "$TARGET_BASE"
  chmod 770 "$TARGET_BASE"
}

copy_install() {
  print_step "Copying install"

  mkdir -p "$TARGET_HOME"
  tar cpf - -C "$(dirname "$SOURCE_HOME")" "$(basename "$SOURCE_HOME")" | tar xpf - -C "$TARGET_BASE"
}

update_config_path() {
  print_step "Updating Pi.NMS config path"

  if [ -f "$TARGET_HOME/config/pialert.conf" ] ; then
    if grep -q '^PIALERT_PATH' "$TARGET_HOME/config/pialert.conf" ; then
      sed -i "s|^PIALERT_PATH.*=.*|PIALERT_PATH      = '$TARGET_HOME'|" "$TARGET_HOME/config/pialert.conf"
    else
      echo "PIALERT_PATH      = '$TARGET_HOME'" >> "$TARGET_HOME/config/pialert.conf"
    fi
  fi
}

update_permissions() {
  print_step "Updating ownership and permissions"

  chown -R "$PINMS_USER:$PINMS_GROUP" "$TARGET_HOME"
  chmod -R u+rwX,g+rwX,o-rwx "$TARGET_HOME"
  find "$TARGET_HOME" -type d -exec chmod g+s {} \;

  if [ -d "$TARGET_HOME/front" ] ; then
    chmod -R g+rwX "$TARGET_HOME/front"
  fi
}

update_web_link() {
  print_step "Updating web symlink"

  if [ -e "$WEB_LINK" ] || [ -L "$WEB_LINK" ] ; then
    rm -rf "$WEB_LINK"
  fi

  ln -s "$TARGET_HOME/front" "$WEB_LINK"
}

migrate_crontab() {
  print_step "Migrating root crontab paths"

  if ! command -v crontab >/dev/null 2>&1 ; then
    log "crontab command not found, skipped cron migration"
    return
  fi

  TMP_CRON=`mktemp`
  crontab -l 2>/dev/null > "$TMP_CRON" || true

  if grep -q 'pialert/back/pialert.py' "$TMP_CRON" ; then
    sed -i "s|~/pialert|$TARGET_HOME|g" "$TMP_CRON"
    sed -i "s|/root/pialert|$TARGET_HOME|g" "$TMP_CRON"
    crontab "$TMP_CRON"
  else
    log "No Pi.NMS crontab entries found for root"
  fi

  rm -f "$TMP_CRON"
}

restart_lighttpd() {
  print_step "Restarting web server"

  if command -v systemctl >/dev/null 2>&1 ; then
    systemctl restart "$LIGHTTPD_SERVICE" || service "$LIGHTTPD_SERVICE" restart || true
  else
    service "$LIGHTTPD_SERVICE" restart || true
  fi
}

sanity_check() {
  print_step "Running sanity checks"

  if [ ! -L "$WEB_LINK" ] ; then
    fail "Web link was not created: $WEB_LINK"
  fi

  if [ "$(readlink "$WEB_LINK")" != "$TARGET_HOME/front" ] ; then
    fail "Web link points to unexpected target: `readlink "$WEB_LINK"`"
  fi

  if [ ! -f "$TARGET_HOME/config/source.conf" ] ; then
    log "Warning: source metadata was not found: $TARGET_HOME/config/source.conf"
  fi

  if id "$WEB_USER" >/dev/null 2>&1 && ! id -nG "$WEB_USER" | tr ' ' '\n' | grep -qx "$PINMS_GROUP" ; then
    log "Warning: $WEB_USER is not in $PINMS_GROUP yet. A service/session restart may be needed."
  fi
}

print_header() {
  log ""
  log "############################################################"
  log " $1"
  log "############################################################"
}

print_step() {
  log ""
  log "- $1..."
}

log() {
  echo "$1" | tee -a "$LOG"
}

fail() {
  log ""
  log "ERROR: $1"
  log "Use 'cat `pwd`/$LOG' to view migration log"
  exit 1
}

main
