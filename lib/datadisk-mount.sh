#!/bin/bash
# =============================================================================
# datadisk-mount.sh - Automatizar montaje del DataDisk NTFS en fstab
# =============================================================================
# Configura /etc/fstab para montar la particion NTFS al arranque con
# remove_hiberfile (limpia bloqueo de hibernacion de Windows).
# =============================================================================

# Device and mount point (override with env: DATADISK_DEV)
DATADISK_DEV="${DATADISK_DEV:-/dev/sda2}"
DATADISK_MOUNT="/media/${USER}/DataDisk"

setup_datadisk_fstab() {
    log_subsection "Montaje automatico DataDisk (fstab)"

    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log_info "[DRY-RUN] Comprobando $DATADISK_DEV, anadiendo linea a /etc/fstab si procede"
        return 0
    fi

    if [[ ! -b "$DATADISK_DEV" ]]; then
        log_warn "Disco $DATADISK_DEV no encontrado; omitiendo configuracion DataDisk"
        return 0
    fi

    local uuid
    uuid=$(sudo blkid -s UUID -o value "$DATADISK_DEV" 2>/dev/null)
    if [[ -z "$uuid" ]]; then
        log_warn "No se pudo obtener UUID de $DATADISK_DEV; omitiendo DataDisk"
        return 0
    fi

    # Ensure ntfs-3g is available
    if ! is_installed ntfs-3g 2>/dev/null; then
        log_info "Instalando ntfs-3g..."
        apt_install_optional ntfs-3g
    fi

    sudo mkdir -p "$DATADISK_MOUNT"
    log_info "Punto de montaje: $DATADISK_MOUNT"

    if sudo grep -q "$DATADISK_MOUNT" /etc/fstab 2>/dev/null; then
        log_info "DataDisk ya esta en /etc/fstab; no se anade nada"
        return 0
    fi

    if sudo grep -q "UUID=$uuid" /etc/fstab 2>/dev/null; then
        log_info "UUID $uuid ya esta en /etc/fstab; no se anade nada"
        return 0
    fi

    local fstab_line="UUID=$uuid $DATADISK_MOUNT ntfs-3g defaults,rw,remove_hiberfile 0 0"
    echo "$fstab_line" | sudo tee -a /etc/fstab >/dev/null
    log_info "Anadida linea a /etc/fstab: UUID=$uuid -> $DATADISK_MOUNT (remove_hiberfile)"
}

run_datadisk_mount() {
    log_section "DataDisk - Montaje automatico (fstab)"
    setup_datadisk_fstab
}
