# Pi.NMS Uninstallation Guide
<!--- --------------------------------------------------------------------- --->
Estimated time: 5'


## One-step Automated Uninstall:
<!--- --------------------------------------------------------------------- --->
  #### `curl -sSL https://github.com/lruiz9136/Pi.NMS/raw/main/install/pinms_uninstall.sh | bash`

## Uninstallation process (step by step)
<!--- --------------------------------------------------------------------- --->

1.1 - Remove Pi.NMS files
  ```
  rm -rf "$HOME/pialert"
  rm -f "$HOME/pinms_latest.tar.gz" "$HOME/pialert_latest.tar.gz"
  ```

1.2 - Remove Pi.NMS web front
  ```
  sudo rm -rf "/var/www/html/pialert"
  ```

1.3 - Remove lighttpd Pi.NMS config
  ```
  sudo rm -f "/etc/lighttpd/conf-available/pialert_front.conf"
  sudo rm -f "/etc/lighttpd/conf-enabled/pialert_front.conf"
  ```

1.4 - Remove lighttpd Pi.NMS cache
  ```
  sudo rm -rf /var/cache/lighttpd/compress/pialert
  ```

1.5 - Remove Pi.NMS DNS entry
  ```
  if [ -f /etc/pihole/custom.list ]; then sudo sed -i '/pi.alert/d' /etc/pihole/custom.list; fi
  if command -v pihole >/dev/null 2>&1; then sudo pihole restartdns; fi
  ```

1.6 - Remove Pi.NMS crontab jobs
  ```
  if command -v crontab >/dev/null 2>&1; then crontab -l 2>/dev/null | sed ':a;N;$!ba;s/#-------------------------------------------------------------------------------\n#  Pi.Alert\n#  Open Source Network Guard \/ WIFI & LAN intrusion detector \n#\n#  pialert.cron - Back module. Crontab jobs\n#-------------------------------------------------------------------------------\n#  Puche 2021        pi.alert.application@gmail.com        GNU GPLv3\n#-------------------------------------------------------------------------------//g' | sed '/pialert.py/d' | crontab -; fi
  ```

### Uninstallation Notes
<!--- --------------------------------------------------------------------- --->
  - If you installed Pi-hole during the Pi.NMS installation process,
 
    Pi-hole will still be available after uninstalling Pi.NMS


  - lighttpd, PHP, arp-scan & Python have not been uninstalled
 
    They may be required by other software
    
    You can uninstall them manually with command 'apt-get remove XX'

### License
  GPL 3.0
  [Read more here](../LICENSE.txt)

### Contact
  https://github.com/lruiz9136/Pi.NMS/issues