#!/bin/sh
# ------------------------------------------------------------------------------
#  Pi.NMS
#  Open Source Network Guard / WIFI & LAN intrusion detector 
#
#  update_vendors.sh - Back module. IEEE Vendors db update
# ------------------------------------------------------------------------------
#  Puche 2021        pi.alert.application@gmail.com        GNU GPLv3
# ------------------------------------------------------------------------------

# ----------------------------------------------------------------------
#  Main directories to update:
#    /usr/share/arp-scan
#    /usr/share/ieee-data
#    /var/lib/ieee-data
# ----------------------------------------------------------------------


# ----------------------------------------------------------------------
if [ -d /usr/share/ieee-data ]; then
  echo Updating... /usr/share/ieee-data/
  cd /usr/share/ieee-data/ || exit 0

  sudo mkdir -p 2_backup
  sudo cp *.txt 2_backup 2>/dev/null || :
  sudo cp *.csv 2_backup 2>/dev/null || :

  sudo curl $1 -# -O http://standards-oui.ieee.org/iab/iab.csv || :
  sudo curl $1 -# -O http://standards-oui.ieee.org/iab/iab.txt || :

  sudo curl $1 -# -O http://standards-oui.ieee.org/oui28/mam.csv || :
  sudo curl $1 -# -O http://standards-oui.ieee.org/oui28/mam.txt || :

  sudo curl $1 -# -O http://standards-oui.ieee.org/oui36/oui36.csv || :
  sudo curl $1 -# -O http://standards-oui.ieee.org/oui36/oui36.txt || :

  sudo curl $1 -# -O http://standards-oui.ieee.org/oui/oui.csv || :
  sudo curl $1 -# -O http://standards-oui.ieee.org/oui/oui.txt || :
else
  echo "Skipping /usr/share/ieee-data update: directory not found"
fi


# ----------------------------------------------------------------------
echo ""
echo Updating... /usr/share/arp-scan/
cd /usr/share/arp-scan || exit 0

sudo mkdir -p 2_backup
sudo cp *.txt 2_backup 2>/dev/null || :

# Update from ieee-data when supported by the installed arp-scan package.
if command -v get-oui >/dev/null 2>&1; then
  sudo get-oui -v || :
fi

if command -v get-iab >/dev/null 2>&1; then
  sudo get-iab -v || :
fi

# Update from ieee website
# sudo get-iab -v -u http://standards-oui.ieee.org/iab/iab.txt
# sudo get-oui -v -u http://standards-oui.ieee.org/oui/oui.txt

# Update from ieee website develop
# sudo get-iab -v -u http://standards.ieee.org/develop/regauth/iab/iab.txt
# sudo get-oui -v -u http://standards.ieee.org/develop/regauth/oui/oui.txt

# Update from Sanitized oui (linuxnet.ca)
# sudo get-oui -v -u https://linuxnet.ca/ieee/oui.txt