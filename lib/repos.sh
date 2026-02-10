#!/bin/bash
# =============================================================================
# repos.sh - Configuracion de PPAs, repositorios y GPG keys
# =============================================================================

setup_google_chrome_repo() {
    log_subsection "Google Chrome"
    if [[ -f /etc/apt/sources.list.d/google-chrome.list ]]; then
        log_info "Repo de Google Chrome ya configurado"
        return 0
    fi
    sudo rm -f /etc/apt/trusted.gpg.d/google-chrome.gpg
    wget -q -O - https://dl.google.com/linux/linux_signing_key.pub \
        | sudo gpg --batch --yes --dearmor -o /etc/apt/trusted.gpg.d/google-chrome.gpg
    echo "deb [arch=amd64 signed-by=/etc/apt/trusted.gpg.d/google-chrome.gpg] https://dl.google.com/linux/chrome/deb/ stable main" \
        | sudo tee /etc/apt/sources.list.d/google-chrome.list > /dev/null
    log_info "Repo de Google Chrome anadido"
}

setup_sublime_text_repo() {
    log_subsection "Sublime Text"
    if [[ -f /etc/apt/sources.list.d/sublime-text.list ]]; then
        log_info "Repo de Sublime Text ya configurado"
        return 0
    fi
    sudo rm -f /usr/share/keyrings/sublimehq-archive-keyring.gpg
    wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg \
        | sudo gpg --batch --yes --dearmor -o /usr/share/keyrings/sublimehq-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/sublimehq-archive-keyring.gpg] https://download.sublimetext.com/ apt/stable/" \
        | sudo tee /etc/apt/sources.list.d/sublime-text.list > /dev/null
    log_info "Repo de Sublime Text anadido"
}

setup_grub_customizer_ppa() {
    log_subsection "GRUB Customizer PPA"
    if ls /etc/apt/sources.list.d/ | grep -q "danielrichter2007.*grub-customizer"; then
        log_info "PPA de GRUB Customizer ya configurado"
        return 0
    fi
    sudo add-apt-repository -y ppa:danielrichter2007/grub-customizer
    log_info "PPA de GRUB Customizer anadido"
}

setup_obs_studio_ppa() {
    log_subsection "OBS Studio PPA"
    if ls /etc/apt/sources.list.d/ | grep -q "obsproject.*obs-studio"; then
        log_info "PPA de OBS Studio ya configurado"
        return 0
    fi
    sudo add-apt-repository -y ppa:obsproject/obs-studio
    log_info "PPA de OBS Studio anadido"
}

setup_graphics_drivers_ppa() {
    log_subsection "Graphics Drivers PPA"
    if ls /etc/apt/sources.list.d/ | grep -q "graphics-drivers"; then
        log_info "PPA de Graphics Drivers ya configurado"
        return 0
    fi
    sudo add-apt-repository -y ppa:graphics-drivers/ppa
    log_info "PPA de Graphics Drivers anadido"
}

setup_azure_cli_repo() {
    log_subsection "Azure CLI"
    sudo mkdir -p /etc/apt/keyrings
    sudo rm -f /etc/apt/keyrings/microsoft.gpg
    curl -sLS https://packages.microsoft.com/keys/microsoft.asc \
        | sudo gpg --batch --yes --dearmor -o /etc/apt/keyrings/microsoft.gpg
    sudo chmod go+r /etc/apt/keyrings/microsoft.gpg

    AZ_DIST=$(lsb_release -cs)
    echo "Types: deb
URIs: https://packages.microsoft.com/repos/azure-cli/
Suites: ${AZ_DIST}
Components: main
Architectures: amd64
Signed-By: /etc/apt/keyrings/microsoft.gpg" \
        | sudo tee /etc/apt/sources.list.d/azure-cli.sources > /dev/null
    log_info "Repo de Azure CLI configurado"
}

setup_gcloud_sdk_repo() {
    log_subsection "Google Cloud SDK"
    sudo mkdir -p /usr/share/keyrings
    sudo rm -f /usr/share/keyrings/cloud.google.gpg
    curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg \
        | sudo gpg --batch --yes --dearmor -o /usr/share/keyrings/cloud.google.gpg
    sudo chmod 644 /usr/share/keyrings/cloud.google.gpg 2>/dev/null || true
    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" \
        | sudo tee /etc/apt/sources.list.d/google-cloud-sdk.list > /dev/null
    log_info "Repo de Google Cloud SDK configurado"
}

setup_master_pdf_editor_repo() {
    log_subsection "Master PDF Editor"
    sudo mkdir -p /etc/apt/keyrings
    sudo rm -f /etc/apt/keyrings/pubmpekey.gpg
    wget -q -O - http://repo.code-industry.net/deb/pubmpekey.asc \
        | sudo gpg --batch --yes --dearmor -o /etc/apt/keyrings/pubmpekey.gpg 2>/dev/null
    sudo chmod 644 /etc/apt/keyrings/pubmpekey.gpg 2>/dev/null || true
    echo "deb [signed-by=/etc/apt/keyrings/pubmpekey.gpg arch=$(dpkg --print-architecture)] http://repo.code-industry.net/deb stable main" \
        | sudo tee /etc/apt/sources.list.d/master-pdf-editor.list > /dev/null
    log_info "Repo de Master PDF Editor configurado"
}

setup_anydesk_repo() {
    log_subsection "AnyDesk"
    if [[ -f /etc/apt/sources.list.d/anydesk-stable.list ]]; then
        log_info "Repo de AnyDesk ya configurado"
        return 0
    fi
    sudo mkdir -p /etc/apt/keyrings
    sudo curl -fsSL https://keys.anydesk.com/repos/DEB-GPG-KEY -o /etc/apt/keyrings/keys.anydesk.com.asc
    sudo chmod a+r /etc/apt/keyrings/keys.anydesk.com.asc
    echo "deb [signed-by=/etc/apt/keyrings/keys.anydesk.com.asc] https://deb.anydesk.com all main" \
        | sudo tee /etc/apt/sources.list.d/anydesk-stable.list > /dev/null
    log_info "Repo de AnyDesk anadido"
}

# -----------------------------------------------------------------------------
# Funcion principal: configurar todos los repos
# -----------------------------------------------------------------------------
setup_all_repos() {
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log_info "[DRY-RUN] Configuraria los siguientes repos:"
        log_info "  - Google Chrome"
        log_info "  - Sublime Text"
        log_info "  - GRUB Customizer PPA"
        log_info "  - OBS Studio PPA"
        log_info "  - Graphics Drivers PPA"
        log_info "  - Azure CLI"
        log_info "  - Google Cloud SDK"
        log_info "  - Master PDF Editor"
        log_info "  - AnyDesk"
        return 0
    fi

    setup_google_chrome_repo
    setup_sublime_text_repo
    setup_grub_customizer_ppa
    setup_obs_studio_ppa
    setup_graphics_drivers_ppa
    setup_azure_cli_repo
    setup_gcloud_sdk_repo
    setup_master_pdf_editor_repo
    setup_anydesk_repo

    log_info "Actualizando indices de paquetes..."
    sudo apt-get update || true
    log_info "Todos los repos configurados"
}
