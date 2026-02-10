#!/bin/bash
# =============================================================================
# dconf-settings.sh - Restore GNOME/dconf settings (keybindings, theme, keyboard, etc.)
# =============================================================================
# Backup is created by running export-my-settings.sh on your current Ubuntu.
# Restore runs during install if config/dconf-gnome.ini exists.
# =============================================================================

# Path to the dconf backup file (relative to repo root)
DCONF_BACKUP_REL="config/dconf-gnome.ini"

# -----------------------------------------------------------------------------
# Restore dconf from backup file
# -----------------------------------------------------------------------------
restore_dconf_settings() {
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    local backup_file="${script_dir}/${DCONF_BACKUP_REL}"

    if [[ ! -f "$backup_file" ]]; then
        log_warn "No hay backup de dconf en ${DCONF_BACKUP_REL}. Ejecuta ./export-my-settings.sh en tu Ubuntu actual y anade el archivo al repo."
        return 0
    fi

    if ! command -v dconf &>/dev/null; then
        log_warn "dconf no encontrado; no se puede restaurar la configuracion GNOME."
        return 0
    fi

    log_subsection "Restaurando configuracion GNOME (dconf)"
    # File was created with "dconf dump /org/gnome/" so it contains [org/gnome/...]; load at root
    if dconf load / < "$backup_file" 2>/dev/null; then
        log_info "Configuracion dconf restaurada desde ${DCONF_BACKUP_REL}"
    else
        log_warn "Error al cargar dconf (puede haber claves incompatibles). Revisa ${DCONF_BACKUP_REL}."
        return 1
    fi
}

# -----------------------------------------------------------------------------
# Main entry: run during install
# -----------------------------------------------------------------------------
run_dconf_restore() {
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log_info "[DRY-RUN] Restauraria configuracion dconf desde config/dconf-gnome.ini si existe"
        return 0
    fi

    if [[ -z "${XDG_CURRENT_DESKTOP:-}" ]] || [[ "$XDG_CURRENT_DESKTOP" != *"GNOME"* ]]; then
        log_warn "No se detecto sesion GNOME. Restaurar dconf en una sesion grafica GNOME para que aplique bien."
    fi

    restore_dconf_settings
}
