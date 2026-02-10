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
    "openweather-extension@penguin-teal.github.io"
    "soft-brightness-plus@joelkitching.com"
    "status-area-horizontal-spacing@mathematical.coffee.gmail.com"
)

# Extensiones del sistema (solo habilitar, ya vienen con Ubuntu)
SYSTEM_EXTENSIONS=(
    "apps-menu@gnome-shell-extensions.gcampax.github.com"
    "auto-move-windows@gnome-shell-extensions.gcampax.github.com"
    "ding@rastersoft.com"
    "drive-menu@gnome-shell-extensions.gcampax.github.com"
    "launch-new-instance@gnome-shell-extensions.gcampax.github.com"
    "light-style@gnome-shell-extensions.gcampax.github.com"
    "native-window-placement@gnome-shell-extensions.gcampax.github.com"
    "places-menu@gnome-shell-extensions.gcampax.github.com"
    "screenshot-window-sizer@gnome-shell-extensions.gcampax.github.com"
    "system-monitor@gnome-shell-extensions.gcampax.github.com"
    "tiling-assistant@ubuntu.com"
    "ubuntu-appindicators@ubuntu.com"
    "ubuntu-dock@ubuntu.com"
    "user-theme@gnome-shell-extensions.gcampax.github.com"
    "window-list@gnome-shell-extensions.gcampax.github.com"
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
    export PATH="$HOME/.local/bin:$PATH"
    for ext in "${USER_EXTENSIONS[@]}"; do
        log_info "Instalando extension: $ext"
        if [[ -d "$HOME/.local/share/gnome-shell/extensions/$ext" ]]; then
            log_info "  $ext ya esta instalada"
        else
            if ! gext install "$ext" 2>&1; then
                sleep 2
                gext install "$ext" 2>&1 || log_warn "No se pudo instalar $ext"
            fi
        fi
    done
}

# Extension present on disk (user or system dir).
extension_on_disk() {
    local ext="$1"
    [[ -d "$HOME/.local/share/gnome-shell/extensions/$ext" ]] && return 0
    [[ -d "/usr/share/gnome-shell/extensions/$ext" ]] && return 0
    return 1
}

# Extension is visible to the running GNOME Shell (so we can enable it).
extension_visible_to_shell() {
    local ext="$1"
    gnome-extensions list 2>/dev/null | grep -qx "$ext" 2>/dev/null && return 0
    return 1
}

# Use session bus and DISPLAY so gnome-extensions talks to the running GNOME session.
ensure_gnome_session_env() {
    [[ -z "${DISPLAY:-}" ]] && export DISPLAY=:0
    if [[ -z "${DBUS_SESSION_BUS_ADDRESS:-}" ]]; then
        local bus="/run/user/$(id -u)/bus"
        [[ -S "$bus" ]] && export DBUS_SESSION_BUS_ADDRESS="unix:path=$bus"
    fi
}

enable_user_extensions() {
    log_subsection "Habilitando extensiones de usuario"
    ensure_gnome_session_env
    export PATH="$HOME/.local/bin:$PATH"
    for ext in "${USER_EXTENSIONS[@]}"; do
        if ! extension_on_disk "$ext"; then
            log_warn "Extension no instalada, omitiendo: $ext"
            continue
        fi
        if ! extension_visible_to_shell "$ext"; then
            log_warn "Extension no visible para esta sesión GNOME (cierra sesión y vuelve a entrar): $ext"
            continue
        fi
        log_info "Habilitando: $ext"
        gnome-extensions enable "$ext" 2>&1 || log_warn "No se pudo habilitar $ext"
    done
}

enable_system_extensions() {
    log_subsection "Habilitando extensiones del sistema"
    ensure_gnome_session_env
    for ext in "${SYSTEM_EXTENSIONS[@]}"; do
        if ! extension_on_disk "$ext"; then
            continue
        fi
        if ! extension_visible_to_shell "$ext"; then
            log_warn "Extension no visible para esta sesión: $ext"
            continue
        fi
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
