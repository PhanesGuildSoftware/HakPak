# Vendor Tools Setup

Some tools require vendor installers or EULAs and are not fully automated by HakPak2. This guide shows safe, repeatable ways to install them on Ubuntu 24.04 and similar.

Important: Review licenses and obtain authorization before installing or using these tools.

## Burp Suite

- Native (Kali repository):
  - Ensure Kali repo is configured: `sudo hakpak2 repo add`
  - Install: `sudo apt update && sudo apt install burpsuite`
  - Launch: `burpsuite`
  - Notes: Requires Java (OpenJDK is fine). If missing: `sudo apt install openjdk-17-jre`

- Vendor installer (PortSwigger):
  - Download Community/Professional from <https://portswigger.net/burp/releases>
  - For `.sh` installer: `chmod +x burpsuite_*.sh && sudo ./burpsuite_*.sh`
  - For `.jar`: `sudo apt install openjdk-17-jre && java -jar burpsuite_*.jar`
  - Optional desktop entry: The installer usually adds one. If not, create `/usr/share/applications/burpsuite.desktop` pointing to your install.

## Maltego

- Vendor installer (recommended):
  - Download from <https://www.maltego.com/downloads/>
  - Choose `.deb` for Debian/Ubuntu or AppImage
  - For `.deb`:
    - `sudo apt install -y openjdk-17-jre`
    - `sudo dpkg -i maltego*.deb || sudo apt -f install -y`
    - Launch: `maltego`
  - For AppImage:
    - `chmod +x Maltego*.AppImage && ./Maltego*.AppImage`
  - First run requires account sign-in and acceptance of license terms.

## Nessus

- Vendor installer (Tenable):
  - Download from <https://www.tenable.com/products/nessus/select-your-operating-system> (select Ubuntu 24.04 .deb)
  - Install: `sudo dpkg -i Nessus-*-ubuntu*.deb || sudo apt -f install -y`
  - Enable and start: `sudo systemctl enable --now nessusd`
  - Open UI: <https://localhost:8834/> and complete setup (activation code required)
  - Manage service: `sudo systemctl status nessusd` | `sudo systemctl stop nessusd`

## Troubleshooting

- Java missing: `sudo apt install openjdk-17-jre`
- Missing libraries for `.deb`: run `sudo apt -f install -y` to fix dependencies
- Desktop entries missing: create a `.desktop` file under `/usr/share/applications` or `~/.local/share/applications`

## Uninstall

- Burp (Kali): `sudo apt remove burpsuite`
- Maltego: `sudo apt remove maltego` (if installed from .deb) or delete AppImage
- Nessus: `sudo dpkg -r nessus && sudo rm -rf /opt/nessus`
