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

log "Début de l'installation Hyprland + NVIDIA + PipeWire + LazyVim"

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
)

AUR_PACKAGES=(
  brave-bin swaync
)

log "Installation des paquets officiels..."
sudo pacman -S --needed --noconfirm "${OFFICIAL_PACKAGES[@]}"
success "Paquets officiels installés"

log "Installation des paquets AUR..."
yay -S --needed --noconfirm "${AUR_PACKAGES[@]}"
success "Paquets AUR installés"

# ------------------------------
# Hyprlock (AUR)
# ------------------------------
if ! yay -Q hyprlock-git &>/dev/null; then
  log "Installation de hyprlock-git..."
  yay -S --noconfirm hyprlock-git || warn "Impossible d'installer hyprlock-git, continuation du script"
else
  log "hyprlock-git déjà installé."
fi

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
    cp -r "$f" "$dest/"
  done
  success "Déployé : $dest"
}

# Hyprland complet (configs + wallpapers + scripts)
deploy_config "$REPO_DIR/hypr" "$HOME/.config/hypr" "toggle-audio.sh"

# Swaync
mkdir -p "$HOME/.config/swaync/icons"
mkdir -p "$HOME/.config/swaync/themes"
cp -r "$REPO_DIR/swaync/icons/"* "$HOME/.config/swaync/icons/"
cp -r "$REPO_DIR/swaync/themes/"* "$HOME/.config/swaync/themes/"
success "Config Swaync copiée"

# Kitty
deploy_config "$REPO_DIR/kitty" "$HOME/.config/kitty"

# Waybar
deploy_config "$REPO_DIR/waybar" "$HOME/.config/waybar"

# Nvim (LazyVim custom)
deploy_config "$REPO_DIR/nvim" "$HOME/.config/nvim"

# Zsh
mkdir -p "$HOME/.config/zsh"
cp -r "$REPO_DIR/zsh-config/"* "$HOME/.config/zsh/"
success "Configuration Zsh déployée"

# Lua
mkdir -p "$HOME/.config/nvim/lua"
cp -r "$REPO_DIR/lua/config/"* "$HOME/.config/nvim/lua/config/"
cp -r "$REPO_DIR/lua/plugins/"* "$HOME/.config/nvim/lua/plugins/"

# ------------------------------
# Services
# ------------------------------
sudo systemctl enable --now NetworkManager
sudo systemctl --global enable pipewire.service pipewire-pulse.service wireplumber
success "Services activés"

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
