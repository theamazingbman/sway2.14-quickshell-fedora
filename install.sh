#!/usr/bin/env bash
# Sway Setup Installer (Fedora Refactor)
# Based on JustAGuy Linux DWM Setup

set -Eeuo pipefail

ONLY_CONFIG=false
while [[ $# -gt 0 ]]; do
    case "$1" in
        --only-config) ONLY_CONFIG=true; shift ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo "  --only-config  Only copy config files (skip packages and themes)"
            echo "  --help         Show this help message"
            exit 0
            ;;
        *) echo "Unknown option: $1" >&2; echo "Use --help for usage information" >&2; exit 1 ;;
    esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config/sway"
TEMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/sway-setup.XXXXXX")"
LOG_FILE="$HOME/sway-install.log"
mkdir -p "$(dirname "$LOG_FILE")"
exec > >(tee -a "$LOG_FILE") 2>&1
trap 'rm -rf "$TEMP_DIR"' EXIT

RED='\033[0;31m'; YELLOW='\033[1;33m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'; NC='\033[0m'
die() { echo -e "${RED}ERROR: $*${NC}" >&2; exit 1; }
warn() { echo -e "${YELLOW}WARNING: $*${NC}" >&2; }
msg() { echo -e "${CYAN}$*${NC}"; }

if [[ "$ONLY_CONFIG" == false ]]; then
    [[ -r /etc/os-release ]] || die "Cannot read /etc/os-release to verify OS"
    # shellcheck disable=SC1091
    . /etc/os-release
    [[ "${ID:-}" == "fedora" || " ${ID_LIKE:-} " == *" fedora "* ]] ||
        die "Unsupported OS: ${PRETTY_NAME:-unknown}. This installer requires Fedora."
fi

echo -e "${CYAN}"
echo " +-+-+-+-+-+-+-+-+-+-+-+-+ "
echo " |  TERRY'S SWAY SETUP   | "
echo " +-+-+-+-+-+-+-+-+-+-+-+-+ "
echo " |      WAYLAND WM       | "
echo " +-+-+-+-+-+-+-+-+-+-+-+-+ "
echo -e "${NC}\n"

if [[ -t 0 ]]; then
    read -r -p "Install Sway on Fedora? (y/n) " -n 1 REPLY
    echo
    [[ "$REPLY" =~ ^[Yy]$ ]] || exit 1
fi

install_user_fonts() {
    local font_dir="$HOME/.local/share/fonts"
    local fa_extract="$TEMP_DIR/fontawesome"
    mkdir -p "$font_dir/JetBrainsMono" "$font_dir/FontAwesome6"

    msg "Downloading JetBrainsMono Nerd Font..."
    curl -fL --retry 3 \
        "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip" \
        -o "$TEMP_DIR/JetBrainsMono.zip" ||
        die "Failed to download JetBrainsMono Nerd Font"
    unzip -oq "$TEMP_DIR/JetBrainsMono.zip" -d "$font_dir/JetBrainsMono" ||
        die "Failed to extract JetBrainsMono Nerd Font"

    msg "Downloading Font Awesome 6 Free..."
    curl -fL --retry 3 \
        "https://github.com/FortAwesome/Font-Awesome/releases/download/6.7.2/fontawesome-free-6.7.2-desktop.zip" \
        -o "$TEMP_DIR/FontAwesome6.zip" ||
        die "Failed to download Font Awesome 6 Free"
    mkdir -p "$fa_extract"
    unzip -oq "$TEMP_DIR/FontAwesome6.zip" -d "$fa_extract" ||
        die "Failed to extract Font Awesome 6 Free"
    find "$fa_extract" -type f \( -name '*.otf' -o -name '*.ttf' \) \
        -exec cp -f -t "$font_dir/FontAwesome6" {} + ||
        die "Failed to copy Font Awesome font files"

    fc-cache -f "$font_dir" || die "Failed to refresh font cache"
    msg "User fonts installed."
}

install_nordic_theme() {
    local theme_dir="$HOME/.local/share/themes"
    local theme_tmp="$TEMP_DIR/Nordic"

    msg "Downloading Nordic GTK theme..."
    git clone --depth 1 https://github.com/EliverLara/Nordic.git "$theme_tmp" ||
        die "Failed to download Nordic GTK theme"
    [[ -f "$theme_tmp/index.theme" && -d "$theme_tmp/gtk-3.0" ]] ||
        die "Downloaded Nordic repository does not look like a GTK theme"

    mkdir -p "$theme_dir"
    # Install to a staging directory, then replace the prior copy safely.
    rm -rf "$theme_dir/Nordic.new"
    cp -a "$theme_tmp" "$theme_dir/Nordic.new" ||
        die "Failed to copy Nordic GTK theme"
    rm -rf "$theme_dir/Nordic"
    mv "$theme_dir/Nordic.new" "$theme_dir/Nordic" ||
        die "Failed to activate Nordic theme files"

    msg "Nordic GTK theme installed to $theme_dir/Nordic."
}

if [[ "$ONLY_CONFIG" == false ]]; then
    msg "Setting up RPM Fusion repositories..."
    FEDORA_VERSION="$(rpm -E %fedora)"
    if ! rpm -q rpmfusion-free-release >/dev/null 2>&1; then
        sudo dnf install -y \
            "https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-${FEDORA_VERSION}.noarch.rpm"
    fi
    if ! rpm -q rpmfusion-nonfree-release >/dev/null 2>&1; then
        sudo dnf install -y \
            "https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${FEDORA_VERSION}.noarch.rpm"
    fi
    msg "Updating DNF system..."
    sudo dnf upgrade -y
fi

PACKAGES_CORE=(sway swayidle swaybg waybar xorg-x11-server-Xwayland)
PACKAGES_SWAY=(wmenu foot geany gimp inkscape swaync fuzzel grim slurp wl-clipboard cliphist brightnessctl playerctl wlr-randr xdg-desktop-portal-wlr swappy wtype)
PACKAGES_UI=(xsettingsd NetworkManager-tui lxpolkit)
PACKAGES_FILE_MANAGER=(nautilus gvfs-smb gvfs-mtp dialog mtools unzip)
PACKAGES_AUDIO=(pavucontrol pamixer pipewire-utils)
PACKAGES_UTILITIES=(avahi acpi acpid upower power-profiles-daemon fd-find xdg-user-dirs-gtk kanshi eog gawk libnotify libnotify-devel libusb btop)
PACKAGES_BUILD=(cmake meson ninja-build curl pkgconfig wget git unzip fontconfig)
PACKAGES_FONTS=(google-noto-color-emoji-fonts fontawesome-fonts)

if [[ "$ONLY_CONFIG" == false ]]; then
    msg "Enabling Quickshell COPR..."
    if sudo dnf copr enable -y errornointernet/quickshell; then
        sudo dnf install -y quickshell || die "Failed to install Quickshell from COPR"
    else
        die "Could not enable errornointernet/quickshell COPR; Quickshell is required for this setup."
    fi

    msg "Installing base development tools..."
    sudo dnf group install -y development-tools || die "Failed to install development tools"
    msg "Installing core Sway packages..."
    sudo dnf install -y "${PACKAGES_CORE[@]}" || die "Failed to install core packages"
    msg "Installing Sway components..."
    sudo dnf install -y "${PACKAGES_SWAY[@]}" || die "Failed to install Sway packages"
    msg "Installing UI components..."
    sudo dnf install -y "${PACKAGES_UI[@]}" || die "Failed to install UI packages"
    msg "Installing file manager..."
    sudo dnf install -y "${PACKAGES_FILE_MANAGER[@]}" || die "Failed to install file manager"
    msg "Installing audio support..."
    sudo dnf install -y "${PACKAGES_AUDIO[@]}" || die "Failed to install audio packages"
    msg "Installing build tools and font utilities..."
    sudo dnf install -y "${PACKAGES_BUILD[@]}" || die "Failed to install build tools"
    msg "Installing system utilities..."
    sudo dnf install -y --allowerasing "${PACKAGES_UTILITIES[@]}" || die "Failed to install utilities"
    msg "Installing default browser..."
    sudo dnf install -y firefox || warn "Could not install Firefox; continuing."
    msg "Installing packaged fonts..."
    sudo dnf install -y "${PACKAGES_FONTS[@]}" || die "Failed to install fonts"

    install_user_fonts
    install_nordic_theme

    msg "Configuring multimedia codecs..."
    sudo dnf swap -y ffmpeg-free ffmpeg --allowerasing || warn "Could not swap FFmpeg packages."
    sudo dnf group install -y multimedia --setopt="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin ||
        warn "Could not install the full multimedia group."
    sudo dnf install -y gstreamer1-plugins-ugly gstreamer1-libav --allowerasing ||
        warn "Could not install some multimedia plugins."

    msg "Installing autotiling..."
    sudo dnf install -y python3-pip python3-i3ipc
    if ! sudo pip3 install --prefix=/usr autotiling; then
        warn "System-wide pip installation failed; trying pipx."
        sudo dnf install -y pipx || warn "Could not install pipx."
        if command -v pipx >/dev/null 2>&1; then
            pipx install autotiling || warn "Could not install autotiling with pipx."
        fi
    fi

    msg "Enabling nwg-shell Copr repository..."
    if sudo dnf copr enable -y tofik/nwg-shell; then
        sudo dnf install -y nwg-look nwg-displays || warn "Could not install nwg tools."
    else
        warn "Could not enable nwg-shell Copr; skipping nwg tools."
    fi

    sudo systemctl enable avahi-daemon acpid || warn "Could not enable one or more services."
else
    msg "Skipping package installation (--only-config mode)"
fi

# Configure Nordic GTK theme when installed; keep GTK settings consistent with the installed theme.
GTK_THEME="Nordic"
if [[ "$ONLY_CONFIG" == false ]]; then
    msg "Configuring Nordic GTK theme..."
    mkdir -p "$HOME/.config/gtk-3.0" "$HOME/.config/gtk-4.0"
    cat > "$HOME/.config/gtk-3.0/settings.ini" <<EOF
[Settings]
gtk-theme-name=$GTK_THEME
gtk-icon-theme-name=Adwaita
gtk-application-prefer-dark-theme=1
EOF
    cat > "$HOME/.config/gtk-4.0/settings.ini" <<EOF
[Settings]
gtk-theme-name=$GTK_THEME
gtk-icon-theme-name=Adwaita
gtk-application-prefer-dark-theme=1
EOF
    mkdir -p "$HOME/.config/xdg-desktop-portal"
    cat > "$HOME/.config/xdg-desktop-portal/settings.ini" <<'EOF'
[org.freedesktop.appearance]
color-scheme=1
EOF
    if command -v dconf >/dev/null 2>&1; then
        dconf write /org/gnome/desktop/interface/gtk-theme "'Nordic'" || true
        dconf write /org/gnome/desktop/interface/color-scheme "'prefer-dark'" || true
        dconf write /org/gnome/desktop/interface/icon-theme "'Adwaita'" || true
    fi
else
    msg "Skipping system theme installation and theme preferences (--only-config mode)"
fi

if [[ -d "$CONFIG_DIR" ]]; then
    if [[ -t 0 ]]; then
        read -r -p "Found existing Sway config. Back it up? (y/n) " -n 1 REPLY
        echo
        if [[ "$REPLY" =~ ^[Yy]$ ]]; then
            mv "$CONFIG_DIR" "$CONFIG_DIR.bak.$(date +%s)"
            msg "Backed up existing Sway config."
        else
            read -r -p "Overwrite without backup? (y/n) " -n 1 REPLY
            echo
            [[ "$REPLY" =~ ^[Yy]$ ]] || die "Installation cancelled"
            rm -rf "$CONFIG_DIR"
        fi
    else
        mv "$CONFIG_DIR" "$CONFIG_DIR.bak.$(date +%s)"
        msg "Non-interactive run: backed up existing Sway config."
    fi
fi

msg "Setting up configuration..."
mkdir -p "$CONFIG_DIR"
[[ -d "$SCRIPT_DIR/config" ]] || die "Config directory not found: $SCRIPT_DIR/config"
cp -a "$SCRIPT_DIR/config/." "$CONFIG_DIR/" || die "Failed to copy configs"

# Install the Quickshell port and helper scripts in a stable user-local share directory.
SHARE_INSTALL="$HOME/.local/share/sway-quickshell"
if [[ -d "$SCRIPT_DIR/share" ]]; then
    mkdir -p "$HOME/.local/share"
    if [[ -d "$SHARE_INSTALL" ]]; then
        mv "$SHARE_INSTALL" "$SHARE_INSTALL.bak.$(date +%s)"
    fi
    cp -a "$SCRIPT_DIR/share/." "$SHARE_INSTALL/" || die "Failed to install Quickshell files"
    chmod +x "$SHARE_INSTALL"/scripts/* 2>/dev/null || true
    mkdir -p "${XDG_STATE_HOME:-$HOME/.local/state}/sway-quickshell"
else
    warn "Quickshell files not found in $SCRIPT_DIR/share; skipping Quickshell installation."
fi

if [[ -e "$HOME/.config/foot" && ! -L "$HOME/.config/foot" ]]; then
    mv "$HOME/.config/foot" "$HOME/.config/foot.bak.$(date +%s)"
    msg "Backed up existing ~/.config/foot"
fi
if [[ -d "$CONFIG_DIR/foot" ]]; then
    ln -sfn "$CONFIG_DIR/foot" "$HOME/.config/foot"
fi

if command -v xdg-mime >/dev/null 2>&1; then
    xdg-mime default org.gnome.Nautilus.desktop inode/directory ||
        warn "Could not set Nautilus as the default directory handler."
fi

if [[ -L "$HOME/.config/gtklock" && "$(readlink "$HOME/.config/gtklock")" == "$HOME/.config/sway/gtklock" ]]; then
    rm "$HOME/.config/gtklock"
fi
ln -sfn themes/github_dark "$CONFIG_DIR/current-theme"

if command -v xdg-user-dirs-update >/dev/null 2>&1; then
    xdg-user-dirs-update || warn "Could not update user directories."
fi
mkdir -p "$HOME/Screenshots"

if [[ -f "$SCRIPT_DIR/QUICKSTART.md" ]]; then
    cp "$SCRIPT_DIR/QUICKSTART.md" "$HOME/QUICKSTART-sway.md"
fi
if [[ -f "$SCRIPT_DIR/nvidia-setup.sh" ]]; then
    cp "$SCRIPT_DIR/nvidia-setup.sh" "$HOME/nvidia-setup.sh"
    chmod +x "$HOME/nvidia-setup.sh"
fi

if [[ "$ONLY_CONFIG" == false ]]; then
    msg "Installing Brave Browser..."
    sudo dnf install -y dnf-plugins-core || warn "Could not install dnf-plugins-core."
    if sudo dnf config-manager addrepo --overwrite \
        --from-repofile=https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo; then
        sudo dnf install -y brave-browser || warn "Could not install Brave Browser."
    else
        warn "Could not add Brave repository; skipping Brave."
    fi

    msg "Configuring Flathub..."
    if command -v flatpak >/dev/null 2>&1; then
        flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo || true
        flatpak update --appstream || true
        FLATPAK_LIST="$SCRIPT_DIR/flatpak_packages.txt"
        if [[ -f "$FLATPAK_LIST" ]]; then
            while IFS= read -r app || [[ -n "$app" ]]; do
                [[ -z "$app" || "$app" =~ ^[[:space:]]*# ]] && continue
                echo "Installing Flatpak: $app"
                flatpak install --user flathub "$app" -y --noninteractive ||
                    warn "Failed to install Flatpak $app; continuing."
            done < "$FLATPAK_LIST"
        else
            warn "flatpak_packages.txt not found. Skipping Flatpak app installs."
        fi
    else
        warn "Flatpak is not installed; skipping Flatpak applications."
    fi
fi

msg "Sway setup script finished."
exit 0
