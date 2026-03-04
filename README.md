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

**Behavior note:** UFW setup is automatic. Shared-folder symlink setup is now a separate script.

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

# Optional: set up shared folder symlink
chmod +x setup-waydroid-share.sh
./setup-waydroid-share.sh
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
