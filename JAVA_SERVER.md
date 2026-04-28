# Minecraft Java Edition Server for Termux

Run a **Minecraft Java Edition server** directly in Termux — no root, no proot, no Box64 needed.

Works on **both 32-bit and 64-bit ARM** Android devices.

> Looking for the Bedrock server instead? [Back to main guide](../README.md)

---

- **Java clients** connect on port `25565`
- **Bedrock / PE clients** connect on port `19132` via Geyser

---

## Requirements

- Android 7.0 or higher
- Any ARM device : 32-bit or 64-bit
- Minimum 1.5 GB free RAM
- [Termux from F-Droid](https://f-droid.org/packages/com.termux/)

---

## Installation

Open Termux and run:

```bash
wget https://raw.githubusercontent.com/debojitsantra/BedrockServerTermux/main/setup_java.sh
bash setup_java.sh
```


---

## Usage


**Session 1 — Start the server:**
```bash
~/run
```

**Session 2 — Start the tunnel:**
```bash
playit
```

After running `playit`, open the URL it shows in a browser, create a free Playit account, claim your tunnel, and share the address with players.

**Stop the server** — type in the server console:
```
stop
```

---

## Connecting

| Client | Port |
|---|---|
| Java Edition | `25565` |
| Bedrock / PE / Console | `19132` |

To find your local IP:
```bash
ifconfig | grep inet
```

---

## FAQ

**Does this work on 32-bit devices?**
- Yes. Java runs on the JVM so no architecture translation is needed, unlike the Bedrock server which requires Box64 and a 64-bit device.

**Can Bedrock/PE players join?**
- Yes. Geyser is included and handles the translation automatically on port `19132`.

**How do I give players more RAM?**
- Edit `~/server/start.sh` and change `-Xmx512M` to a higher value like `-Xmx1024M`.

**Where are my world files?**
```
 ~/server/world/
```

**I see warnings about JNA/OSHI on startup - is that normal?**
- Yes, these are harmless. They appear because Termux uses Android's Bionic libc instead of standard GNU libc. They are filtered out automatically and have no effect on gameplay.
