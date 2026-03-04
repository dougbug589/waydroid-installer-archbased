#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }
print_step() { echo -e "\n${GREEN}==>${NC} $1"; }

SCRIPT_USER="${SUDO_USER:-$USER}"
SCRIPT_HOME=$(eval echo ~$SCRIPT_USER)

if [[ $EUID -eq 0 ]]; then
    print_error "Run this script as a normal user (no sudo)."
    exit 1
fi

print_step "Setting up Waydroid shared-folder symlink"

WAYDROID_DATA="$SCRIPT_HOME/.local/share/waydroid/data/media/0"
SHARED_FOLDER="Waydroid"
SYMLINK_PATH="$SCRIPT_HOME/$SHARED_FOLDER"
WAYDROID_SHARED="$WAYDROID_DATA/$SHARED_FOLDER"

if [[ ! -d "$WAYDROID_DATA" ]]; then
    print_info "Waydroid storage path not found, creating it directly..."
    if ! mkdir -p "$WAYDROID_DATA" 2>/dev/null; then
        sudo mkdir -p "$WAYDROID_DATA"
        sudo chown "$SCRIPT_USER":"$SCRIPT_USER" "$WAYDROID_DATA"
    fi
fi

if [[ ! -d "$WAYDROID_DATA" ]]; then
    print_error "Waydroid storage path is still missing. Please check permissions and rerun."
    exit 1
fi

if ! groups | grep -q "waydroid"; then
    print_info "Adding $SCRIPT_USER to waydroid group (1023)..."
    if grep -q "^waydroid:x:1023:" /etc/group; then
        sudo usermod -aG waydroid "$SCRIPT_USER"
    else
        echo "waydroid:x:1023:$SCRIPT_USER" | sudo tee -a /etc/group >/dev/null
    fi
    print_warning "Re-login/reboot required for new group permissions"
fi

if ! mkdir -p "$WAYDROID_SHARED" 2>/dev/null; then
    sudo mkdir -p "$WAYDROID_SHARED"
    sudo chown "$SCRIPT_USER":"$SCRIPT_USER" "$WAYDROID_SHARED"
fi

if [[ -L "$SYMLINK_PATH" ]]; then
    current_target=$(readlink "$SYMLINK_PATH")
    if [[ "$current_target" == "$WAYDROID_SHARED" ]]; then
        print_success "Symlink already correct: ~/$SHARED_FOLDER"
        exit 0
    fi
    print_warning "Existing symlink points elsewhere; replacing it"
    rm -f "$SYMLINK_PATH"
elif [[ -e "$SYMLINK_PATH" ]]; then
    print_error "~/$SHARED_FOLDER exists and is not a symlink. Remove or rename it first."
    exit 1
fi

ln -s "$WAYDROID_SHARED" "$SYMLINK_PATH"
print_success "Shared folder ready"
print_info "Linux: ~/$SHARED_FOLDER"
print_info "Android: Internal storage/$SHARED_FOLDER"
