#!/usr/bin/env bash

# Exit immediately if a command fails
set -e

# Change directory to where the script is located
cd "$(dirname "$0")"

echo "============================================"
echo " Starting Terry's Fedora System Restoration "
echo "============================================"

# 1. Install RPM Fusion Repositories
echo -e "\n--> Installing RPM Fusion (Free and Non-Free)..."
if ! rpm -q rpmfusion-free-release >/dev/null 2>&1; then
    sudo dnf install -y \
        https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
        https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
else
    echo "RPM Fusion is already installed."
fi

# 2. Install Brave Browser
echo -e "\n--> Installing Brave Browser..."
curl -fsS https://dl.brave.com/install.sh | FLAVOR=origin sh

# 3. Update System DNF Repositories
echo -e "\n--> Updating DNF system..."
sudo dnf upgrade -y

# 4. Install DNF Packages from file
if [ -f "dnf_packages.txt" ]; then
    echo -e "\n--> Installing DNF packages..."
    sudo dnf install -y $(cat dnf_packages.txt)
else
    echo "Warning: dnf_packages.txt not found. Skipping."
fi

# 5. Swap to Full Multimedia Codecs (RPM Fusion)
echo -e "\n--> Configuring Full Multimedia Codecs..."
sudo dnf swap -y ffmpeg-free ffmpeg --allowerasing
sudo dnf install -y @multimedia --setopt="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin
sudo dnf install -y gstreamer1-plugins-ugly gstreamer1-libav --allowerasing

# 6. Setup Flatpak Repository & Apps
echo -e "\n--> Configuring Flathub..."
flatpak remote-add --if-not-exists flathub https://flathub.org
flatpak update --appstream

if [ -f "flatpak_packages.txt" ]; then
    echo -e "\n--> Installing Flatpak applications..."
    while IFS= read -r app || [ -n "$app" ]; do
        [[ -z "$app" || "$app" =~ ^# ]] && continue
        echo "Installing Flatpak: $app"
        flatpak install flathub "$app" -y --noninteractive || echo "Failed to install $app, skipping..."
    done < flatpak_packages.txt
else
    echo "Warning: flatpak_packages.txt not found. Skipping."
fi

# 7. Restore Desktop Custom Themes & Settings via dconf
if [ -f "desktop_settings.ini" ]; then
    echo -e "\n--> Restoring Desktop Settings and Themes via dconf..."
    dconf load / < desktop_settings.ini
else
    echo "Warning: desktop_settings.ini not found. Skipping settings restore."
fi

# 8. Restore Fuzzel Custom Styles
echo -e "\n--> Restoring Fuzzel configurations..."
if [ -d "fuzzel" ]; then
    # Create the config directory if it doesn't exist (-p prevents errors if it exists)
    mkdir -p "$HOME/.config/fuzzel"
    # Copy the style file into place
    cp fuzzel/fuzzel.ini "$HOME/.config/fuzzel/fuzzel.ini"
    echo "Fuzzel style file applied successfully."
else
    echo "Warning: Fuzzel configuration folder not found. Skipping."
fi

echo -e "\n======================================"
echo " System Restoration Complete!         "
echo " Please log out or restart your PC.   "
echo "======================================"
