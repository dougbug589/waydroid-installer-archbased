# waydroid-installer-archbased

This repo provides a simple script for basic Waydroid setup and maintenance.

## What the script does

### If Waydroid is already installed
- Prompts you to choose:
  - Fully remove Waydroid
  - Modify existing setup using waydroid_script
  - Exit

### If Waydroid is not installed
- Checks kernel compatibility
- Installs and initializes Waydroid images
- Installs/updates and launches waydroid_script so you can choose modifications
- Installs UFW (if missing), enables it, and applies required Waydroid ports/rules
- Creates a safe launcher that auto-runs `waydroid session stop` before start and when closing

**Behavior note:** UFW setup is automatic. Shared-folder symlink setup is manual.

## Requirements
- Arch-based Linux
- Wayland session
- Internet connection

## Quick Start

Clone and run:

```bash
git clone https://github.com/dougbug589/waydroid-installer-archbased.git
cd waydroid-installer-archbased
chmod +x install-waydroid.sh
./install-waydroid.sh
```

## Manual shared-folder symlink setup

Run these steps manually after Waydroid is installed.

1) Check Waydroid media folder ownership and current groups:

```bash
ls -ld ~/.local/share/waydroid/data/media
groups
```

2) Add your user to the group with GID `1023` (Waydroid media group):

```bash
# If GID 1023 already exists, use its group name:
getent group 1023
sudo usermod -aG <groupname> "$USER"

# If GID 1023 does not exist yet:
sudo groupadd -g 1023 waydroid
sudo usermod -aG waydroid "$USER"
```

3) Re-login (or reboot), then verify:

```bash
groups
```

4) Create symlink(s) to Waydroid folders:

```bash
# Example 1: dedicated shared folder
mkdir -p ~/.local/share/waydroid/data/media/0/Waydroid
ln -s ~/.local/share/waydroid/data/media/0/Waydroid ~/Waydroid

# Example 2: direct link to Download
ln -s ~/.local/share/waydroid/data/media/0/Download ~/WaydroidDownload
```

## Kernel compatibility

If your kernel is not supported, the script exits and lists compatible kernels only:
- linux-zen
- linux-cachyos
- linux-xanmod
- linux-lts
- linux-hardened
- linux-clear

## Notes
- Run the script as a normal user (not root).
- The script uses sudo when needed.
- waydroid_script source: https://github.com/casualsnek/waydroid_script
- Use `Waydroid (Safe)` from your app menu, or run `~/.local/bin/waydroid-safe-launcher`.

## License

MIT (see LICENSE)
