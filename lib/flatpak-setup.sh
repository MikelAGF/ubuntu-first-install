#!/bin/bash
# =============================================================================
# flatpak-setup.sh - Configuracion de Flatpak y Flathub
# =============================================================================

setup_flatpak() {
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log_info "[DRY-RUN] Instalaria Flatpak y configuraria Flathub"
        return 0
    fi

    log_subsection "Instalando Flatpak"
    apt_install flatpak gnome-software-plugin-flatpak

    log_subsection "Anadiendo Flathub"
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    log_info "Flatpak configurado con Flathub"
}
