#!/usr/bin/env bash
# ============================================================
#  ytdl.sh — Téléchargeur YouTube interactif
#  Dépendance : yt-dlp (installé automatiquement si absent)
# ============================================================

set -euo pipefail

# ── Interruption propre (Ctrl+C) ─────────────────────────────
trap 'echo -e "\n${YELLOW}[!]${RESET} Interruption. À bientôt !\n"; exit 130' INT

# ── PATH : inclure ~/.local/bin pour yt-dlp installé via pip ─
export PATH="${HOME}/.local/bin:${PATH}"

# ── Couleurs ─────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

# ── Dossier de destination par défaut ────────────────────────
DEST="${HOME}/Téléchargements/Youtube"

# ── Fonctions utilitaires ─────────────────────────────────────
info()    { echo -e "${CYAN}[•]${RESET} $*"; }
success() { echo -e "${GREEN}[✓]${RESET} $*"; }
warn()    { echo -e "${YELLOW}[!]${RESET} $*"; }
error()   { echo -e "${RED}[✗]${RESET} $*" >&2; }

banner() {
  echo -e "${BOLD}${CYAN}"
  echo "  ╔══════════════════════════════════════╗"
  echo "  ║       YouTube Downloader v1.0        ║"
  echo "  ║         Propulsé par yt-dlp          ║"
  echo "  ╚══════════════════════════════════════╝"
  echo -e "${RESET}"
}

# ── Vérification / installation de yt-dlp ────────────────────
check_deps() {
  if ! command -v yt-dlp &>/dev/null; then
    warn "yt-dlp n'est pas installé. Installation en cours..."
    if command -v pip3 &>/dev/null; then
      pip3 install yt-dlp --break-system-packages -q
      success "yt-dlp installé avec succès."
    elif command -v pip &>/dev/null; then
      pip install yt-dlp -q
      success "yt-dlp installé avec succès."
    else
      error "pip introuvable. Installez yt-dlp manuellement : sudo apt install yt-dlp"
      exit 1
    fi
  fi

  info "Vérification des mises à jour de yt-dlp..."
  if yt-dlp -U --no-progress 2>&1 | grep -q "up-to-date"; then
    success "yt-dlp déjà à jour ($(yt-dlp --version))."
  else
    success "yt-dlp mis à jour ($(yt-dlp --version))."
  fi

  if ! command -v node &>/dev/null && ! command -v deno &>/dev/null; then
    warn "Runtime JavaScript absent — certains formats peuvent manquer."
    warn "Installez Node.js : sudo apt install nodejs"
  fi

  if ! command -v ffmpeg &>/dev/null; then
    warn "ffmpeg absent — conversion audio limitée."
    warn "Installez-le avec : sudo apt install ffmpeg"
  fi
}

# ── Saisie de l'URL ───────────────────────────────────────────
get_url() {
  echo ""
  echo -e "${BOLD}URL YouTube (vidéo ou playlist) :${RESET}"
  read -rp "  → " URL
  if [[ -z "$URL" ]]; then
    error "Aucune URL saisie."
    exit 1
  fi
  if [[ ! "$URL" =~ ^https?:// ]]; then
    error "URL invalide. Elle doit commencer par http:// ou https://"
    exit 1
  fi
}

# ── Menu principal ────────────────────────────────────────────
show_menu() {
  echo ""
  echo -e "${BOLD}Que voulez-vous télécharger ?${RESET}"
  echo ""
  echo "  1) 🎬  Vidéo — Meilleure qualité (MP4)"
  echo "  2) 🎬  Vidéo — Qualité au choix (360p / 720p / 1080p / 4K)"
  echo "  3) 🎵  Audio seulement (MP3)"
  echo "  4) 📋  Playlist complète (vidéos)"
  echo "  5) 📋  Playlist complète (audio MP3)"
  echo "  6) 📄  Sous-titres uniquement"
  echo "  7) 🔍  Voir les formats disponibles"
  echo "  8) 📁  Changer le dossier de destination (actuel : ${DEST})"
  echo "  0) ❌  Quitter"
  echo ""
  read -rp "  Votre choix [0-8] : " CHOICE
}

# ── Changer le dossier de destination ────────────────────────
change_dest() {
  echo ""
  echo -e "${BOLD}Nouveau dossier de destination :${RESET}"
  read -rp "  → " NEW_DEST
  if [[ -n "$NEW_DEST" ]]; then
    DEST="${NEW_DEST/#\~/$HOME}"
    success "Dossier mis à jour : $DEST"
  else
    warn "Dossier inchangé."
  fi
}

# ── Téléchargement ────────────────────────────────────────────
do_download() {
  local args=("$@")
  mkdir -p "$DEST"
  info "Téléchargement vers : ${BOLD}$DEST${RESET}"
  echo ""
  if ! yt-dlp "${args[@]}" -o "${DEST}/%(title)s.%(ext)s" "$URL"; then
    error "Échec du téléchargement. Vérifiez l'URL ou la connexion."
    return 1
  fi
  echo ""
  success "Terminé ! Fichier(s) disponible(s) dans : $DEST"
}

# ── Qualité au choix ──────────────────────────────────────────
pick_quality() {
  echo ""
  echo -e "${BOLD}Choisissez la qualité :${RESET}"
  echo "  1) 360p   2) 480p   3) 720p   4) 1080p   5) 1440p   6) 4K (2160p)"
  read -rp "  Votre choix [1-6] : " Q
  case "$Q" in
    1) HEIGHT=360  ;;
    2) HEIGHT=480  ;;
    3) HEIGHT=720  ;;
    4) HEIGHT=1080 ;;
    5) HEIGHT=1440 ;;
    6) HEIGHT=2160 ;;
    *) HEIGHT=1080; warn "Choix invalide, 1080p sélectionné par défaut." ;;
  esac
  do_download -f "bestvideo[height<=${HEIGHT}][ext=mp4]+bestaudio[ext=m4a]/best[height<=${HEIGHT}][ext=mp4]/best" --merge-output-format mp4
}

# ── Sous-titres ───────────────────────────────────────────────
download_subs() {
  echo ""
  echo -e "${BOLD}Langue des sous-titres (ex: fr, en, es) :${RESET}"
  read -rp "  → " LANG
  LANG="${LANG:-fr}"
  mkdir -p "$DEST"
  info "Téléchargement des sous-titres [${LANG}] vers : $DEST"
  yt-dlp --write-sub --write-auto-sub --sub-lang "$LANG" \
         --skip-download -o "${DEST}/%(title)s.%(ext)s" "$URL"
  success "Sous-titres téléchargés dans : $DEST"
}

# ── Boucle principale ─────────────────────────────────────────
main() {
  banner
  check_deps
  get_url

  while true; do
    show_menu
    case "$CHOICE" in
      1) do_download -f "bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best" --merge-output-format mp4 ;;
      2) pick_quality ;;
      3) do_download -x --audio-format mp3 --audio-quality 0 ;;
      4) do_download -f "bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best" --merge-output-format mp4 --yes-playlist ;;
      5) do_download -x --audio-format mp3 --audio-quality 0 --yes-playlist ;;
      6) download_subs ;;
      7) info "Formats disponibles pour : $URL"
         echo ""
         yt-dlp -F "$URL" ;;
      8) change_dest ;;
      0) echo -e "\n${GREEN}À bientôt !${RESET}\n"; exit 0 ;;
      *) warn "Choix invalide, réessayez." ;;
    esac

    echo ""
    read -rp "  Télécharger autre chose avec la même URL ? [o/N] : " AGAIN
    if [[ ! "$AGAIN" =~ ^[oOyY]$ ]]; then
      echo ""
      read -rp "  Saisir une nouvelle URL ? [o/N] : " NEW
      if [[ "$NEW" =~ ^[oOyY]$ ]]; then
        get_url
      else
        echo -e "\n${GREEN}À bientôt !${RESET}\n"
        exit 0
      fi
    fi
  done
}

main
