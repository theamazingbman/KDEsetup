#!/usr/bin/env bash

# Exit immediately if a command fails
set -e

# Change directory to where the script is located
cd "$(dirname "$0")"

echo "============================================"
echo " Starting Terry's Fedora KDE Setup   "
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

# 7. Install SF Pro Font System-Wide
echo -e "\n--> Installing Apple SF Pro Font..."
# Ensure git is installed for the clone process
if ! command -v git &> /dev/null; then
    sudo dnf install -y git
fi

# Clone, install, and clean up in a temporary directory
git clone https://github.com/sahibjotsaggu/San-Francisco-Pro-Fonts.git /tmp/sf-pro
sudo mkdir -p /usr/share/fonts/sf-pro
sudo cp -r /tmp/sf-pro/* /usr/share/fonts/sf-pro/
rm -rf /tmp/sf-pro

# Update the global font cache
sudo fc-cache -f -v
echo "SF Pro Font installed successfully."

echo -e "\n======================================"
echo " KDE Setup Complete!        "
echo " Please log out or restart your PC.   "
echo "======================================"
