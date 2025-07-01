# Linux Spotlight Wallpaper

🖼️ **Bring Windows 11 Spotlight wallpapers to your Linux desktop!**

A lightweight script that automatically downloads and rotates beautiful landscape wallpapers, mimicking the Windows 11 Spotlight feature for Linux systems. Perfect for minimalist window managers like dwm, i3, bspwm, and others.

![Demo](https://img.shields.io/badge/Status-Active-brightgreen) ![License](https://img.shields.io/badge/License-MIT-blue) ![Shell](https://img.shields.io/badge/Shell-Bash-green)

## ✨ Features

- 🎨 **High-quality landscape wallpapers** from curated sources (Unsplash, Picsum)
- ⏰ **Automatic rotation** every 30 minutes (customizable)
- 🔄 **Smart fallback system** - uses existing wallpapers if downloads fail
- 🧹 **Automatic cleanup** - manages storage by keeping only recent wallpapers
- 📝 **Comprehensive logging** for troubleshooting
- 🎯 **Manual controls** for immediate wallpaper changes
- 🪶 **Lightweight** - minimal resource usage
- 🔧 **Easy integration** with any window manager using feh

## 🖥️ Compatibility

- **Display**: Any X11-based Linux desktop
- **Tested on**: Arch Linux (should work on any Linux distribution)

## 📋 Prerequisites

Install required packages:

### Arch Linux
```bash
sudo pacman -S feh curl jq
```

### Ubuntu/Debian
```bash
sudo apt install feh curl jq
```

### Fedora
```bash
sudo dnf install feh curl jq
```

## 🚀 Installation

1. **Clone the repository:**
```bash
git clone https://github.com/AhmedElazony/linux-spotlight-wallpaper.git
cd linux-spotlight-wallpaper
```

2. **Install the script:**
```bash
mkdir -p ~/.local/bin
cp spotlight-wallpaper.sh ~/.local/bin/
chmod +x ~/.local/bin/spotlight-wallpaper.sh
```

3. Get Unsplash API key** (recommended for better quality):
   - Visit [Unsplash Developers](https://unsplash.com/developers)
   - Create a free account and app
   - Add your API key to your shell profile:
```bash
echo 'export UNSPLASH_ACCESS_KEY="your_api_key_here"' >> ~/.bashrc # or .zshrc or you are using zsh.
source ~/.bashrc # or .zshrc
```

## ⚙️ Setup Automatic Rotation

### Using systemd (Recommended)

1. **Create service file:**
```bash
mkdir -p ~/.config/systemd/user

cat > ~/.config/systemd/user/spotlight-wallpaper.service << 'EOF'
[Unit]
Description=Spotlight Wallpaper Changer
After=graphical-session.target

[Service]
Type=oneshot
Environment=DISPLAY=:0
Environment=UNSPLASH_ACCESS_KEY=your_api_key
ExecStart=%h/.local/bin/spotlight-wallpaper.sh
StandardOutput=journal
StandardError=journal
EOF
```

2. **Create timer file:**
```bash
cat > ~/.config/systemd/user/spotlight-wallpaper.timer << 'EOF'
[Unit]
Description=Run Spotlight Wallpaper Changer every 30 minutes
Requires=spotlight-wallpaper.service

[Timer]
OnBootSec=2min
OnUnitActiveSec=30min
Persistent=true

[Install]
WantedBy=timers.target
EOF
```

3. **Enable and start:**
```bash
systemctl --user daemon-reload
systemctl --user enable spotlight-wallpaper.timer
systemctl --user start spotlight-wallpaper.timer
```

4. **Initialize:**
```bash
~/.local/bin/spotlight-wallpaper.sh init
```

### Using cron (Alternative)

```bash
# Add to crontab
crontab -e

# Add this line for 30-minute intervals
*/30 * * * * DISPLAY=:0 ~/.local/bin/spotlight-wallpaper.sh
```

## 📖 Usage

### Manual Commands

```bash
# Initialize and set first wallpaper
spotlight-wallpaper.sh init

# Get next wallpaper immediately
spotlight-wallpaper.sh next

# Check current status
spotlight-wallpaper.sh status

# Regular update (used by timer)
spotlight-wallpaper.sh
```

### System Management

```bash
# Check timer status
systemctl --user status spotlight-wallpaper.timer

# View logs
journalctl --user -u spotlight-wallpaper.service -f

# Stop/start timer
systemctl --user stop spotlight-wallpaper.timer
systemctl --user start spotlight-wallpaper.timer

# List active timers
systemctl --user list-timers
```

## 🔧 Integration

### dwm Integration

Add to your `.xinitrc`:
```bash
# Restore wallpaper on startup
if [ -f "$HOME/.local/share/wallpapers/current_wallpaper" ]; then
    feh --bg-fill "$(cat "$HOME/.local/share/wallpapers/current_wallpaper")"
fi
```

### Other Window Managers

The script works with any window manager that can use feh for wallpapers:
- **i3/sway**: Add restore command to config
- **bspwm**: Add to bspwmrc
- **awesome**: Call feh from rc.lua
- **openbox**: Add to autostart

## ⚙️ Configuration

Edit the script variables to customize behavior:

```bash
# Wallpaper storage location
WALLPAPER_DIR="$HOME/.local/share/wallpapers/spotlight"

# Maximum wallpapers to keep
MAX_WALLPAPERS=50

# Log file location
LOG_FILE="$HOME/.local/share/wallpapers/spotlight.log"
```

### Changing Update Interval

**For systemd timer:**
```bash
# Edit timer file
nano ~/.config/systemd/user/spotlight-wallpaper.timer

# Change this line:
OnUnitActiveSec=30min  # Change to 15min, 1h, etc.

# Reload
systemctl --user daemon-reload
systemctl --user restart spotlight-wallpaper.timer
```

**For cron:**
```bash
# Edit crontab
crontab -e

# Examples:
*/15 * * * *  # Every 15 minutes
0 * * * *     # Every hour
0 */2 * * *   # Every 2 hours
```

## 📁 File Structure

```
~/.local/
├── bin/
│   └── spotlight-wallpaper.sh          # Main script
└── share/
    └── wallpapers/
        ├── spotlight/                   # Downloaded wallpapers
        │   ├── spotlight_abc123.jpg
        │   └── spotlight_xyz789.jpg
        ├── current_wallpaper           # Path to current wallpaper
        └── spotlight.log              # Application logs
```

## 🔍 Troubleshooting

### Common Issues

**Script not running:**
```bash
# Check if timer is active
systemctl --user list-timers spotlight-wallpaper.timer

# Check service status
systemctl --user status spotlight-wallpaper.service
```

**No wallpaper changes:**
```bash
# Check logs
journalctl --user -u spotlight-wallpaper.service -n 20

# Test manually
spotlight-wallpaper.sh next
```

**Permission issues:**
```bash
# Make script executable
chmod +x ~/.local/bin/spotlight-wallpaper.sh

# Check file permissions
ls -la ~/.local/bin/spotlight-wallpaper.sh
```

**X11 display issues:**
```bash
# Check DISPLAY variable
echo $DISPLAY

# Test feh manually
feh --bg-fill /path/to/image.jpg
```

### Reset Everything

```bash
# Stop timer
systemctl --user stop spotlight-wallpaper.timer

# Clear wallpapers
rm -rf ~/.local/share/wallpapers/spotlight/*

# Restart
spotlight-wallpaper.sh init
systemctl --user start spotlight-wallpaper.timer
```

## 📊 API Sources

The script uses these image sources:

1. **Unsplash API** (requires free API key)
   - High-quality curated photos
   - Professional photography
   - Rate limit: 1000 requests/hour

2. **Picsum (Lorem Picsum)** (fallback)
   - No API key required
   - Random high-quality images
   - Unlimited requests

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

--

⭐ **Star this repo if you find it useful!** ⭐

Made with ❤️ for the Linux community
