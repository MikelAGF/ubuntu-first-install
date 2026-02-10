#!/bin/bash
# =============================================================================
# dev-tools.sh - Node.js (via n), npm global packages, Python3
# =============================================================================

NPM_GLOBALS=(
    typescript
    ts-node
    turbo
    nativefier
)

setup_nodejs() {
    log_subsection "Node.js via n"

    if command_exists node && command_exists n; then
        log_info "Node.js ya esta instalado ($(node --version)) con n"
        return 0
    fi

    # Instalar nodejs y npm desde apt como bootstrap
    apt_install nodejs npm

    # Instalar n (Node version manager)
    log_info "Instalando n (Node version manager)..."
    sudo npm install -g n

    # Instalar la version LTS de Node.js usando n
    log_info "Instalando Node.js LTS via n..."
    sudo n lts

    # Rehash del PATH para usar la nueva version
    hash -r 2>/dev/null || true

    log_info "Node.js instalado: $(node --version 2>/dev/null || echo 'pendiente de rehash')"
}

install_npm_globals() {
    log_subsection "Paquetes NPM globales"

    for pkg in "${NPM_GLOBALS[@]}"; do
        log_info "Instalando npm global: $pkg"
        sudo npm install -g "$pkg" 2>&1 || log_warn "No se pudo instalar npm global: $pkg"
    done

    log_info "Paquetes NPM globales instalados"
}

# -----------------------------------------------------------------------------
# Funcion principal
# -----------------------------------------------------------------------------
setup_dev_tools() {
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log_info "[DRY-RUN] Instalaria:"
        log_info "  - Node.js LTS via n"
        log_info "  - NPM globals: ${NPM_GLOBALS[*]}"
        return 0
    fi

    setup_nodejs
    install_npm_globals
}
