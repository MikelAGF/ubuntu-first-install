#!/bin/bash
# =============================================================================
# gnome-extensions.sh - Instalacion y habilitacion de extensiones GNOME
# =============================================================================

# Extensiones de usuario (descargar e instalar desde extensions.gnome.org)
USER_EXTENSIONS=(
    "appmenu-is-back@fthx"
    "caffeine@patapon.info"
    "dash-to-dock@micxgx.gmail.com"
    "Vitals@CoreCoding.com"
)

# Extensiones del sistema (solo habilitar, ya vienen con Ubuntu)
SYSTEM_EXTENSIONS=(
    "ding@rastersoft.com"
    "ubuntu-appindicators@ubuntu.com"
    "ubuntu-dock@ubuntu.com"
    "tiling-assistant@ubuntu.com"
)

install_gext() {
    log_subsection "Instalando gnome-extensions-cli (gext)"
    if command_exists gext; then
        log_info "gext ya esta instalado"
        return 0
    fi

    apt_install pipx
    pipx install gnome-extensions-cli
    pipx ensurepath

    # Asegurar que ~/.local/bin esta en el PATH para esta sesion
    export PATH="$HOME/.local/bin:$PATH"

    if command_exists gext; then
        log_info "gext instalado correctamente"
    else
        log_error "No se pudo instalar gext"
        return 1
    fi
}

install_user_extensions() {
    log_subsection "Instalando extensiones de usuario"
    for ext in "${USER_EXTENSIONS[@]}"; do
        log_info "Instalando extension: $ext"
        if [[ -d "$HOME/.local/share/gnome-shell/extensions/$ext" ]]; then
            log_info "  $ext ya esta instalada"
        else
            gext install "$ext" 2>&1 || log_warn "No se pudo instalar $ext"
        fi
    done
}

enable_user_extensions() {
    log_subsection "Habilitando extensiones de usuario"
    for ext in "${USER_EXTENSIONS[@]}"; do
        log_info "Habilitando: $ext"
        gnome-extensions enable "$ext" 2>&1 || log_warn "No se pudo habilitar $ext"
    done
}

enable_system_extensions() {
    log_subsection "Habilitando extensiones del sistema"
    for ext in "${SYSTEM_EXTENSIONS[@]}"; do
        log_info "Habilitando: $ext"
        gnome-extensions enable "$ext" 2>&1 || log_warn "No se pudo habilitar $ext"
    done
}

# -----------------------------------------------------------------------------
# Funcion principal
# -----------------------------------------------------------------------------
setup_all_gnome_extensions() {
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log_info "[DRY-RUN] Instalaria y habilitaria las siguientes extensiones GNOME:"
        log_info "  Instalar (usuario):"
        for ext in "${USER_EXTENSIONS[@]}"; do
            log_info "    - $ext"
        done
        log_info "  Habilitar (sistema):"
        for ext in "${SYSTEM_EXTENSIONS[@]}"; do
            log_info "    - $ext"
        done
        return 0
    fi

    # Verificar que estamos en una sesion GNOME
    if [[ -z "$XDG_SESSION_TYPE" ]] || [[ "$XDG_CURRENT_DESKTOP" != *"GNOME"* ]]; then
        log_warn "No se detecto una sesion GNOME activa. Las extensiones pueden no instalarse correctamente."
        log_warn "Ejecuta esta seccion desde una sesion grafica GNOME."
    fi

    install_gext
    install_user_extensions
    enable_user_extensions
    enable_system_extensions

    log_warn "Puede ser necesario cerrar sesion y volver a entrar para que las extensiones se activen completamente"
}
