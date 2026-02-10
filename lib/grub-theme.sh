#!/bin/bash
# =============================================================================
# grub-theme.sh - Instalacion del tema GRUB Tela y configuracion
# =============================================================================

install_grub_tela_theme() {
    log_subsection "Instalando tema GRUB Tela"

    if [[ -f /boot/grub/themes/Tela/theme.txt ]]; then
        log_info "Tema GRUB Tela ya esta instalado"
        return 0
    fi

    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    local theme_src="${script_dir}/grub-theme-tela"

    # Usar la copia local del tema incluida en el repo
    if [[ -d "$theme_src" ]] && [[ -f "$theme_src/theme.txt" ]]; then
        log_info "Copiando tema Tela desde copia local del proyecto..."
        sudo mkdir -p /boot/grub/themes/Tela
        sudo cp -r "$theme_src"/* /boot/grub/themes/Tela/
    else
        # Fallback: descargar del repo oficial de GitHub
        log_warn "Copia local del tema no encontrada, descargando del repo oficial..."
        local temp_dir
        temp_dir=$(mktemp -d)

        git clone --depth=1 https://github.com/vinceliuice/grub2-themes.git "$temp_dir/grub2-themes"
        cd "$temp_dir/grub2-themes" || return 1
        sudo ./install.sh -t tela -s 2k
        cd - > /dev/null || true
        rm -rf "$temp_dir"
    fi

    if [[ -f /boot/grub/themes/Tela/theme.txt ]]; then
        log_info "Tema GRUB Tela instalado correctamente"
    else
        log_error "No se encontro theme.txt tras la instalacion"
        return 1
    fi
}

configure_grub() {
    log_subsection "Configurando GRUB"

    local grub_file="/etc/default/grub"
    backup_file "$grub_file"

    # Funcion helper para establecer un valor en GRUB
    set_grub_value() {
        local key="$1"
        local value="$2"
        if grep -q "^${key}=" "$grub_file"; then
            sudo sed -i "s|^${key}=.*|${key}=\"${value}\"|" "$grub_file"
        else
            echo "${key}=\"${value}\"" | sudo tee -a "$grub_file" > /dev/null
        fi
    }

    set_grub_value "GRUB_THEME" "/boot/grub/themes/Tela/theme.txt"
    set_grub_value "GRUB_GFXMODE" "2560x1440"
    set_grub_value "GRUB_TIMEOUT" "20"
    set_grub_value "GRUB_TIMEOUT_STYLE" "menu"

    log_info "Ejecutando update-grub..."
    sudo update-grub

    log_info "GRUB configurado correctamente"
}

# -----------------------------------------------------------------------------
# Funcion principal
# -----------------------------------------------------------------------------
setup_grub() {
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log_info "[DRY-RUN] Instalaria tema GRUB Tela y configuraria:"
        log_info "  GRUB_THEME=/boot/grub/themes/Tela/theme.txt"
        log_info "  GRUB_GFXMODE=2560x1440"
        log_info "  GRUB_TIMEOUT=20"
        log_info "  GRUB_TIMEOUT_STYLE=menu"
        return 0
    fi

    install_grub_tela_theme
    configure_grub
}
