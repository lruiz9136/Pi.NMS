# Pi.NMS Installation Guide
<!--- --------------------------------------------------------------------- --->
Initially designed to run on a Raspberry PI, probably it can run on many other
Linux distributions.

Estimated time: 20'

### Dependencies
  | Dependency | Comments                                                 |
  | ---------- | -------------------------------------------------------- |
  | Lighttpd   | Installed and configured directly by Pi.NMS              |
  | arp-scan   | Required for Scan Method 1                               |
  | dnsmasq    | Optional. Enrich discovery from a standard lease file    |
  | IEEE HW DB | Necessary to identified Device vendor                    |

## One-step Automated Install:
<!--- --------------------------------------------------------------------- --->
  #### `curl -sSL https://github.com/lruiz9136/Pi.NMS/raw/main/install/pialert_install.sh | bash`

## One-step Automated Update:
<!--- --------------------------------------------------------------------- --->
  #### `curl -sSL https://github.com/lruiz9136/Pi.NMS/raw/main/install/pinms_update.sh | bash`

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


### Connect to Pi.NMS
<!--- --------------------------------------------------------------------- --->
After installation, find the host address:

  ```
  hostname -I
  ```
  Or, on hosts with several interfaces:
  ```
  ip -o route get 1 | sed 's/^.*src \([^ ]*\).*$/\1/;q'
  ```
Open `http://192.168.1.x/pialert/`, replacing the example address with the
Pi.NMS host address. Pi.NMS installs its own web dependencies and does not
require an external DNS or DHCP product.

To enable optional dnsmasq lease enrichment, set `DHCP_ACTIVE = True` and
`DHCP_LEASES` to the lease file path in `config/pialert.conf`. The default path
is `/var/lib/misc/dnsmasq.leases`.
