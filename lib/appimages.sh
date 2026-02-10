#!/bin/bash
# =============================================================================
# appimages.sh - Instalacion de LM Studio y otros AppImages
# =============================================================================

LM_STUDIO_URL="https://releases.lmstudio.ai/linux/x86/latest"

setup_lm_studio() {
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log_info "[DRY-RUN] Instalaria LM Studio AppImage en ~/Applications/lm-studio/"
        return 0
    fi

    local install_dir="$HOME/Applications/lm-studio"
    local appimage_path="${install_dir}/LM-Studio.AppImage"

    if [[ -f "$appimage_path" ]]; then
        log_info "LM Studio ya esta instalado en $install_dir"
        return 0
    fi

    log_subsection "Instalando LM Studio"

    # Dependencia para AppImages
    ensure_libfuse2 || true

    ensure_dir "$install_dir"

    log_info "Descargando LM Studio AppImage..."
    wget -O "$appimage_path" "$LM_STUDIO_URL"
    chmod +x "$appimage_path"

    # Crear .desktop file
    log_info "Creando .desktop file para LM Studio"
    ensure_dir "$HOME/.local/share/applications"

    cat > "$HOME/.local/share/applications/lm-studio.desktop" << DESKTOP
[Desktop Entry]
Name=LM Studio
Comment=Run local LLMs
Exec=${appimage_path} --no-sandbox %U
Icon=lm-studio
Terminal=false
Type=Application
Categories=Development;Science;
StartupWMClass=LM Studio
DESKTOP

    update-desktop-database "$HOME/.local/share/applications/" 2>/dev/null || true
    log_info "LM Studio instalado en $install_dir"
}

# -----------------------------------------------------------------------------
# Funcion principal
# -----------------------------------------------------------------------------
setup_all_appimages() {
    setup_lm_studio
}
