#!/bin/bash
# =============================================================================
# export-my-settings.sh - Export your current GNOME/dconf settings to the repo
# =============================================================================
# Run this on your current Ubuntu (with your keybindings, dark mode, keyboard
# layout, etc. already set). It creates config/dconf-gnome.ini so that
# ./install.sh --section gnome-settings can restore it on a fresh install.
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${SCRIPT_DIR}/config"
OUTPUT_FILE="${CONFIG_DIR}/dconf-gnome.ini"

if ! command -v dconf &>/dev/null; then
    echo "Error: dconf no encontrado. Ejecuta esto en Ubuntu con GNOME."
    exit 1
fi

mkdir -p "$CONFIG_DIR"
echo "Exportando configuracion GNOME (/org/gnome/) a ${OUTPUT_FILE} ..."
dconf dump /org/gnome/ > "$OUTPUT_FILE"
echo "Listo. Archivo escrito: ${OUTPUT_FILE}"
echo ""
echo "Siguiente paso: anade y commitea el archivo para que install.sh lo restaure:"
echo "  git add config/dconf-gnome.ini"
echo "  git commit -m 'Add dconf backup (GNOME settings)'"
echo ""
echo "En una instalacion nueva, ejecuta: ./install.sh --section gnome-settings"
