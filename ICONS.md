# Hakpak Icons

This directory contains the icon files for Hakpak - Universal Kali Tools Installer for Debian-Based Systems.

## Icon Files

- `hakpak.svg` - Original vector icon (scalable)
- `hakpak-128.png` - 128x128 PNG (for applications, dock)
- `hakpak-64.png` - 64x64 PNG (standard desktop icon)
- `hakpak-48.png` - 48x48 PNG (toolbar, menu)
- `hakpak-32.png` - 32x32 PNG (small icons)
- `hakpak-16.png` - 16x16 PNG (favicon size)
- `hakpak.ico` - Windows favicon format
- `hakpak.desktop` - Desktop entry file for Linux

## Icon Design

The Hakpak icon features a clean, professional terminal window design:

- **Terminal Window**: Represents command-line interface and technical tools
- **Command Prompt**: Shows "$ hakpak" command with cursor
- **Modern Design**: Clean, minimalist aesthetic appealing to developers and security professionals
- **Monospace Font**: Technical typography consistent with terminal environments
- **Dark Theme**: Professional appearance suitable for cybersecurity applications
- **Scalable Vector**: Crisp appearance at all sizes from 16px to 128px+
- **Cross-Platform**: Universal design works across all Debian-based distributions

## Usage

### Installing Desktop Entry
To make Hakpak available in your applications menu:

```bash
# Copy to local applications
cp hakpak.desktop ~/.local/share/applications/

# Or install system-wide (requires sudo)
sudo cp hakpak.desktop /usr/share/applications/

# Update desktop database
update-desktop-database ~/.local/share/applications/
```

### Using Icons in Documentation
Reference the appropriate size icon for your use case:
- Documentation: Use `hakpak-64.png` or `hakpak.svg`
- Web favicon: Use `hakpak.ico` or `hakpak-16.png`
- Desktop applications: Use `hakpak-48.png` or `hakpak-64.png`

## License

These icons are part of the Kabuntool project by PhanesGuild Software LLC.
