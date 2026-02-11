#!/bin/bash
# =============================================================================
# cursor-ide.sh - Instalacion de Cursor IDE (.deb) con icono custom
# =============================================================================

CURSOR_DEB_URL="https://api2.cursor.sh/updates/download/golden/linux-x64-deb/cursor/2.4"
CURSOR_ICON_NAME="cursor-icon.png"

setup_cursor_ide() {
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log_info "[DRY-RUN] Instalaria Cursor IDE via .deb con icono custom"
        return 0
    fi

    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

    # Instalar dependencia (FUSE para .deb/AppImage)
    log_subsection "Instalando dependencias de Cursor"
    ensure_libfuse2 || true

    # Descargar e instalar .deb
    log_subsection "Descargando Cursor IDE (.deb)"
    local deb_path="/tmp/cursor.deb"

    if is_installed cursor; then
        log_info "Cursor ya esta instalado via .deb"
    else
        wget -O "$deb_path" "$CURSOR_DEB_URL"
        log_info "Instalando Cursor IDE..."
        sudo apt install -y "$deb_path"
        rm -f "$deb_path"
    fi

    # Configurar icono custom
    log_subsection "Configurando icono custom de Cursor"
    local icon_src="${script_dir}/${CURSOR_ICON_NAME}"
    local icon_dest="$HOME/.local/share/icons/${CURSOR_ICON_NAME}"
    local desktop_src="/usr/share/applications/cursor.desktop"
    local desktop_dest="$HOME/.local/share/applications/cursor.desktop"

    if [[ ! -f "$icon_src" ]]; then
        log_warn "No se encontro ${CURSOR_ICON_NAME} en ${script_dir}"
        return 0
    fi

    ensure_dir "$HOME/.local/share/icons"
    ensure_dir "$HOME/.local/share/applications"

    cp "$icon_src" "$icon_dest"
    log_info "Icono custom copiado a $icon_dest"

    # Copiar y modificar .desktop file
    if [[ -f "$desktop_src" ]]; then
        cp "$desktop_src" "$desktop_dest"
        sed -i "s|^Icon=.*|Icon=${icon_dest}|" "$desktop_dest"
        log_info "Desktop file modificado con icono custom"
    else
        # Si el .deb no creo un .desktop, crear uno manualmente
        log_warn ".desktop de Cursor no encontrado en /usr/share, creando uno..."
        cat > "$desktop_dest" << DESKTOP
[Desktop Entry]
Name=Cursor
Exec=cursor --no-sandbox %U
Icon=${icon_dest}
Type=Application
Categories=Utility;Development;TextEditor;
MimeType=text/plain;
StartupWMClass=Cursor
DESKTOP
    fi

    update-desktop-database "$HOME/.local/share/applications/" 2>/dev/null || true
    log_info "Cursor IDE instalado con icono custom"

    # Importar y activar perfil de Cursor
    log_subsection "Configurando perfil de Cursor"
    local profile_src="${script_dir}/cursor/MikelAGF.code-profile"

    if [[ -f "$profile_src" ]]; then
        log_info "Importando perfil MikelAGF..."
        cursor --profile import "$profile_src" || log_warn "No se pudo importar el perfil (puede que Cursor necesite ejecutarse primero)"

        log_info "Activando perfil MikelAGF..."
        cursor --profile MikelAGF || log_warn "No se pudo activar el perfil"

        log_info "Perfil de Cursor configurado"
    else
        log_warn "No se encontro el perfil en ${profile_src}"
    fi
}
