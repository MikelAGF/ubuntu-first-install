#!/bin/bash
# =============================================================================
# apt-packages.sh - Instalacion de paquetes APT organizados por categoria
# =============================================================================

install_core_utilities() {
    log_subsection "Utilidades core"
    apt_install \
        curl \
        wget \
        p7zip-full \
        p7zip-rar \
        zip \
        unzip \
        ffmpeg \
        net-tools \
        software-properties-common \
        apt-transport-https \
        ca-certificates \
        gnupg \
        lsb-release
}

install_development_tools() {
    log_subsection "Herramientas de desarrollo"
    apt_install \
        build-essential \
        cmake \
        pkg-config \
        git \
        git-lfs \
        python3 \
        python3-pip \
        python3-venv
}

install_system_monitoring() {
    log_subsection "Herramientas de monitorizacion"
    apt_install \
        htop \
        nvtop \
        powertop \
        iotop \
        lm-sensors \
        intel-gpu-tools \
        tmux
}

install_browser() {
    log_subsection "Navegador"
    apt_install google-chrome-stable
}

install_productivity() {
    log_subsection "Productividad"
    apt_install libreoffice baobab sublime-text
    apt_install_optional master-pdf-editor-5
}

install_media() {
    log_subsection "Media"
    apt_install \
        vlc \
        obs-studio
}

install_virtualization() {
    log_subsection "Virtualizacion"
    # Remove stale crash report so DKMS postinst does not fail with "File exists"
    sudo rm -f /var/crash/virtualbox-dkms*.crash 2>/dev/null || true
    log_info "Instalando linux-headers para DKMS..."
    if ! all_packages_installed linux-headers-"$(uname -r)" 2>/dev/null; then
        sudo apt-get install -y linux-headers-"$(uname -r)" 2>/dev/null \
            || sudo apt-get install -y linux-headers-generic 2>/dev/null || true
    fi
    if ! apt_install virtualbox virtualbox-dkms; then
        sudo dpkg --configure -a 2>/dev/null || true
        log_warn "VirtualBox no se pudo instalar (p. ej. DKMS o kernel). Puedes instalarlo manualmente mas tarde con: sudo apt install virtualbox virtualbox-dkms"
        return 0
    fi
}

install_docker() {
    log_subsection "Docker"
    apt_install \
        docker.io \
        docker-compose-v2
}

install_gnome_tools() {
    log_subsection "Herramientas GNOME"
    apt_install \
        gnome-tweaks \
        chrome-gnome-shell \
        gnome-shell-extensions \
        gnome-shell-extension-prefs
}

install_grub_customizer() {
    log_subsection "GRUB Customizer"
    apt_install grub-customizer
}

install_cloud_tools() {
    log_subsection "Herramientas Cloud"
    apt_install_optional azure-cli
    apt_install_optional google-cloud-cli
}

install_remote_tools() {
    log_subsection "Herramientas remotas"
    apt_install_optional anydesk
}

install_fonts() {
    log_subsection "Fuentes"
    apt_install \
        fonts-noto-core \
        fonts-noto-cjk \
        fonts-noto-color-emoji \
        fonts-noto-mono \
        fonts-liberation \
        fonts-dejavu-core \
        fonts-dejavu-extra \
        fonts-wqy-zenhei
}

install_vpn_plugins() {
    log_subsection "Plugins VPN"
    apt_install \
        network-manager-openvpn \
        network-manager-openvpn-gnome
}

# -----------------------------------------------------------------------------
# Funcion principal: instalar todos los paquetes APT
# -----------------------------------------------------------------------------
install_all_apt_packages() {
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log_info "[DRY-RUN] Instalaria paquetes APT de las siguientes categorias:"
        log_info "  - Utilidades core"
        log_info "  - Herramientas de desarrollo"
        log_info "  - Monitorizacion"
        log_info "  - Navegador (Chrome)"
        log_info "  - Productividad (LibreOffice, Baobab, Sublime, Master PDF)"
        log_info "  - Media (VLC, OBS)"
        log_info "  - Virtualizacion (VirtualBox)"
        log_info "  - Docker"
        log_info "  - GNOME tools"
        log_info "  - GRUB Customizer"
        log_info "  - Cloud (Azure CLI, GCloud)"
        log_info "  - Anydesk"
        log_info "  - Fuentes"
        log_info "  - Plugins VPN"
        return 0
    fi
    # Ensure crash file is gone before any apt run (e.g. when running only --section apt)
    sudo rm -f /var/crash/virtualbox-dkms*.crash 2>/dev/null || true
    # Refresh indices so packages from fixed repos are available
    log_info "Actualizando indices de paquetes (apt-get update)..."
    sudo apt-get update -qq 2>/dev/null || true

    install_core_utilities
    install_development_tools
    install_system_monitoring
    install_browser
    install_productivity
    install_media
    install_virtualization
    install_docker
    install_gnome_tools
    install_grub_customizer
    install_cloud_tools
    install_remote_tools
    install_fonts
    install_vpn_plugins
}
