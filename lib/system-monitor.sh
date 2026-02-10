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
    local src_icon="${script_dir}/SystemMonitor.png"
    local dest_script="$HOME/.local/bin/SystemMonitor.sh"
    local dest_icon="$HOME/.local/share/icons/SystemMonitor.png"
    local dest_desktop="$HOME/.local/share/applications/system-monitor-tmux.desktop"

    # Verificar que los archivos fuente existen
    if [[ ! -f "$src_script" ]]; then
        log_error "No se encontro SystemMonitor.sh en $script_dir"
        return 1
    fi

    # Crear directorios destino
    ensure_dir "$HOME/.local/bin"
    ensure_dir "$HOME/.local/share/icons"
    ensure_dir "$HOME/.local/share/applications"

    # Copiar script
    log_subsection "Copiando SystemMonitor.sh"
    cp "$src_script" "$dest_script"
    chmod +x "$dest_script"
    log_info "SystemMonitor.sh copiado a $dest_script"

    # Copiar icono si existe
    if [[ -f "$src_icon" ]]; then
        cp "$src_icon" "$dest_icon"
        log_info "Icono copiado a $dest_icon"
    fi

    # Crear .desktop file
    log_subsection "Creando .desktop file"
    cat > "$dest_desktop" << DESKTOP
[Desktop Entry]
Name=System Monitor (tmux)
Comment=Dashboard de monitorizacion del sistema con tmux
Exec=gnome-terminal -- bash -c '${dest_script}; exec bash'
Icon=${dest_icon}
Terminal=false
Type=Application
Categories=System;Monitor;
DESKTOP

    update-desktop-database "$HOME/.local/share/applications/" 2>/dev/null || true
    log_info "SystemMonitor configurado con .desktop file"
}
