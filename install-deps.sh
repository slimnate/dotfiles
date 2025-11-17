
# Install microsoft-edge-stable-bin from AUR and configure as default browser
sudo yay -S microsoft-edge-stable-bin
xdg-settings set default-web-browser microsoft-edge-stable-bin.desktop

# Install Joplin notes
sudo yay -S joplin-desktop

#Install starship prompt
sudo pacman -S starship

# Install asciiquarium
sudo pacman -S asciiquarium

# Install rsync
sudo pacman -S rsync