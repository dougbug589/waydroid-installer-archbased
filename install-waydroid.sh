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
WAYDROID_SCRIPT_DIR="$SCRIPT_HOME/.local/share/waydroid_script"

if [[ $EUID -eq 0 ]]; then
    print_error "Run this script as a normal user (no sudo)."
    exit 1
fi

if [[ ! -f /etc/pacman.conf ]]; then
    print_error "This script supports Arch-based distributions only."
    exit 1
fi

if [[ -z "$WAYLAND_DISPLAY" ]] && [[ -z "$WAYLAND_SOCKET" ]]; then
    print_error "Wayland session is required."
    exit 1
fi

check_kernel_compatibility() {
    print_step "Checking kernel compatibility"
    local kernel_name
    kernel_name=$(uname -r)
    local supported=("zen" "cachyos" "xanmod" "lts" "hardened" "clear")
    local ok=false

    for item in "${supported[@]}"; do
        if [[ "$kernel_name" =~ $item ]]; then
            ok=true
            break
        fi
    done

    if [[ "$ok" == false ]]; then
        if zgrep -q "CONFIG_ANDROID=y" /proc/config.gz 2>/dev/null || modprobe -n binder_linux &>/dev/null; then
            ok=true
        fi
    fi

    if [[ "$ok" == false ]]; then
        print_error "Unsupported kernel: $kernel_name"
        echo "Compatible kernels:"
        echo "  - linux-zen"
        echo "  - linux-cachyos"
        echo "  - linux-xanmod"
        echo "  - linux-lts"
        echo "  - linux-hardened"
        echo "  - linux-clear"
        exit 1
    fi

    print_success "Kernel is compatible"
}

setup_binderfs() {
    print_step "Setting up binderfs"
    if ! mount | grep -q binderfs; then
        sudo mkdir -p /dev/binderfs
        sudo mount -t binder binder /dev/binderfs
    fi

    sudo tee /etc/systemd/system/binderfs.service >/dev/null <<'EOF'
[Unit]
Description=Mount binderfs for Waydroid
DefaultDependencies=no
Before=waydroid-container.service

[Service]
Type=oneshot
ExecStart=/usr/bin/mount -t binder binder /dev/binderfs
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl enable binderfs.service
    print_success "binderfs ready"
}

install_and_init_waydroid() {
    print_step "Installing and initializing Waydroid"
    sudo pacman -S --needed --noconfirm waydroid
    setup_binderfs
    sudo waydroid init
    sudo systemctl daemon-reload
    sudo systemctl enable --now waydroid-container.service
    print_success "Waydroid installed and initialized"
}

install_and_run_waydroid_script() {
    print_step "Installing/updating waydroid_script"
    sudo pacman -S --needed --noconfirm python git lzip

    if [[ ! -d "$WAYDROID_SCRIPT_DIR" ]]; then
        git clone https://github.com/casualsnek/waydroid_script.git "$WAYDROID_SCRIPT_DIR"
    else
        git -C "$WAYDROID_SCRIPT_DIR" pull
    fi

    python3 -m venv "$WAYDROID_SCRIPT_DIR/venv"
    "$WAYDROID_SCRIPT_DIR/venv/bin/pip" install -r "$WAYDROID_SCRIPT_DIR/requirements.txt"

    print_info "Launching waydroid_script (select what you want to modify there)"
    sudo "$WAYDROID_SCRIPT_DIR/venv/bin/python3" "$WAYDROID_SCRIPT_DIR/main.py"
}

setup_safe_waydroid_launcher() {
    print_step "Setting up safe Waydroid launcher"

    local launcher_dir="$SCRIPT_HOME/.local/bin"
    local launcher_path="$launcher_dir/waydroid-safe-launcher"
    local desktop_dir="$SCRIPT_HOME/.local/share/applications"
    local desktop_path="$desktop_dir/waydroid-safe.desktop"

    mkdir -p "$launcher_dir" "$desktop_dir"

    cat > "$launcher_path" <<'EOF'
#!/bin/bash
set -e

cleanup() {
    sudo waydroid session stop >/dev/null 2>&1 || true
}

trap cleanup EXIT INT TERM

sudo waydroid session stop >/dev/null 2>&1 || true
waydroid session start
sleep 1
waydroid show-full-ui
EOF

    chmod +x "$launcher_path"

    cat > "$desktop_path" <<EOF
[Desktop Entry]
Type=Application
Name=Waydroid (Safe)
Comment=Launch Waydroid with auto session stop/start handling
Exec=$launcher_path
Icon=waydroid
Terminal=false
Categories=System;
EOF

    print_success "Safe launcher created: $launcher_path"
    print_success "Desktop entry created: $desktop_path"
}

configure_ufw() {
    print_step "UFW setup"

    if ! command -v ufw &>/dev/null; then
        print_info "UFW not found, installing..."
        sudo pacman -S --needed --noconfirm ufw
    fi

    sudo systemctl enable --now ufw
    sudo ufw --force enable
    sudo ufw allow 67
    sudo ufw allow 53
    sudo ufw default allow FORWARD
    print_success "UFW installed/enabled and Waydroid rules applied"
}

detect_existing_install() {
    pacman -Q waydroid &>/dev/null || [[ -d /var/lib/waydroid ]]
}

print_step "Detecting Waydroid installation"
if detect_existing_install; then
    print_warning "Existing Waydroid installation detected"
    echo "1) Fully remove Waydroid"
    echo "2) Modify existing setup with waydroid_script"
    echo "3) Exit"
    read -p "Choose (1/2/3): " existing_choice

    case "$existing_choice" in
        1)
            print_step "Removing Waydroid"
            sudo systemctl disable --now waydroid-container.service 2>/dev/null || true
            sudo pacman -Rns --noconfirm waydroid || true
            sudo rm -rf /var/lib/waydroid
            print_success "Waydroid removed"
            ;;
        2)
            install_and_run_waydroid_script
            setup_safe_waydroid_launcher
            ;;
        *)
            print_info "No changes made"
            exit 0
            ;;
    esac
else
    print_info "No existing Waydroid installation found"
    read -p "Do you want to install Waydroid now? (y/N): " do_install
    if [[ ! "$do_install" =~ ^[Yy]$ ]]; then
        print_info "Installation cancelled"
        exit 0
    fi

    check_kernel_compatibility
    install_and_init_waydroid
    install_and_run_waydroid_script
    configure_ufw
    setup_safe_waydroid_launcher
    print_info "Optional shared-folder symlink setup moved to: ./setup-waydroid-share.sh"
fi

print_success "Done"

