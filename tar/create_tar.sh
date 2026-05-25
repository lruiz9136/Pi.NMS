#!/bin/sh
# ------------------------------------------------------------------------------
#  Pi.NMS
#  Open Source Network Guard / WIFI & LAN intrusion detector 
#
#  create_tar.sh - Create the tar file for installation
# ------------------------------------------------------------------------------
#  lruiz9136 2026        pi.alert.application@gmail.com        GNU GPLv3
# ------------------------------------------------------------------------------

SCRIPT_DIR=`CDPATH= cd -- "$(dirname -- "$0")" && pwd`
PROJECT_DIR=`CDPATH= cd -- "$SCRIPT_DIR/.." && pwd`
PROJECT_NAME=`basename "$PROJECT_DIR"`

cd "$PROJECT_DIR"
pwd
PIALERT_VERSION=`awk '$1=="VERSION" { print $3 }' config/version.conf | tr -d \'`

# ------------------------------------------------------------------------------
ls -l tar/pialert*.tar 2>/dev/null || :
tar tvf tar/pialert_latest.tar 2>/dev/null | wc -l
rm tar/pialert_*.tar 2>/dev/null || :
rm tar/pialert_latest.tar 2>/dev/null || :

# ------------------------------------------------------------------------------
tar cvf "tar/pialert_$PIALERT_VERSION.tar" \
  --exclude="$PROJECT_NAME/tar" \
  --exclude="$PROJECT_NAME/.git" \
  --transform "s|^$PROJECT_NAME|pialert|" \
  -C "`dirname "$PROJECT_DIR"`" "$PROJECT_NAME" | wc -l

ln -s "pialert_$PIALERT_VERSION.tar" tar/pialert_latest.tar
ls -l tar/pialert*.tar