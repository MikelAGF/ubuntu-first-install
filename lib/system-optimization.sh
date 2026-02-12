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

fix_chromium_crashes() {
    log_subsection "Fix para crashes de aplicaciones Chromium (Chrome, Cursor, VSCode, Discord)"

    # Ubuntu 24.04 introdujo restricciones de seguridad que impiden que aplicaciones
    # basadas en Chromium/Electron creen namespaces sin permiso explicito.
    # Esto causa crashes con error FATAL:zygote_host_impl_linux.cc

    local SYSCTL_CONF="/etc/sysctl.d/60-chromium-fix.conf"
    local NEEDS_REBOOT=false

    # Verificar si ya esta configurado
    if [[ -f "$SYSCTL_CONF" ]] && grep -q "kernel.unprivileged_userns_clone=1" "$SYSCTL_CONF"; then
        log_info "Fix de Chromium ya esta aplicado en $SYSCTL_CONF"
    else
        log_info "Aplicando fix para habilitar user namespaces..."
        echo 'kernel.unprivileged_userns_clone=1' | sudo tee "$SYSCTL_CONF" > /dev/null
        sudo sysctl -p "$SYSCTL_CONF" > /dev/null 2>&1 || true
        log_info "Fix aplicado: kernel.unprivileged_userns_clone=1"
        NEEDS_REBOOT=true
    fi

    # Verificar restricciones de AppArmor
    local apparmor_restrict=$(cat /proc/sys/kernel/apparmor_restrict_unprivileged_userns 2>/dev/null || echo "0")
    if [[ "$apparmor_restrict" != "0" ]]; then
        log_info "AppArmor esta restringiendo user namespaces, aplicando fix adicional..."
        if grep -q "^kernel.apparmor_restrict_unprivileged_userns=0" /etc/sysctl.conf 2>/dev/null; then
            log_info "Fix de AppArmor ya configurado en /etc/sysctl.conf"
        else
            echo "kernel.apparmor_restrict_unprivileged_userns=0" | sudo tee -a /etc/sysctl.conf > /dev/null
            sudo sysctl -w kernel.apparmor_restrict_unprivileged_userns=0 > /dev/null 2>&1 || true
            log_info "Fix de AppArmor aplicado"
            NEEDS_REBOOT=true
        fi
    else
        log_info "AppArmor no esta restringiendo user namespaces"
    fi

    if [[ "$NEEDS_REBOOT" == "true" ]]; then
        log_warn "Se recomienda reiniciar el sistema para aplicar completamente los cambios"
    fi

    log_info "Chrome, Cursor, VSCode, Discord y otras apps Chromium ya no deberian crashear"
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
        log_info "  - Fix para crashes de aplicaciones Chromium"
        return 0
    fi

    setup_timeshift
    optimize_ssd
    optimize_swap
    fix_chromium_crashes

    log_info "Optimizaciones del sistema completadas"
}
