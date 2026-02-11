#!/bin/bash
# =============================================================================
# dev-tools.sh - Node.js (via n), npm global packages, Python3, pyenv, GitHub CLI
# =============================================================================

NPM_GLOBALS=(
    typescript
    ts-node
    turbo
    nativefier
)

PYENV_INSTALL_URL="https://pyenv.run"

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

setup_pyenv() {
    log_subsection "pyenv (gestor de versiones Python)"

    if command_exists pyenv; then
        log_info "pyenv ya esta instalado ($(pyenv --version))"
        return 0
    fi

    # Instalar dependencias necesarias para compilar Python
    log_info "Instalando dependencias de pyenv..."
    apt_install \
        make \
        build-essential \
        libssl-dev \
        zlib1g-dev \
        libbz2-dev \
        libreadline-dev \
        libsqlite3-dev \
        wget \
        curl \
        llvm \
        libncursesw5-dev \
        xz-utils \
        tk-dev \
        libxml2-dev \
        libxmlsec1-dev \
        libffi-dev \
        liblzma-dev

    # Instalar pyenv
    log_info "Instalando pyenv..."
    curl -fsSL "$PYENV_INSTALL_URL" | bash

    # Configurar PATH en .bashrc si no existe
    local bashrc="$HOME/.bashrc"
    if ! grep -q 'PYENV_ROOT' "$bashrc" 2>/dev/null; then
        log_info "Configurando pyenv en .bashrc..."
        cat >> "$bashrc" << 'EOF'

# pyenv
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
EOF
    fi

    # Configurar PATH en .zshrc si existe
    local zshrc="$HOME/.zshrc"
    if [[ -f "$zshrc" ]] && ! grep -q 'PYENV_ROOT' "$zshrc" 2>/dev/null; then
        log_info "Configurando pyenv en .zshrc..."
        cat >> "$zshrc" << 'EOF'

# pyenv
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
EOF
    fi

    # Cargar pyenv en la sesion actual
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    if command_exists pyenv; then
        eval "$(pyenv init -)"
        log_info "pyenv instalado: $(pyenv --version)"
        log_warn "Reinicia tu terminal o ejecuta: source ~/.bashrc"
    else
        log_warn "pyenv instalado pero necesitas reiniciar terminal"
    fi
}

setup_github_cli() {
    log_subsection "GitHub CLI (gh)"

    if command_exists gh; then
        log_info "GitHub CLI ya esta instalado ($(gh --version | head -n1))"
        return 0
    fi

    # El repo de GitHub CLI ya deberia estar configurado en repos.sh
    # Si no esta, lo instalamos manualmente
    if ! is_installed gh; then
        log_info "Instalando GitHub CLI..."

        # Anadir repo oficial de GitHub CLI
        curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
        sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null

        sudo apt update
        apt_install gh
    fi

    if command_exists gh; then
        log_info "GitHub CLI instalado: $(gh --version | head -n1)"
        log_info "Autenticate con: gh auth login"
    fi
}

# -----------------------------------------------------------------------------
# Funcion principal
# -----------------------------------------------------------------------------
setup_dev_tools() {
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log_info "[DRY-RUN] Instalaria:"
        log_info "  - Node.js LTS via n"
        log_info "  - NPM globals: ${NPM_GLOBALS[*]}"
        log_info "  - pyenv (gestor de versiones Python)"
        log_info "  - GitHub CLI (gh)"
        return 0
    fi

    setup_nodejs
    install_npm_globals
    setup_pyenv
    setup_github_cli
}
