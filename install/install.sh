#!/bin/bash
set -e

# ------------------------------
# Couleurs pour l'affichage
# ------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# ------------------------------
# Vérification Arch
# ------------------------------
if [ ! -f /etc/arch-release ]; then
  error "Ce script est conçu uniquement pour Arch Linux"
  exit 1
fi

log "Début de l'installation Hyprland + NVIDIA + PipeWire + LazyVim + SDDM"

# ------------------------------
# Mise à jour
# ------------------------------
log "Mise à jour du système..."
sudo pacman -Syu --noconfirm
success "Système mis à jour."

# ------------------------------
# Installation yay (AUR)
# ------------------------------
if ! command -v yay &>/dev/null; then
  log "Installation de yay..."
  sudo pacman -S --needed base-devel git --noconfirm
  cd /tmp
  git clone https://aur.archlinux.org/yay.git
  cd yay
  makepkg -si --noconfirm
  cd ~
  rm -rf /tmp/yay
  success "yay installé"
else
  log "yay déjà installé."
fi

# ------------------------------
# Paquets officiels
# ------------------------------
OFFICIAL_PACKAGES=(
  hyprland waybar wofi kitty swaybg swayidle grim slurp wl-clipboard wlr-randr
  xdg-user-dirs polkit seatd xdg-desktop-portal xdg-desktop-portal-hyprland
  nvidia nvidia-utils nvidia-settings egl-wayland vulkan-icd-loader vulkan-tools libva
  pipewire pipewire-alsa pipewire-pulse pipewire-jack pipewire-audio wireplumber pavucontrol
  git neovim code discord dolphin python-pip networkmanager openssh zsh fastfetch
  sddm sddm-kcm ttf-jetbrains-mono ttf-nerd-fonts-symbols
  swaync
)

AUR_PACKAGES=(
  brave-bin swaync hyprlock-git
)

log "Installation des paquets officiels..."
sudo pacman -S --needed --noconfirm "${OFFICIAL_PACKAGES[@]}"
success "Paquets officiels installés"

log "Installation des paquets AUR..."
yay -S --needed --noconfirm "${AUR_PACKAGES[@]}"
success "Paquets AUR installés"

# ------------------------------
# LazyVim
# ------------------------------
log "Installation de LazyVim..."
if [ -d ~/.config/nvim ]; then
  mv ~/.config/nvim ~/.config/nvim.bak.$(date +%Y%m%d_%H%M%S)
fi
git clone https://github.com/LazyVim/starter ~/.config/nvim
rm -rf ~/.config/nvim/.git
success "LazyVim installé"

# ------------------------------
# Déploiement des configs
# ------------------------------
REPO_DIR="$(pwd)/../config"

deploy_config() {
  local src="$1"
  local dest="$2"
  local exclude="$3"
  [[ -d "$dest" ]] && mv "$dest" "${dest}.bak.$(date +%s)"
  mkdir -p "$dest"
  for f in "$src"/*; do
    base=$(basename "$f")
    [[ "$base" == "$exclude" ]] && continue
    mv "$f" "$dest/"
  done
  success "Déployé : $dest"
}

# Hyprland (tout sauf toggle-audio.sh)
HYPR_SRC="$REPO_DIR/hypr"
HYPR_DEST="$HOME/.config/hypr"

# Sauvegarde si déjà existant
[[ -d "$HYPR_DEST" ]] && mv "$HYPR_DEST" "${HYPR_DEST}.bak.$(date +%s)"

# Création du dossier
mkdir -p "$HYPR_DEST"

# Copier tout sauf toggle-audio.sh
shopt -s dotglob # inclut fichiers commençant par .
for f in "$HYPR_SRC"/*; do
  base=$(basename "$f")
  [[ "$base" == "toggle-audio.sh" ]] && continue
  mv "$f" "$HYPR_DEST/"
done
shopt -u dotglob

success "Configuration Hyprland déployée"

# S'assurer que les wallpapers sont bien dans le dossier
mkdir -p "$HYPR_DEST/wallpapers"
# Déplacer seulement s'il y a des fichiers
if [ -d "$HYPR_SRC/wallpapers" ]; then
  mv "$HYPR_SRC/wallpapers"/* "$HYPR_DEST/wallpapers/" 2>/dev/null || true
fi
success "Wallpapers Hypr copiés"

# Kitty
deploy_config "$REPO_DIR/kitty" "$HOME/.config/kitty"

# Waybar
deploy_config "$REPO_DIR/waybar" "$HOME/.config/waybar"

# Nvim (LazyVim custom)
deploy_config "$REPO_DIR/nvim" "$HOME/.config/nvim"

# Zsh
mkdir -p "$HOME/.config/zsh"
mv "$REPO_DIR/zsh-config"/* "$HOME/.config/zsh/"
success "Configuration Zsh déployée"

# Lua
mkdir -p "$HOME/.config/nvim/lua"
mv "$REPO_DIR/lua/config"/* "$HOME/.config/nvim/lua/config/"
mv "$REPO_DIR/lua/plugins"/* "$HOME/.config/nvim/lua/plugins/"

# ------------------------------
# SwayNC
# ------------------------------
SWAYNC_SRC="$REPO_DIR/swaync"
SWAYNC_DEST="$HOME/.config/swaync"

# Sauvegarde si déjà existant
[[ -d "$SWAYNC_DEST" ]] && mv "$SWAYNC_DEST" "${SWAYNC_DEST}.bak.$(date +%s)"

# Création du dossier
mkdir -p "$SWAYNC_DEST"

# Copier tout
mv "$SWAYNC_SRC"/* "$SWAYNC_DEST/"

success "Configuration SwayNC déployée"

# ------------------------------
# Services
# ------------------------------
sudo systemctl enable --now NetworkManager
sudo systemctl enable --now sddm
sudo systemctl --global enable pipewire.service pipewire-pulse.service wireplumber
success "Services activés"

# ------------------------------
# SDDM Configuration (FR + background)
# ------------------------------
log "Déploiement de la config SDDM..."
sudo mkdir -p /etc/sddm.conf.d
cp "$REPO_DIR/config/hypr/wallpapers/*" "$HOME/.config/sddm/"
sudo tee /etc/sddm.conf.d/custom.conf >/dev/null <<EOF
[Theme]
Current=breeze
Background=/usr/share/backgrounds/smoky.jpg

[General]
NumLock=on
InputMethod=

[Users]
MinimumUid=1000
EOF
success "SDDM configuré (FR layout par défaut + background)"

# ------------------------------
# Brave avec flag
# ------------------------------
log "Création du lanceur Brave avec --password-store=basic..."
mkdir -p ~/.local/share/applications
cat >~/.local/share/applications/brave-password.desktop <<EOF
[Desktop Entry]
Name=Brave
Comment=Brave Browser avec mot de passe basic
Exec=brave --password-store=basic %U
Icon=brave
Type=Application
Terminal=false
Categories=Network;WebBrowser;
EOF
success "Lanceur Brave créé"

# ------------------------------
success "Installation terminée ! Redémarre ou reconnecte-toi pour appliquer les configs."
