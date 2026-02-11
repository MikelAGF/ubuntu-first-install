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

cleanup_system() {
    log_subsection "Limpieza del sistema"

    log_info "Eliminando paquetes huerfanos..."
    sudo apt autoremove -y 2>&1 | grep -v "^Reading" || true

    log_info "Limpiando cache de apt..."
    sudo apt autoclean 2>&1 | grep -v "^Reading" || true
    sudo apt clean 2>&1 || true

    log_info "Limpiando cache de snap..."
    sudo snap list --all | awk '/disabled/{print $1, $3}' | while read snapname revision; do
        sudo snap remove "$snapname" --revision="$revision" 2>&1 || true
    done

    log_info "Sistema limpio"
}

verify_installation() {
    log_subsection "Verificacion post-instalacion"

    local failed=0

    # Verificar servicios criticos
    if systemctl is-active --quiet docker; then
        log_info "✓ Docker activo"
    else
        if is_installed docker.io; then
            log_warn "✗ Docker instalado pero no activo"
            failed=$((failed + 1))
        fi
    fi

    # Verificar comandos importantes
    local commands=("node" "npm" "python3" "git" "gh" "pyenv" "cursor")
    for cmd in "${commands[@]}"; do
        if command_exists "$cmd"; then
            local version=$(eval "$cmd --version 2>/dev/null | head -n1" || echo "instalado")
            log_info "✓ $cmd: $version"
        fi
    done

    # Verificar extensiones GNOME instaladas
    if command_exists gnome-extensions; then
        local ext_count=$(gnome-extensions list 2>/dev/null | wc -l)
        log_info "✓ Extensiones GNOME: $ext_count instaladas"
    fi

    if [[ $failed -gt 0 ]]; then
        log_warn "Verificacion completada con $failed advertencias"
    else
        log_info "Verificacion completada: todo OK"
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
        log_info "  - Limpiar sistema (apt autoremove, cache)"
        log_info "  - Verificar instalacion"
        return 0
    fi

    configure_docker_group
    enable_services
    configure_git_lfs
    cleanup_system
    verify_installation
}
