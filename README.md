# Pi.NMS

Pi.NMS is a lightweight network management system for home labs, small offices,
and prosumer networks. It starts from the Pi.Alert foundation of local network
discovery and device presence tracking, then expands toward practical NMS
workflows: inventory, health checks, status, events, and actionable alerts.

This fork is in active transition. Some internal file names, database names, and
install paths still use the original `pialert` naming while compatibility and
migration work continues.

![Main screen][main]

## Current Capabilities

Pi.NMS currently scans the network for:

- New devices
- New connections and reconnections
- Disconnections
- Always-connected devices going down
- Device IP changes
- Internet IP address changes

## Direction

The near-term goal is to evolve from a network presence detector into a small
network NMS with:

- Device inventory and ownership metadata
- Availability checks such as ICMP, TCP, HTTP, and DNS
- Node status states such as up, down, warning, unknown, and maintenance
- Event history and incident views
- Notification rules by severity, device group, or check type
- Simple topology and subnet views

## Scan Methods

Up to three scanning methods are used:

- **Method 1: arp-scan**. The `arp-scan` system utility searches for devices on
  the network using ARP frames.
- **Method 2: Pi-hole**. If the Pi-hole DNS server is active, Pi.NMS examines
  its activity looking for active devices using DNS that were not detected by
  method 1.
- **Method 3: dnsmasq**. If the dnsmasq DHCP server is active, Pi.NMS examines
  DHCP leases to find active devices that were not discovered by the other
  methods.

## Components

### Back End

The back end:

- Scans the network using the configured scan methods
- Stores device, event, and presence information in SQLite
- Sends reports by email when configured

| ![Report 1][report1] | ![Report 2][report2] |
| -------------------- | -------------------- |

### Front End

The web UI allows you to:

- Manage the device inventory
- Review sessions, events, presence, and down alerts
- Inspect connected, favorite, and unknown devices
- Track IP addresses and recent network changes

| ![Screen 1][screen1] | ![Screen 2][screen2] |
| -------------------- | -------------------- |
| ![Screen 3][screen3] | ![Screen 4][screen4] |

## Installation

Pi.NMS is currently designed around the original Raspberry Pi-oriented install
flow. Manual installation is recommended while the fork is being renamed and
packaged.

- [Installation Guide](docs/INSTALL.md)
- [Uninstall Guide](docs/UNINSTALL.md)
- [Device Management](docs/DEVICE_MANAGEMENT.md)

## Project Status

This repository is a fork of the original Pi.Alert project. The first cleanup
phase focuses on project identity, documentation, and visible UI naming. Later
phases should handle internal package names, install paths, service names, and
database migrations.

## Powered By

| Product      | Purpose                                |
| ------------ | -------------------------------------- |
| Python       | Back-end scanning and reporting        |
| PHP          | Web front end                          |
| JavaScript   | Front-end behavior                     |
| Bootstrap    | Front-end framework                    |
| AdminLTE     | Admin dashboard template               |
| FullCalendar | Calendar component                     |
| SQLite       | Database engine                        |
| Lighttpd     | Web server                             |
| arp-scan     | Network scanning with ARP              |
| Pi-hole      | Optional DNS activity source           |
| dnsmasq      | Optional DHCP lease source             |

## License

GPL 3.0. See [LICENSE.txt](LICENSE.txt).

## Attribution

Pi.NMS is based on the original Pi.Alert project by Puche.

[main]:    ./docs/img/1_devices.jpg           "Main screen"
[screen1]: ./docs/img/2_1_device_details.jpg  "Screen 1"
[screen2]: ./docs/img/2_2_device_sessions.jpg "Screen 2"
[screen3]: ./docs/img/2_3_device_presence.jpg "Screen 3"
[screen4]: ./docs/img/3_presence.jpg          "Screen 4"
[report1]: ./docs/img/4_report_1.jpg          "Report sample 1"
[report2]: ./docs/img/4_report_2.jpg          "Report sample 2"