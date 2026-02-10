#!/bin/bash
# =============================================================================
# post-config.sh - Configuracion post-instalacion
# =============================================================================

configure_docker_group() {
    log_subsection "Anadiendo usuario al grupo docker"
    if groups "$USER" | grep -q docker; then
        log_info "Usuario $USER ya esta en el grupo docker"
        return 0
    fi
    sudo usermod -aG docker "$USER"
    log_info "Usuario $USER anadido al grupo docker (requiere cerrar sesion)"
}

enable_services() {
    log_subsection "Habilitando servicios"

    if is_installed docker.io; then
        sudo systemctl enable docker
        sudo systemctl start docker
        log_info "Servicio docker habilitado e iniciado"
    fi
}

configure_git_lfs() {
    log_subsection "Configurando Git LFS"
    if command_exists git-lfs; then
        git lfs install
        log_info "Git LFS configurado"
    fi
}

# -----------------------------------------------------------------------------
# Funcion principal
# -----------------------------------------------------------------------------
run_post_config() {
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log_info "[DRY-RUN] Post-configuracion:"
        log_info "  - Anadir usuario al grupo docker"
        log_info "  - Habilitar servicio docker"
        log_info "  - Configurar Git LFS"
        return 0
    fi

    configure_docker_group
    enable_services
    configure_git_lfs
}
