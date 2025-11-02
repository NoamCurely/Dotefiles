#!/bin/bash

set -e

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
	echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
	echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
	echo -e "${RED}[ERROR]${NC} $1"
}

if [ ! -f /etc/arch-release ]; then
	print_error "Ce script est conçu uniquement pour Arch Linux"
	exit 1
fi

print_status "Début de l'installation Hyprland sur Arch Linux..."

print_status "Mise à jour du système..."

sudo pacman -Syu --noconfirm

if ! command -v yay &>/dev/null; then
	print_status "Installation de yay (AUR helper)..."

	sudo pacman -S --needed base-devel git --noconfirm

	cd /tmp

	git clone https://aur.archlinux.org/yay.git

	cd yay

	makepkg -si --noconfirm

	cd ~

	print_success "yay installé avec succès"
fi

OFFICIAL_PACKAGES=(
	"hyprland"
	"code"
	"discord"
	"dolphin"
	"git"
	"kitty"
	"neofetch"
	"neovim"
	"networkmanager"
	"openssh"
	"pavucontrol"
	"pipewire"
	"python-pip"
	"waybar"
	"wofi"
	"zsh"
)

AUR_PACKAGES=(
	"brave-bin"
	"swaync"
	"yay-git"
)

print_status "Installation des paquets officiels..."

for package in "${OFFICIAL_PACKAGES[@]}"; do
	print_status "Installation de $package..."
done

sudo pacman -S --needed --noconfirm "${OFFICIAL_PACKAGES[@]}"

print_success "Paquets officiels installés"

print_status "Installation des paquets AUR..."

for package in "${AUR_PACKAGES[@]}"; do
	print_status "Installation de $package..."
done

yay -S --needed --noconfirm "${AUR_PACKAGES[@]}"

print_success "Paquets AUR installés"

print_status "Installation de LazyVim..."
# Sauvegarde de la config nvim existante si elle existe
if [ -d ~/.config/nvim ]; then
	print_status "Sauvegarde de la configuration Neovim existante..."
	mv ~/.config/nvim ~/.config/nvim.bak.$(date +%Y%m%d_%H%M%S)
fi

if [ -d ~/.local/share/nvim ]; then
	mv ~/.local/share/nvim ~/.local/share/nvim.bak.$(date +%Y%m%d_%H%M%S)
fi

# Installation de LazyVim
git clone https://github.com/LazyVim/starter ~/.config/nvim

rm -rf ~/.config/nvim/.git

print_success "LazyVim installé"

print_status "Activation des services..."

sudo systemctl enable NetworkManager

sudo systemctl start NetworkManager

print_success "NetworkManager activé"

# Configuration de pipewire
sudo systemctl --global enable pipewire.service

sudo systemctl --global enable pipewire-pulse.service

print_success "Pipewire configuré"

print_success "Installation terminée avec succès !"
