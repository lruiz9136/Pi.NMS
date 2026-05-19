# Pi.NMS Installation Guide
<!--- --------------------------------------------------------------------- --->
Initially designed to run on a Raspberry PI, probably it can run on many other
Linux distributions.

Estimated time: 20'

### Dependencies
  | Dependency | Comments                                                 |
  | ---------- | -------------------------------------------------------- |
  | Lighttpd   | Probably works on other webservers / not tested          |
  | arp-scan   | Required for Scan Method 1                               |
  | Pi.hole    | Optional. Scan Method 2. Check devices doing DNS queries |
  | dnsmasq    | Optional. Scan Method 3. Check devices using DHCP server |
  | IEEE HW DB | Necessary to identified Device vendor                    |

## One-step Automated Install:
<!--- --------------------------------------------------------------------- --->
  #### `curl -sSL https://github.com/pucherot/Pi.Alert/raw/main/install/pialert_install.sh | bash`

## One-step Automated Update:
<!--- --------------------------------------------------------------------- --->
  #### `curl -sSL https://github.com/pucherot/Pi.Alert/raw/main/install/pialert_update.sh | bash`

## Uninstall process
<!--- --------------------------------------------------------------------- --->
  - [Unistall process](./UNINSTALL.md)

## Installation process (step by step)
<!--- --------------------------------------------------------------------- --->

### Raspberry Setup
<!--- --------------------------------------------------------------------- --->
1.1 - Install 'Raspberry Pi OS'
  - Instructions https://www.raspberrypi.org/documentation/installation/installing-images/
  - *Lite version (without Desktop) is enough for Pi.NMS*

1.2 - Activate ssh
  - Create a empty file with name 'ssh' in the boot partition of the SD

1.3 - Start the raspberry

1.4 - Login to the system with pi user
  ```
  user: pi
  password: raspberry
  ```

1.5 - Change the default password of pi user
  ```
  passwd
  ```

1.6 - Setup the basic configuration
  ```
  sudo raspi-config
  ```

1.7 - Optionally, configure a static IP in raspi-config

1.8 - Update the OS
  ```
  sudo apt-get update
  sudo apt-get upgrade
  sudo shutdown -r now
  ```


### Pi-hole Setup (optional)
<!--- --------------------------------------------------------------------- --->
2.1 - Links & Doc
  - https://pi-hole.net/
  - https://github.com/pi-hole/pi-hole
  - https://github.com/pi-hole/pi-hole/#one-step-automated-install

2.2 - Login to the system with pi user

2.3 - Install Pi-hole
  ```
  curl -sSL https://install.pi-hole.net | bash
  ```
  - Select "Install web admin interface"
  - Select "Install web server lighttpd"

2.4 - Configure Pi-hole admin password
  ```
  pihole -a -p PASSWORD
  ```

2.5 - Connect to web admin panel
  ```
  hostname -I
  ```
  or this one if have severals interfaces
  ```
  ip -o route get 1 | sed 's/^.*src \([^ ]*\).*$/\1/;q'
  ```
  
  - http://192.168.1.x/admin/
  - (*replace 192.168.1.x with your devices IP*)