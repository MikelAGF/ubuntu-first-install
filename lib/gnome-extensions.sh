#!/bin/bash
# =============================================================================
# gnome-extensions.sh - Instalacion y habilitacion de extensiones GNOME
# =============================================================================

# Extensiones de usuario (descargar e instalar desde extensions.gnome.org)
USER_EXTENSIONS=(
    "appmenu-is-back@fthx"
    "caffeine@patapon.info"  # Evita que la pantalla se apague / el sistema entre en suspensión
    "dash-to-dock@micxgx.gmail.com"  # Mas configurable que ubuntu-dock (que esta desactivado)
    "Vitals@CoreCoding.com"  # Mejor que system-monitor
    "openweather-extension@penguin-teal.github.io"
    "soft-brightness-plus@joelkitching.com"
    "status-area-horizontal-spacing@mathematical.coffee.gmail.com"
)

# Extensiones del sistema (solo habilitar, ya vienen con Ubuntu)
SYSTEM_EXTENSIONS=(
    "apps-menu@gnome-shell-extensions.gcampax.github.com"
    "ding@rastersoft.com"
    "places-menu@gnome-shell-extensions.gcampax.github.com"
    "tiling-assistant@ubuntu.com"
    "ubuntu-appindicators@ubuntu.com"
    # "ubuntu-dock@ubuntu.com"  # Desactivado - usamos dash-to-dock en su lugar
    "user-theme@gnome-shell-extensions.gcampax.github.com"
    # "window-list@gnome-shell-extensions.gcampax.github.com"  # No habilitar por defecto
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

# Compile GSettings schemas for extensions that have schemas/ (e.g. Caffeine).
# Fixes: "Failed to open file .../gschemas.compiled": No such file or directory
compile_extension_schemas() {
    log_subsection "Compilando esquemas de extensiones (GSettings)"
    if ! command_exists glib-compile-schemas 2>/dev/null; then
        apt_install_optional libglib2.0-bin
    fi
    if ! command_exists glib-compile-schemas 2>/dev/null; then
        log_warn "glib-compile-schemas no disponible; algunas extensiones (ej. Caffeine) pueden fallar al abrir preferencias"
        return 0
    fi
    local ext_dir="$HOME/.local/share/gnome-shell/extensions"
    for ext in "${USER_EXTENSIONS[@]}"; do
        local schemas_dir="${ext_dir}/${ext}/schemas"
        if [[ -d "$schemas_dir" ]] && compgen -G "${schemas_dir}/*.gschema.xml" >/dev/null 2>&1; then
            log_info "Compilando esquemas: $ext"
            glib-compile-schemas "$schemas_dir" 2>/dev/null || log_warn "No se pudo compilar esquemas de $ext"
        fi
    done
}

# Set Caffeine default: active (on) with timer "Infinite".
# Index 3 = Infinite in the quick settings duration list (0=15m, 1=30m, 2=1h, 3=Infinite).
# GSETTINGS_SCHEMA_DIR is needed so gsettings finds the extension schema in ~/.local.
set_caffeine_defaults() {
    local ext_dir="$HOME/.local/share/gnome-shell/extensions"
    local ext="caffeine@patapon.info"
    local schemas_dir="${ext_dir}/${ext}/schemas"
    if [[ ! -d "$schemas_dir" ]]; then
        return 0
    fi
    log_subsection "Configurando Caffeine (activado + Infinite)"
    if command_exists gsettings 2>/dev/null; then
        export GSETTINGS_SCHEMA_DIR="$schemas_dir"
        if gsettings set org.gnome.shell.extensions.caffeine user-enabled true 2>/dev/null && \
           gsettings set org.gnome.shell.extensions.caffeine duration-timer 3 2>/dev/null; then
            log_info "Caffeine: activado por defecto, temporizador Infinite"
        else
            log_warn "No se pudo aplicar la configuracion por defecto de Caffeine (puede requerir reiniciar GNOME)"
        fi
        unset GSETTINGS_SCHEMA_DIR
    else
        log_warn "gsettings no disponible; Caffeine no se configurara por defecto"
    fi
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

# Apply saved extension state (enabled/disabled) and configs from dconf backup.
# Run after installing and enabling extensions so backup overwrites with desired state.
apply_extension_state_from_backup() {
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    local backup_file="${script_dir}/config/dconf-gnome.ini"
    if [[ ! -f "$backup_file" ]]; then
        return 0
    fi
    if ! command -v dconf &>/dev/null; then
        return 0
    fi
    log_subsection "Aplicando estado guardado de extensiones (activadas/desactivadas y configuraciones)"
    if dconf load /org/gnome/ < "$backup_file" 2>/dev/null; then
        log_info "Estado de extensiones aplicado desde config/dconf-gnome.ini"
    else
        log_warn "Error al aplicar backup dconf (extensiones); revisa config/dconf-gnome.ini"
    fi
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
    compile_extension_schemas
    set_caffeine_defaults
    enable_user_extensions
    enable_system_extensions
    apply_extension_state_from_backup

    # If extensions are on disk but not visible, the shell has not rescanned yet.
    # On X11 we can restart the shell so it rescans; then retry enable.
    local need_retry="false"
    for ext in "${USER_EXTENSIONS[@]}" "${SYSTEM_EXTENSIONS[@]}"; do
        if extension_on_disk "$ext" && ! extension_visible_to_shell "$ext"; then
            need_retry="true"
            break
        fi
    done
    if [[ "$need_retry" == "true" ]] && [[ "${XDG_SESSION_TYPE:-}" == "x11" ]]; then
        log_info "Reiniciando GNOME Shell para que detecte las extensiones instaladas (X11)..."
        killall -HUP gnome-shell 2>/dev/null || true
        sleep 10
        log_subsection "Habilitando extensiones (segundo intento tras reinicio del shell)"
        for ext in "${USER_EXTENSIONS[@]}" "${SYSTEM_EXTENSIONS[@]}"; do
            extension_on_disk "$ext" || continue
            extension_visible_to_shell "$ext" || continue
            log_info "Habilitando: $ext"
            gnome-extensions enable "$ext" 2>&1 || log_warn "No se pudo habilitar $ext"
        done
    fi
    if [[ "$need_retry" == "true" ]] && [[ "${XDG_SESSION_TYPE:-}" != "x11" ]]; then
        log_warn "En Wayland: cierra sesion y vuelve a entrar, luego ejecuta: ./install.sh gnome (para habilitar las extensiones)"
    else
        log_warn "Puede ser necesario cerrar sesion y volver a entrar para que las extensiones se activen completamente"
    fi
}
