#!/bin/bash
# =============================================================================
# export-my-settings.sh - Export your current GNOME/dconf settings to the repo
# =============================================================================
# Run this on the PC whose state you want to replicate (extensiones activadas/
# desactivadas, configuraciones de Caffeine, Dash to Dock, tema, keybindings, etc.).
# Creates config/dconf-gnome.ini so that ./install.sh applies the same state.
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
echo "  (extensiones activadas/desactivadas, configs de Caffeine/Dash to Dock, tema, teclado, etc.)"
dconf dump /org/gnome/ > "$OUTPUT_FILE"
echo "Listo. Archivo escrito: ${OUTPUT_FILE}"
echo ""
# Show what was captured for extensions
if grep -q '^\[shell\]' "$OUTPUT_FILE"; then
    echo "Estado de extensiones capturado:"
    grep -E '^(enabled-extensions|disabled-extensions)=' "$OUTPUT_FILE" 2>/dev/null || true
    echo ""
fi
echo "Siguiente paso: anade y commitea el archivo para que install.sh aplique este estado:"
echo "  git add config/dconf-gnome.ini"
echo "  git commit -m 'Update dconf backup (GNOME + extensiones)'"
echo ""
echo "En una instalacion nueva (o solo extensiones):"
echo "  ./install.sh --section gnome   # instala extensiones y aplica este estado"
echo "  ./install.sh --section gnome-settings   # solo restaura dconf (tema, keybindings, etc.)"
