#!/bin/bash
# =============================================================================
# system-optimization.sh - Optimizaciones del sistema (SSD, swap, snapshots)
# =============================================================================

setup_timeshift() {
    log_subsection "Timeshift (snapshots del sistema)"

    if is_installed timeshift; then
        log_info "Timeshift ya esta instalado"
        return 0
    fi

    apt_install timeshift

    if command_exists timeshift; then
        log_info "Timeshift instalado correctamente"
        log_info "Configura snapshots con: sudo timeshift-gtk"
        log_warn "Recomendado: Crear snapshot RSYNC en particion separada o disco externo"
    fi
}

optimize_ssd() {
    log_subsection "Optimizaciones SSD"

    # Verificar si hay SSD en el sistema
    local has_ssd=false
    while IFS= read -r disk; do
        if [[ "$(cat "/sys/block/$disk/queue/rotational" 2>/dev/null)" == "0" ]]; then
            has_ssd=true
            log_info "SSD detectado: $disk"
        fi
    done < <(lsblk -ndo NAME | grep -E '^(sd|nvme)')

    if [[ "$has_ssd" == "false" ]]; then
        log_info "No se detectaron SSD, omitiendo optimizaciones"
        return 0
    fi

    # Habilitar TRIM semanal
    if systemctl is-enabled fstrim.timer &>/dev/null; then
        log_info "fstrim.timer ya esta habilitado"
    else
        log_info "Habilitando TRIM semanal para SSD..."
        sudo systemctl enable fstrim.timer
        sudo systemctl start fstrim.timer
        log_info "TRIM habilitado (se ejecutara semanalmente)"
    fi

    # Verificar fstab para noatime (solo informativo)
    log_info "Verificando opciones de montaje..."
    if grep -q "noatime" /etc/fstab; then
        log_info "fstab ya usa 'noatime' en algunas particiones"
    else
        log_warn "Considera anadir 'noatime' a tus particiones SSD en /etc/fstab"
        log_warn "Ejemplo: UUID=xxx / ext4 defaults,noatime 0 1"
    fi
}

optimize_swap() {
    log_subsection "Optimizaciones de swap"

    # Ajustar swappiness para SSD (menos escrituras)
    local current_swappiness=$(cat /proc/sys/vm/swappiness)
    log_info "Swappiness actual: $current_swappiness"

    if grep -q "^vm.swappiness" /etc/sysctl.conf 2>/dev/null; then
        log_info "Swappiness ya configurado en /etc/sysctl.conf"
    else
        log_info "Configurando swappiness=10 (menos swap, mejor para SSD)..."
        echo "vm.swappiness=10" | sudo tee -a /etc/sysctl.conf > /dev/null
        sudo sysctl -p > /dev/null 2>&1 || true
        log_info "Swappiness configurado a 10"
    fi

    # Configurar zswap (compresion en RAM antes de swap)
    if grep -q "zswap.enabled=1" /etc/default/grub 2>/dev/null; then
        log_info "zswap ya esta habilitado"
    else
        log_info "Habilitando zswap (compresion de swap en RAM)..."
        sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/&zswap.enabled=1 /' /etc/default/grub
        sudo update-grub > /dev/null 2>&1 || true
        log_info "zswap habilitado (efectivo tras reinicio)"
        log_warn "Reinicia el sistema para activar zswap"
    fi

    # Informacion sobre swap actual
    local swap_info=$(swapon --show 2>/dev/null | tail -n +2)
    if [[ -n "$swap_info" ]]; then
        log_info "Swap actual:"
        echo "$swap_info" | while read -r line; do
            log_info "  $line"
        done
    else
        log_warn "No hay swap configurado"
    fi
}

# -----------------------------------------------------------------------------
# Funcion principal
# -----------------------------------------------------------------------------
setup_system_optimization() {
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log_info "[DRY-RUN] Optimizaciones del sistema:"
        log_info "  - Instalar Timeshift (snapshots)"
        log_info "  - Habilitar TRIM para SSD"
        log_info "  - Configurar swappiness=10"
        log_info "  - Habilitar zswap"
        return 0
    fi

    setup_timeshift
    optimize_ssd
    optimize_swap

    log_info "Optimizaciones del sistema completadas"
}
