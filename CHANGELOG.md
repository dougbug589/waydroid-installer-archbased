# Changelog

All notable changes and fixes to the Waydroid installation script.

## [2026-03-04] - Installer Simplification, Session Stability, and Repo Rename

### Changed
- **Simplified installer flow to core basics only**
  - Existing install path now offers:
    1. Fully remove Waydroid
    2. Modify existing setup with `waydroid_script`
    3. Exit
  - Fresh install path now focuses on: kernel check, install/init, `waydroid_script`, UFW, and symlink sharing

- **Added fresh-install confirmation prompt**
  - When no install is detected, script now asks:
    - `Do you want to install Waydroid now? (y/N)`
  - Prevents accidental installation runs

- **Kernel compatibility failure output simplified**
  - On unsupported kernels, script exits and lists compatible kernels only

### Added
- **Safe launcher to reduce reopen/loop issues**
  - Creates `~/.local/bin/waydroid-safe-launcher`
  - Creates desktop entry: `Waydroid (Safe)`
  - Launcher behavior:
    - Runs `waydroid session stop` before launch
    - Starts a clean session and opens full UI
    - Runs `waydroid session stop` automatically on exit via trap

- **Automatic UFW installation and configuration**
  - If UFW is missing, script installs it automatically
  - Enables UFW service and applies required rules:
    - allow port 53
    - allow port 67
    - `ufw default allow FORWARD`

- **Symlink setup bootstrap for storage path creation**
  - If Waydroid media path is missing, script starts a session once to initialize storage, waits briefly, then stops session and continues symlink setup

### Documentation
- **README reduced to a concise basics-only guide**
  - Removed long advanced/manual sections from top-level docs
  - Updated script behavior documentation to match current flow
  - Added safe launcher usage notes
  - Updated clone instructions for renamed repository

### Repository
- **Repository renamed**
  - From: `waydroid-guide-cachyos-arch`
  - To: `waydroid-installer-archbased`
  - Local `origin` remote updated accordingly

## [2026-01-17] - File Sharing Method Update

### Changed
- **Replaced bind mount with symlink method for file sharing**
  - Automated script now uses safer symlink approach
  - Creates single `~/Waydroid` folder instead of linking to existing Android folders
  - No longer touches user's Downloads, Pictures, Documents, or DCIM
  - Symlinks new dedicated folder: `~/Waydroid` ↔ `Internal storage/Waydroid`
  - No fstab configuration needed
  - No mounting or restart required
  - Instant file transfer between Linux and Android
  - Based on community solution from [waydroid/waydroid#2150](https://github.com/waydroid/waydroid/discussions/2150)

### Documentation
- **Consolidated all documentation into README.md**
  - Removed separate SHARED_FOLDER_GUIDE.md
  - All file sharing instructions now in README
  - Manual section shows both symlink (recommended) and bind mount methods
  - Single comprehensive documentation file

### Security
- **Improved safety of automated file sharing setup**
  - No longer creates symlinks to existing Android system folders
  - Creates dedicated new folder for sharing
  - Follows better security practices
  - Safer for user data

---

## [2026-01-13] - Major Improvements & Bug Fixes

### Added Features

#### 1. **Kernel Compatibility Detection**
- Added automatic kernel detection and validation
- Supports: `linux-zen`, `linux-cachyos`, `linux-xanmod`, `linux-lts`, `linux-hardened`, `linux-clear`
- Fallback check for binder module support (`CONFIG_ANDROID=y` or `binder_linux-dkms`)
- Exits with clear instructions if unsupported kernel detected
- Prevents installation on incompatible systems

#### 2. **Fresh Install vs Re-configuration Detection**
- Detects existing Waydroid installations automatically
- Checks for: package installation, data/images, enabled services
- Offers option to exit or continue in re-configuration mode
- Prevents accidental re-installation/overwrites

#### 3. **Image Preservation**
- Detects existing Waydroid system and vendor images
- Shows image sizes before prompting
- Asks user to keep or re-download images (defaults to keep)
- Saves bandwidth and time by skipping unnecessary downloads
- Ensures config exists even when keeping images

#### 4. **waydroid_script Integration**
- Switched from package repos to GitHub installation
- Repository: [casualsnek/waydroid_script](https://github.com/casualsnek/waydroid_script)
- Follows author's exact installation instructions using Python venv
- Installs to: `~/.local/share/waydroid_script`
- Supports git pull updates for existing installations
- Credits: [@casualsnek](https://github.com/casualsnek) for the amazing waydroid_script

### Fixed Issues

#### Issue #1: Missing Socket Error
**Problem:**
```
Failed to enable unit: Unit waydroid-container.socket does not exist
```
**Solution:**
- Check if `waydroid-container.socket` exists before enabling
- Check if `waydroid-container-freeze.timer` exists before masking
- Graceful handling of optional systemd components

#### Issue #2: Python Module Conflicts (InquirerPy)
**Problem:**
```
ModuleNotFoundError: No module named 'InquirerPy'
```
**Multiple attempts to fix:**
1. ❌ Tried `--break-system-packages` (risky on Arch)
2. ❌ Tried system-wide pip install (conflicts with pacman)
3. ❌ Tried `--user` flag (didn't work with sudo)
4. ✅ **Final solution: Python venv (author's method)**

**Solution:**
- Follows [@casualsnek's](https://github.com/casualsnek) official instructions
- Creates isolated Python virtual environment
- Installs all dependencies in venv: `python3 -m venv venv`
- Runs with: `sudo venv/bin/python3 main.py`
- Zero system Python conflicts on Arch

#### Issue #3: waydroid_script Detection Priority
**Problem:**
- Broken symlink in `/usr/local/bin/waydroid_extras` detected first
- Cloned directory with working venv ignored

**Solution:**
- Reordered detection priority:
  1. Cloned directory with venv (highest priority)
  2. Package installation (`waydroid-script-git`)
  3. Manual installations in PATH
  4. Fresh install from GitHub

#### Issue #4: Missing Dependencies
**Problem:**
- `lzip` required by waydroid_script but not installed
- System dependencies not properly managed

**Solution:**
- Install system dependencies: `python`, `git`, `lzip`
- Install Python deps via venv requirements.txt
- Proper dependency isolation

#### Issue #5: Syntax Error
**Problem:**
```bash
syntax error near unexpected token `else'
```
**Solution:**
- Added missing `fi` statement
- Fixed nested if/else/fi structure

### Technical Improvements

#### Python Environment Management
- **Before:** System-wide pip installs (breaks Arch)
- **After:** Isolated venv per [@casualsnek's](https://github.com/casualsnek/waydroid_script) guidelines
- No conflicts with system Python packages
- Clean uninstallation possible

#### Script Architecture
- Better error handling and user prompts
- Clearer status messages (INFO, SUCCESS, WARNING, ERROR)
- Follows upstream project's best practices
- Respects original author's design decisions

### Credits & Attribution

**Special Thanks:**
- [@casualsnek](https://github.com/casualsnek) - Creator of [waydroid_script](https://github.com/casualsnek/waydroid_script)
- Original guide: [dougbug589/waydroid-guide-cachyos-arch](https://github.com/dougbug589/waydroid-guide-cachyos-arch)
- Waydroid project: [waydroid.io](https://waydro.id/)

### Installation Methods Tested

✅ Fresh installation on clean system  
✅ Re-configuration on existing installation  
✅ Image preservation and re-use  
✅ waydroid_script installation with venv  
✅ Kernel compatibility checks  
✅ Service management without socket errors

### Known Working Configurations

- **OS:** Arch Linux, CachyOS, Garuda, EndeavourOS
- **Kernels:** zen, cachyos, xanmod, lts (with binder)
- **Session:** Wayland (required)
- **Python:** System python3 with isolated venv

---
