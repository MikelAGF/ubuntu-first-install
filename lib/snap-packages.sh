#!/bin/bash
# =============================================================================
# snap-packages.sh - Instalacion de paquetes Snap
# =============================================================================

install_all_snaps() {
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log_info "[DRY-RUN] Instalaria los siguientes snaps:"
        log_info "  - keepassxc"
        log_info "  - discord"
        log_info "  - spotify"
        return 0
    fi

    log_subsection "KeePassXC"
    snap_install keepassxc

    log_subsection "Discord"
    snap_install discord

    log_subsection "Spotify"
    snap_install spotify
}
