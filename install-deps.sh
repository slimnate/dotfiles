#! /bin/bash

# Required deps
# Install gnu stow and rsync
sudo pacman -S stow rsync

# Install wget (used in other install scripts, plus I want it installed anyway)
sudo pacman -S wget

# Optional deps
function prompt_install()
{
    read -p "Do you want to install $1? (y/n): " yn
    case $yn in
    [Yy]*) return 0;;
    [Nn]*) return 1;;
    *) echo "Invalid response"; return 1;;
    esac
}

# Install Joplin notes
if prompt_install "Joplin Notes"; then
    echo "Installing Joplin Notes..."
    yay -S joplin-desktop
else
    echo "Skipping Joplin Notes..."
fi

# Install Windscribe
if prompt_install "Windscribe"; then
    echo "Installing Windscribe..."
    yay -S windscribe-v2-bin
else
    echo "Skipping Windscribe..."
fi

# Install Tailscale
if prompt_install "Tailscale"; then
    echo "Installing Tailscale..."
    curl -fsSL https://tailscale.com/install.sh | sh
else
    echo "Skipping Tailscale..."
fi

#Install starship prompt
if prompt_install "Starship Prompt (custom terminal prompt)"; then
    echo "Installing Starship Prompt..."
    sudo pacman -S starship
else
    echo "Skipping Starship Prompt..."
fi

# Install asciiquarium
if prompt_install "Asciiquarium (for terminal background)"; then
    echo "Installing Asciiquarium..."
    sudo pacman -S asciiquarium
else
    echo "Skipping Asciiquarium..."
fi

# Install custom version of Microsoft Edge and configure as default browser
if prompt_install "Microsoft Edge and set as default browser"; then
    echo "Installing Microsoft Edge..."
    sudo chmod +x ./install-microsoft-edge-version.sh
    ./install-microsoft-edge-version.sh 143.0.3650.96
    xdg-settings set default-web-browser microsoft-edge.desktop
else
    echo "Skipping Microsoft Edge..."
fi

# Install polychromatic for Razer devices
if prompt_install "Polychromatic (for razer devices)"; then
    echo "Installing Polychromatic..."
    yay -S polychromatic
else
    echo "Skipping Polychromatic..."
fi