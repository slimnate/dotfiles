#!/usr/bin/env bash

set -euo pipefail

if [ -z "$1" ]; then
    echo "Usage: $0 <pkgver>"
    echo "Example: $0 143.0.3650.96"
    exit 1
fi

PKGVER="$1"
PKGREL=1
REPO_DIR="$HOME/software/microsoft-edge-stable"
DEB_FILE="microsoft-edge-stable_${PKGVER}-${PKGREL}_amd64.deb"
DEB_URL="https://packages.microsoft.com/repos/edge/pool/main/m/microsoft-edge-stable/${DEB_FILE}"

echo "Creating repository directory"
mkdir -p "$REPO_DIR"

if [ -d "$REPO_DIR/.git" ]; then
    echo "Updating existing AUR repository"
    git -C "$REPO_DIR" fetch --all --prune
    git -C "$REPO_DIR" reset --hard origin/master
else
    echo "Cloning AUR repository"
    git clone https://aur.archlinux.org/microsoft-edge-stable.git "$REPO_DIR"
fi

echo "==> Switching to repo directory"
cd "$REPO_DIR"

echo "==> Updating PKGBUILD with version $PKGVER"
sed -i "s/^pkgver=.*/pkgver=${PKGVER}/" PKGBUILD
sed -i "s/^pkgrel=.*/pkgrel=${PKGREL}/" PKGBUILD
sed -i "s|source=(.*)|source=(\"${DEB_FILE}::${DEB_URL}\")|" PKGBUILD

echo "==> Downloading .deb file"
wget -q --show-progress "$DEB_URL" -O "$DEB_FILE"

echo "==> Generating sha256sum"
SHA256=$(sha256sum "$DEB_FILE" | awk '{print $1}')
sed -i "s|sha256sums=(.*)|sha256sums=('${SHA256}')|" PKGBUILD

echo "==> Building and installing package"
makepkg -si --noconfirm

if ! command -v microsoft-edge-stable >/dev/null 2>&1; then
    echo "Install finished but microsoft-edge-stable is not on PATH" >&2
    exit 1
fi

echo "==> Done. Installed microsoft-edge-stable $PKGVER-$PKGREL"
