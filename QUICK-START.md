# 🚀 HakPak Quick Start Guide

## Windows-Style Installation Process

### Step 1: Download
Download the HakPak package from the website and save it to your Downloads folder.

### Step 2: Extract  
Right-click the downloaded ZIP file and select "Extract Here" or "Extract All".

### Step 3: Open Terminal (or File Manager)
You can install HakPak in two ways:

#### Option A: File Manager (Easiest)
1. Open the extracted HakPak folder in your file manager
2. Right-click on `install.sh` 
3. Select "Open in Terminal" or "Run in Terminal"
4. Choose option 1 for Desktop Application

#### Option B: Terminal
```bash
cd Downloads/HakPak  # (or wherever you extracted it)
./install.sh
```

### Step 4: Choose Installation Type
The installer will show you 3 options:

1. **🖥️ Desktop Application (Recommended)** - Complete desktop experience
2. **💻 Command Line Only** - Terminal-only for servers  
3. **📦 Portable Mode** - Run without installing

**Choose option 1** for the full Windows-like experience.

### Step 5: Enter Your Password
When prompted, enter **YOUR** password (the same one you use to log into your computer). This is NOT a developer password - it's your own system password.

### Step 6: Launch HakPak
After installation, you can launch HakPak in several ways:

#### Desktop Icon
- Look for the HakPak icon on your desktop
- Double-click to launch

#### Application Menu
- Click the applications/activities button
- Search for "HakPak"
- Click to launch

#### Terminal
```bash
hakpak
```

## What Happens During Installation

The installer will:
1. ✅ Check your system compatibility
2. ✅ Verify all required files are present  
3. ✅ Install HakPak to system directories
4. ✅ Create desktop shortcut with icon
5. ✅ Add HakPak to your application menu
6. ✅ Set up secure authentication
7. ✅ Generate proper app icons

## After Installation

### Desktop Experience
- **Desktop Shortcut**: HakPak icon appears on your desktop
- **App Menu**: Available in System Tools/Administration
- **Search**: Type "HakPak" in your launcher
- **Right-Click**: Quick actions menu on desktop icon

### First Launch
1. Double-click the HakPak desktop icon
2. Enter your password when prompted
3. Choose what you want to install:
   - Kali Top 10 Tools (most popular)
   - Web Security Tools
   - Individual tools
   - Or browse all options

## Troubleshooting

### "Permission denied" error?
Make sure you're NOT running as root:
```bash
# Check your user (should NOT be root)
whoami

# Run installer as regular user
./install.sh  # NOT sudo ./install.sh
```

### Desktop icon not appearing?
Try refreshing your desktop:
```bash
# GNOME/Ubuntu
killall nautilus

# Or just log out and back in
```

### Can't find HakPak in menu?
The app should appear under:
- System Tools
- Administration  
- Security

Or just search for "HakPak" in your application launcher.

### Authentication not working?
HakPak uses YOUR system password. If you can't sudo normally, HakPak won't work either:
```bash
# Test if sudo works
sudo echo "test"
```

## Need Help?

1. **Check the logs**: `/var/log/hakpak.log`
2. **Test basic functionality**: `hakpak --help`
3. **System status**: `hakpak --status`
4. **Fix dependencies**: `sudo hakpak --fix-deps`

---

**Ready to forge your security toolkit! 🛡️⚒️**
