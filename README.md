# BedrockServerTermux

![BedrockServerTermux](https://socialify.git.ci/debojitsantra/BedrockServerTermux/image?font=Jost&language=1&logo=https%3A%2F%2Fdebojitsantra.vercel.app%2Fimages%2Fbedrock-logo.svg&name=1&pattern=Brick+Wall&stargazers=1&theme=Auto)

![License](https://img.shields.io/badge/license-GPL--3.0-blue.svg)
![Platform](https://img.shields.io/badge/platform-Android-green.svg)
![Termux](https://img.shields.io/badge/Termux-Required-orange.svg)
![Maintained](https://img.shields.io/badge/maintained-yes-green.svg)

Run a Minecraft Bedrock Dedicated Server on your Android device using Termux and Debian (proot-distro).

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Running the Server](#running-the-server)
- [Making Your Server Accessible](#making-your-server-accessible)
- [Server Management](#server-management)
- [Updating Your Server](#updating-your-server)
- [Accessing Files](#accessing-files)
- [Installing Add-ons](#installing-add-ons)
- [Configuration](#configuration)
- [Troubleshooting](#troubleshooting)
- [Performance](#performance)
- [FAQ](#faq)
- [Contributing](#contributing)
- [License](#license)
- [Acknowledgments](#acknowledgments)

## Overview

BedrockServerTermux hosts a Minecraft Bedrock Edition server on Android without root access using:

- **Termux** — terminal emulator for Android
- **proot-distro** — runs a full Debian environment
- **Box64** — ARM64 to x86_64 translation layer
- **Playit.gg** — tunneling service for internet access

## Features

- No root required
- Simple installation scripts
- Version selection — latest stable, preview, or any specific version
- Multiple server instances in separate folders
- One-command updates with automatic world backup
- Built-in tunneling via Playit.gg

## Prerequisites

- Android 7.0 or higher
- Minimum 2GB RAM (4GB+ recommended)
- 2GB+ free storage
- Termux from [F-Droid](https://f-droid.org/packages/com.termux/) — the Play Store version is outdated
- Stable internet connection

## Installation

### Step 1: Set up Debian in Termux

Open Termux and run:

```bash
apt update -y && apt upgrade -y
apt install wget -y
wget https://raw.githubusercontent.com/debojitsantra/BedrockServerTermux/refs/heads/main/setup_proot.sh
bash setup_proot.sh
```

After it finishes, log in to Debian:

```bash
pdd
```
or
```bash
proot-distro login debian
```


### Step 2: Set up the server environment

Inside the Debian session:

```bash
apt update -y && apt upgrade -y
apt install wget -y
wget https://raw.githubusercontent.com/debojitsantra/BedrockServerTermux/refs/heads/main/setup_env.sh
bash setup_env.sh
```

The script will ask you to choose a version and install folder, then handle everything automatically — Box64, Playit, server download, and extraction.

Estimated time: 5–10 minutes depending on your connection.

## Running the Server

You need two separate Termux sessions.

**Session 1 — server:**

```bash
pdd
```
```bash
cd ~
./run
```

If you have multiple server folders installed, `run` will list them and let you choose which one to start.

**Session 2 — tunnel:**

```bash
pdd
```
```bash
playit
```

## Making Your Server Accessible

After running `playit`, open the displayed URL in a browser, create a free Playit account, claim your tunnel, and share the public address with players.

## Server Management

**Stop the server:**

Type `stop` in the server session, or press `Ctrl+C`.

**Available console commands:**

- `stop` — gracefully stop the server
- `list` — list connected players
- `kick <player>` — kick a player
- `ban <player>` — ban a player
- `save` — force save the world

Full command reference: [Minecraft Wiki — Commands](https://minecraft.wiki/w/Commands)

## Updating Your Server

```bash
cd ~
./update.sh
```

The update script lets you choose the version and target folder, backs up your worlds automatically, then downloads and extracts the new server files.

## Accessing Files

Debian files are at:

```
/data/data/com.termux/files/usr/var/lib/proot-distro/installed-rootfs/debian
```

To browse them from a file manager, create a symlink:

```bash
ln -s $PREFIX/var/lib/proot-distro/installed-rootfs/debian ~/debian
```

Then navigate to:
```
/storage/emulated/0/Android/data/com.termux/files/home/debian
```

Requires a file manager with Storage Access Framework support (Material Files, Solid Explorer, MiXplorer).

## Installing Add-ons

Bedrock uses behavior packs and resource packs. Java mods (.jar) are not supported.

**Step 1: Extract the pack**

Rename `.mcpack` to `.zip` and extract it. The extracted folder must contain `manifest.json` at the root level.

**Step 2: Place packs in server folders**

```
server/
├── behavior_packs/
│   └── MyAddon_BP/
│       └── manifest.json
├── resource_packs/
│   └── MyAddon_RP/
│       └── manifest.json
```

Do not add extra subfolder levels.

**Step 3: Find your world name**

```bash
grep level-name ~/server/server.properties
```

**Step 4: Enable the behavior pack**

```bash
nano ~/server/worlds/<level-name>/world_behavior_packs.json
```

```json
[
  {
    "pack_id": "UUID-FROM-BP-manifest",
    "version": [1, 0, 0]
  }
]
```

**Step 5: Enable the resource pack**

```bash
nano ~/server/worlds/<level-name>/world_resource_packs.json
```

```json
[
  {
    "pack_id": "UUID-FROM-RP-manifest",
    "version": [1, 0, 0]
  }
]
```

The BP and RP UUIDs are different — copy each from their respective `manifest.json`.

**Step 6: Enable experimental features if required**

Add to `server.properties`:

```
experimental-gameplay=true
```

**Step 7: Restart the server**

```bash
stop
./run
```

If the pack loaded correctly you'll see `Pack Stack - <AddonName>` in the logs. `Pack Stack - None` means wrong UUID or missing folder.

## Configuration

Edit server settings:

```bash
nano ~/server/server.properties
```

Key options:

| Option | Description |
|--------|-------------|
| `server-name` | Server display name |
| `gamemode` | survival, creative, adventure |
| `difficulty` | peaceful, easy, normal, hard |
| `max-players` | Player limit |
| `view-distance` | Render distance |
| `server-port` | Default 19132 |

Save with `Ctrl+X`, `Y`, `Enter`.

**Manual world backup:**

```bash
cd ~/server
tar -czf world_backup_$(date +%Y%m%d).tar.gz worlds/
```

## Troubleshooting

**Server crashes immediately**

- Make sure you're running `./run` from `~`
- Check available RAM (close background apps)
- Verify Box64 is installed: `box64 --version`
- If running an older specific version, it may be incompatible with Box64 on ARM — use latest stable instead

**Players can't connect**

- Verify Playit is running in a separate session
- Check tunnel status at playit.gg
- Confirm the server shows "Server started" in logs
- Make sure you're sharing the correct Playit address

**Installation fails**

- Run `apt update` before retrying
- Check internet connection and storage space
- Restart Termux and try again
- Confirm Termux is from F-Droid

**Server is slow or laggy**

- Lower `view-distance` to 4–6 in `server.properties`
- Lower `max-players`
- Close background apps
- Reduce `max-threads` according to your device(try 5-6)
- Keep device plugged in

**Termux closes unexpectedly**

- Run `termux-wake-lock` in Termux
- Disable battery optimization for Termux
- Enable "Don't kill my app" for Termux in device settings

If the issue isn't listed here, [search existing issues](https://github.com/debojitsantra/BedrockServerTermux/issues) or open a new one with your Android version, device model, RAM, and the full error output.

## Performance

| RAM | Players | View distance |
|-----|---------|---------------|
| 2–3GB | 1–2 | 4–6 |
| 4–6GB | 2–5 | 6–8 |
| 8GB+ | 5–10 | 8–10 |

The server runs through Box64 (x86_64 → ARM64 translation), so CPU usage will be higher than native and some lag is expected compared to PC hosting.

## FAQ

**Do I need root?**
No.

**Can I run multiple server versions?**
Yes. The setup and update scripts let you install each version into a separate folder. `./run` lists all available servers at startup.

**Is my world data safe during updates?**
The update script backs up your worlds before extracting new files.

**Can I run this 24/7?**
Yes, keep the device plugged in, disable battery optimization for Termux, and use `termux-wake-lock`.

**Can I use plugins?**
Behavior packs and resource packs are supported. Java plugins (Bukkit/Spigot) are not.

**Can I play on the same device?**
Yes, connect using `localhost:19132`, but performance will be affected.

**Does this work on tablets?**
Yes, any ARM64 Android device works.

**How much data does hosting use?**
Roughly 50–200 MB per hour with active players.

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature`
3. Commit your changes: `git commit -m 'Add your feature'`
4. Push to the branch: `git push origin feature/your-feature`
5. Open a pull request

Bug reports and documentation improvements are also welcome.

## License

GPL-3.0 — see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [Termux](https://termux.com/)
- [proot-distro](https://github.com/termux/proot-distro)
- [Box64](https://github.com/ptitSeb/box64)
- [Playit.gg](https://playit.gg)
- [Mojang/Microsoft](https://www.minecraft.net/)

---

<div align="center">

[Report Bug](https://github.com/debojitsantra/BedrockServerTermux/issues) · [Request Feature](https://github.com/debojitsantra/BedrockServerTermux/issues) · [Documentation](https://debojitsantra.vercel.app/BedrockServerTermux)

</div>
