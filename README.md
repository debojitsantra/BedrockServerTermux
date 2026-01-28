# BedrockServerTermux

![License](https://img.shields.io/badge/license-GPL--3.0-blue.svg)
![Platform](https://img.shields.io/badge/platform-Android-green.svg)
![Termux](https://img.shields.io/badge/Termux-Required-orange.svg)

> Run a fully functional Minecraft Bedrock Dedicated Server on your Android device using Termux and Ubuntu (proot-distro)

## 📖 Table of Contents

- [Overview](#-overview)
- [Features](#-features)
- [Prerequisites](#-prerequisites)
- [Installation](#-installation)
  - [Step 1: Install Ubuntu in Termux](#step-1-install-ubuntu-in-termux)
  - [Step 2: Setup Environment & Minecraft Server](#step-2-setup-environment--minecraft-server)
  - [Step 3: Running the Server](#step-3-running-the-server)
  - [Step 4: Making Your Server Accessible](#step-4-making-your-server-accessible)
- [Server Management](#-server-management)
- [Updating Your Server](#-updating-your-server)
- [Configuration](#-configuration)
- [Troubleshooting](#-troubleshooting)
- [Performance Considerations](#-performance-considerations)
- [FAQ](#-faq)
- [Contributing](#-contributing)
- [License](#-license)
- [Acknowledgments](#-acknowledgments)

## 🎮 Overview

BedrockServerTermux allows you to host a Minecraft Bedrock Edition server directly on your Android device without requiring root access. This project leverages:

- **Termux**: A powerful terminal emulator for Android
- **proot-distro**: To run a full Ubuntu environment
- **Box64**: ARM64 to x86_64 translation layer for running the Bedrock server
- **Playit.gg**: Tunneling service to make your server accessible over the internet

## ✨ Features

- ✅ **No Root Required**: Works on any modern Android device
- ✅ **Automated Setup**: Simple installation scripts handle all dependencies
- ✅ **Full-Featured Server**: Supports all Minecraft Bedrock Edition features
- ✅ **Easy Updates**: One-command server updates
- ✅ **Internet Accessible**: Built-in tunneling support with Playit.gg
- ✅ **Free to Use**: No subscriptions or hosting fees

## 📋 Prerequisites

Before you begin, ensure you have:

- **Android Device**: 
  - Android 7.0 or higher
  - Minimum 2GB RAM (4GB+ recommended)
  - 2GB+ free storage space
  
- **Termux Application**:
  - ⚠️ **IMPORTANT**: Install Termux from [F-Droid](https://f-droid.org/packages/com.termux/), NOT from Google Play Store
  - Google Play Store version is outdated and incompatible
  
- **Internet Connection**: 
  - Stable connection required for installation and server hosting
  - WiFi recommended for best performance

- **Basic Knowledge**:
  - Familiarity with command-line interfaces helpful but not required
  - Ability to follow step-by-step instructions

## 🚀 Installation

### Step 1: Install Ubuntu in Termux

1. Open **Termux** and execute the following commands:

```bash
# Update Termux packages
apt update -y
apt upgrade -y

# Install wget
apt install wget -y

# Download and run Ubuntu setup script
wget https://raw.githubusercontent.com/debojitsantra/BedrockServerTermux/refs/heads/main/setup_ubuntu.sh
bash setup_ubuntu.sh
```

2. After installation completes, log in to Ubuntu:

```bash
proot-distro login ubuntu
```

> **Note**: You should now see a prompt starting with `root@localhost` indicating you're in the Ubuntu environment.

### Step 2: Setup Environment & Minecraft Server

1. Inside the Ubuntu session, run these commands:

```bash
# Update Ubuntu packages
apt update -y
apt upgrade -y

# Install wget
apt install wget -y

# Download and run environment setup script
wget https://raw.githubusercontent.com/debojitsantra/BedrockServerTermux/refs/heads/main/setup_env.sh
bash setup_env.sh
```

2. This script will automatically:
   - Install **Box64** (x86_64 emulation layer)
   - Install **Playit** (tunneling service)
   - Install **Git** and other dependencies
   - Download the latest Minecraft Bedrock Dedicated Server
   - Extract and configure server files

> ⏱️ **Estimated Time**: 5-10 minutes depending on your internet connection

### Step 3: Running the Server

You'll need **two separate Termux sessions** (windows/tabs) for this step.

#### Session 1: Minecraft Server

1. Open your first Termux session
2. Log in to Ubuntu:
```bash
proot-distro login ubuntu
```

3. Navigate to the root directory and start the server:
```bash
cd ~
./run
```

> The server will begin starting up. You should see server logs appearing.

#### Session 2: Playit Tunnel

1. Open a **second** Termux session (swipe from left edge → New Session)
2. Log in to Ubuntu:
```bash
proot-distro login ubuntu
```

3. Start the Playit tunneling service:
```bash
playit
```

### Step 4: Making Your Server Accessible

1. After running `playit`, you'll see a URL displayed in the terminal
2. Copy this URL and open it in your web browser
3. Follow the setup instructions on [playit.gg](https://playit.gg) to:
   - Create a free account (if you don't have one)
   - Claim your tunnel
   - Get your server's public address

4. Share the public address with friends to let them join your server!

## 🎛️ Server Management

### Starting the Server

```bash
# In Ubuntu environment
cd ~
./run
```

### Stopping the Server

In the server session, type:
```bash
stop
```

Or press `Ctrl + C` to force stop.

### Viewing Server Logs

Server logs are displayed in real-time in the session where you ran `./run`.

### Server Console Commands

While the server is running, you can use standard Bedrock server commands:
- `stop` - Gracefully stop the server
- `list` - List connected players
- `kick <player>` - Kick a player
- `ban <player>` - Ban a player
- `save` - Force save the world

Full command list: [Official Bedrock Server Commands](https://minecraft.wiki/w/Commands)

## 🔄 Updating Your Server

To update to the latest version of Minecraft Bedrock Server:

```bash
# Navigate to server directory
cd server

# Download update script
wget https://raw.githubusercontent.com/debojitsantra/BedrockServerTermux/refs/heads/main/update.sh

# Make it executable and run
chmod +x update.sh
./update.sh
```

> ⚠️ **Important**: Always backup your world data before updating!

## ⚙️ Configuration

### Server Properties

Edit server settings in `server.properties`:

```bash
cd ~/server
nano server.properties
```

Key settings to configure:
- `server-name` - Your server's display name
- `gamemode` - survival, creative, adventure
- `difficulty` - peaceful, easy, normal, hard
- `max-players` - Maximum number of players
- `view-distance` - Render distance (lower = better performance)
- `server-port` - Default is 19132

After editing, press `Ctrl + X`, then `Y`, then `Enter` to save.

### World Management

Your world data is stored in:
```
~/server/worlds/
```

To backup your world:
```bash
cd ~/server
tar -czf world_backup_$(date +%Y%m%d).tar.gz worlds/
```

## 🔧 Troubleshooting

### Common Issues

<details>
<summary><b>Server won't start / crashes immediately</b></summary>

**Solutions:**
- Ensure you're in the `/root` directory when running `./run`
- Check if you have enough free RAM (close other apps)
- Verify Box64 is installed: `box64 --version`
- Check server logs for specific error messages
</details>

<details>
<summary><b>Players can't connect to server</b></summary>

**Solutions:**
- Verify Playit is running in a separate session
- Check your Playit tunnel status at playit.gg
- Ensure server is running and shows "Server started" in logs
- Verify the correct port (usually 19132) is configured
- Make sure you're sharing the correct Playit address
</details>

<details>
<summary><b>Installation script fails</b></summary>

**Solutions:**
- Run `apt update` before retrying
- Check your internet connection
- Ensure you have enough storage space
- Try restarting Termux and starting over
- Make sure Termux is from F-Droid, not Play Store
</details>

<details>
<summary><b>Server is laggy / slow performance</b></summary>

**Solutions:**
- Reduce `view-distance` in `server.properties` (try 4-6)
- Reduce `max-players` to 2-5 players
- Close background apps to free up RAM
- Use a device with better specifications
- Reduce simulation distance in server settings
</details>

<details>
<summary><b>Termux keeps closing / server stops</b></summary>

**Solutions:**
- Acquire wakelock: `termux-wake-lock`
- Enable "Don't kill my app" settings for Termux
- Disable battery optimization for Termux
- Keep device plugged in while hosting
</details>

### Getting Help

If you encounter issues:

1. Check the [Troubleshooting](#troubleshooting) section
2. Search [existing issues](https://github.com/debojitsantra/BedrockServerTermux/issues)
3. Create a new issue with:
   - Your Android version
   - Device model and RAM
   - Complete error messages
   - Steps to reproduce the problem

## ⚡ Performance Considerations

### Expected Performance

- **Low-end devices** (2-3GB RAM): 1-2 players, view distance 4-6
- **Mid-range devices** (4-6GB RAM): 2-5 players, view distance 6-8
- **High-end devices** (8GB+ RAM): 5-10 players, view distance 8-10

### Optimization Tips

1. **Reduce render distance**: Lower values significantly improve performance
2. **Limit max players**: Fewer players = better performance
3. **Keep device cool**: Overheating causes throttling
4. **Close background apps**: Free up as much RAM as possible
5. **Use WiFi**: More stable than mobile data
6. **Keep device charged**: Low battery can reduce performance

### Box64 Translation Overhead

The server runs through Box64 (x86_64 → ARM64 translation), which adds some performance overhead. This is why:
- Server may use more CPU than native
- Some lag is expected compared to PC hosting
- Performance varies by device capabilities

## 💡 FAQ

**Q: Do I need root access?**  
A: No, this solution works without root privileges.

**Q: Can I run this 24/7?**  
A: Yes, but keep your device plugged in and ensure it doesn't overheat. Enable battery optimization exceptions for Termux.

**Q: Is my world data safe?**  
A: Regular backups are recommended. The server stores worlds in `~/server/worlds/`.

**Q: Can I use plugins/addons?**  
A: Yes, you can add behavior packs and resource packs to the server like any Bedrock server.

**Q: Does this work on tablets?**  
A: Yes, any ARM64 Android device can run this.

**Q: Can I play on the same device?**  
A: Yes, but performance will be significantly impacted. Use `localhost:19132` to connect.

**Q: How much data does hosting use?**  
A: Varies by player count and activity. Expect 50-200 MB per hour with active players.

**Q: Can I use a custom port?**  
A: Yes, modify `server-port` in `server.properties` and configure Playit accordingly.

## 🤝 Contributing

Contributions are welcome! Here's how you can help:

1. **Report bugs**: Open an issue with detailed information
2. **Suggest features**: Share your ideas in the issues section
3. **Improve documentation**: Submit PRs for documentation improvements
4. **Share your experience**: Help others in discussions

### Development

If you want to contribute code:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the GNU General Public License v3.0 - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **[Termux](https://termux.com/)** - Terminal emulator for Android
- **[proot-distro](https://github.com/termux/proot-distro)** - Termux package for managing Linux distributions
- **[Box64](https://github.com/ptitSeb/box64)** - x86_64 emulator for ARM64
- **[Playit.gg](https://playit.gg)** - Tunneling service for game servers
- **[Mojang/Microsoft](https://www.minecraft.net/)** - Minecraft Bedrock Dedicated Server
- All contributors and users who have helped improve this project

## 📞 Support & Community

- **Website**: [debojitsantra.vercel.app/BedrockServerTermux](https://debojitsantra.vercel.app/BedrockServerTermux)
- **GitHub Issues**: [Report bugs or request features](https://github.com/debojitsantra/BedrockServerTermux/issues)
- **Discussions**: Share your experience and help others

---

<div align="center">

**Made with ❤️ for the Minecraft community**

If you found this helpful, consider giving it a ⭐ on GitHub!

[Report Bug](https://github.com/debojitsantra/BedrockServerTermux/issues) • [Request Feature](https://github.com/debojitsantra/BedrockServerTermux/issues) • [Documentation](https://debojitsantra.vercel.app/BedrockServerTermux)

</div>
