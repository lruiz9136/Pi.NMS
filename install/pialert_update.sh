#!/bin/bash
# ------------------------------------------------------------------------------
#  Pi.NMS
#  Compatibility wrapper for the legacy update script name.
# ------------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

if [ -f "$SCRIPT_DIR/pinms_update.sh" ] ; then
  exec bash "$SCRIPT_DIR/pinms_update.sh" "$@"
fi

INSTALL_DIR="${PINMS_INSTALL_DIR:-$HOME}"
PINMS_HOME="${PINMS_HOME:-$INSTALL_DIR/pialert}"
SOURCE_CONF="$PINMS_HOME/config/source.conf"

if [ -f "$SOURCE_CONF" ] ; then
  SOURCE_REPO_VALUE=`sed -n "s/^SOURCE_REPO=['\"]\\{0,1\\}\\([^'\"]*\\)['\"]\\{0,1\\}$/\\1/p" "$SOURCE_CONF" | head -n 1`
  SOURCE_BRANCH_VALUE=`sed -n "s/^SOURCE_BRANCH=['\"]\\{0,1\\}\\([^'\"]*\\)['\"]\\{0,1\\}$/\\1/p" "$SOURCE_CONF" | head -n 1`
fi

PINMS_REPO="${PINMS_REPO:-${SOURCE_REPO_VALUE:-lruiz9136/Pi.NMS}}"
PINMS_BRANCH="${PINMS_BRANCH:-${SOURCE_BRANCH_VALUE:-main}}"
PINMS_UPDATE_SCRIPT_URL="${PINMS_UPDATE_SCRIPT_URL:-https://github.com/$PINMS_REPO/raw/$PINMS_BRANCH/install/pinms_update.sh}"

export PINMS_REPO
export PINMS_BRANCH
export PINMS_ARCHIVE_URL
export PINMS_HOME
export PINMS_INSTALL_DIR

curl -fsSL "$PINMS_UPDATE_SCRIPT_URL" | bash
