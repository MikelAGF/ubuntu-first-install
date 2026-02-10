#!/bin/bash
# =============================================================================
# system-monitor.sh - Instalacion de SystemMonitor.sh con .desktop file
# =============================================================================

setup_system_monitor() {
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log_info "[DRY-RUN] Instalaria SystemMonitor.sh en ~/.local/bin/ con .desktop file"
        return 0
    fi

    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

    local src_script="${script_dir}/SystemMonitor.sh"
    local src_launcher="${script_dir}/SystemMonitor-launch.sh"
    local src_icon="${script_dir}/SystemMonitor.png"
    local dest_script="$HOME/.local/bin/SystemMonitor.sh"
    local dest_launcher="$HOME/.local/bin/SystemMonitor-launch.sh"
    local dest_icon="$HOME/.local/share/icons/SystemMonitor.png"
    local dest_desktop="$HOME/.local/share/applications/system-monitor-tmux.desktop"

    if [[ ! -f "$src_script" ]]; then
        log_error "No se encontro SystemMonitor.sh en $script_dir"
        return 1
    fi
    if [[ ! -f "$src_launcher" ]]; then
        log_error "No se encontro SystemMonitor-launch.sh en $script_dir"
        return 1
    fi

    # Crear directorios destino
    ensure_dir "$HOME/.local/bin"
    ensure_dir "$HOME/.local/share/icons"
    ensure_dir "$HOME/.local/share/applications"

    # wmctrl + xdotool used by the launcher to resize window to 70% on X11
    apt_install_optional wmctrl xdotool

    log_subsection "Copiando SystemMonitor.sh"
    cp "$src_script" "$dest_script"
    chmod +x "$dest_script"
    log_info "SystemMonitor.sh copiado a $dest_script"

    log_subsection "Copiando SystemMonitor-launch.sh"
    cp "$src_launcher" "$dest_launcher"
    chmod +x "$dest_launcher"
    log_info "Launcher copiado a $dest_launcher (abre ventana al 70% en X11)"

    if [[ -f "$src_icon" ]]; then
        cp "$src_icon" "$dest_icon"
        log_info "Icono copiado a $dest_icon"
    fi

    # Create .desktop file
    # Use --class + StartupWMClass so the dock shows this app's icon instead of Terminal (X11).
    # Icon=SystemMonitor (no path) so the system resolves it from ~/.local/share/icons/
    log_subsection "Creando .desktop file"
    cat > "$dest_desktop" << DESKTOP
[Desktop Entry]
Name=System Monitor (tmux)
Comment=Dashboard de monitorizacion del sistema con tmux
Exec=${dest_launcher}
Icon=SystemMonitor
StartupWMClass=SystemMonitor
Terminal=false
Type=Application
Categories=System;Monitor;
DESKTOP

    update-desktop-database "$HOME/.local/share/applications/" 2>/dev/null || true

    # NOPASSWD for powertop, sensors, iotop so the dashboard does not prompt for password
    log_subsection "Configurando sudo sin contraseña para powertop, sensors, iotop"
    local target_user="${SUDO_USER:-$USER}"
    local sudoers_file="/etc/sudoers.d/system-monitor-nopasswd"
    local paths_powertop paths_sensors paths_iotop
    paths_powertop="$(command -v powertop 2>/dev/null || echo "/usr/sbin/powertop")"
    paths_sensors="$(command -v sensors 2>/dev/null || echo "/usr/bin/sensors")"
    paths_iotop="$(command -v iotop 2>/dev/null || echo "/usr/sbin/iotop")"
    if [[ -n "$target_user" ]]; then
        if sudo tee "$sudoers_file" >/dev/null << SUDOERS
# Allow system-monitor dashboard to run these without password (ubuntu-first-install)
$target_user ALL=(ALL) NOPASSWD: $paths_powertop, $paths_sensors, $paths_iotop
SUDOERS
        then
            sudo chmod 0440 "$sudoers_file"
            if sudo visudo -c -f "$sudoers_file" 2>/dev/null; then
                log_info "Sudoers configurado: powertop, sensors, iotop sin contraseña para $target_user"
            else
                log_warn "No se pudo validar $sudoers_file; revísalo con visudo"
                sudo rm -f "$sudoers_file"
            fi
        else
            log_warn "No se pudo crear $sudoers_file (se pedirá sudo al usar powertop/sensors/iotop)"
        fi
    fi

    log_info "SystemMonitor configurado con .desktop file"
}
