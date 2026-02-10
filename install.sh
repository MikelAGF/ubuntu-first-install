#!/bin/bash
# =============================================================================
# install.sh - Script principal de instalacion de Ubuntu 24.04
# =============================================================================
# Uso:
#   ./install.sh                      # Ejecutar todo
#   ./install.sh --section repos      # Solo una seccion
#   ./install.sh --section apt,snaps  # Varias secciones (separadas por coma)
#   ./install.sh --list               # Listar secciones disponibles
#   ./install.sh --dry-run            # Ver que haria sin ejecutar
#   ./install.sh --dry-run --section repos  # Dry-run de una seccion
# =============================================================================

set -uo pipefail

# Directorio del script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Variables globales
DRY_RUN="${DRY_RUN:-false}"
SELECTED_SECTIONS=()

# -----------------------------------------------------------------------------
# Cargar modulos
# -----------------------------------------------------------------------------
source "${SCRIPT_DIR}/lib/utils.sh"
source "${SCRIPT_DIR}/lib/repos.sh"
source "${SCRIPT_DIR}/lib/apt-packages.sh"
source "${SCRIPT_DIR}/lib/snap-packages.sh"
source "${SCRIPT_DIR}/lib/flatpak-setup.sh"
source "${SCRIPT_DIR}/lib/dev-tools.sh"
source "${SCRIPT_DIR}/lib/cursor-ide.sh"
source "${SCRIPT_DIR}/lib/appimages.sh"
source "${SCRIPT_DIR}/lib/system-monitor.sh"
source "${SCRIPT_DIR}/lib/gnome-extensions.sh"
source "${SCRIPT_DIR}/lib/grub-theme.sh"
source "${SCRIPT_DIR}/lib/dconf-settings.sh"
source "${SCRIPT_DIR}/lib/post-config.sh"

# -----------------------------------------------------------------------------
# Definicion de secciones (orden de ejecucion)
# -----------------------------------------------------------------------------
declare -A SECTIONS
SECTIONS=(
    [repos]="setup_all_repos"
    [apt]="install_all_apt_packages"
    [snaps]="install_all_snaps"
    [flatpak]="setup_flatpak"
    [dev-tools]="setup_dev_tools"
    [cursor]="setup_cursor_ide"
    [appimages]="setup_all_appimages"
    [system-monitor]="setup_system_monitor"
    [gnome]="setup_all_gnome_extensions"
    [gnome-settings]="run_dconf_restore"
    [grub]="setup_grub"
    [post-config]="run_post_config"
)

# Orden de ejecucion (los arrays asociativos en bash no mantienen orden)
SECTION_ORDER=(
    repos
    apt
    snaps
    flatpak
    dev-tools
    cursor
    appimages
    system-monitor
    gnome
    gnome-settings
    grub
    post-config
)

SECTION_DESCRIPTIONS=(
    "repos:Configurar PPAs, repositorios y GPG keys"
    "apt:Instalar paquetes APT (Chrome, LibreOffice, Docker, VLC, etc.)"
    "snaps:Instalar snaps (KeePassXC, Discord, Spotify)"
    "flatpak:Configurar Flatpak y Flathub"
    "dev-tools:Node.js (via n), npm globals, Python3"
    "cursor:Cursor IDE (.deb) con icono custom"
    "appimages:LM Studio AppImage"
    "system-monitor:SystemMonitor.sh + .desktop file"
    "gnome:Extensiones GNOME (Caffeine, Dash to Dock, Vitals, etc.)"
    "gnome-settings:Restaurar Settings GNOME (dconf: keybindings, tema, teclado)"
    "grub:Tema GRUB Tela + configuracion"
    "post-config:Grupos (docker), servicios, Git LFS"
)

# -----------------------------------------------------------------------------
# CLI
# -----------------------------------------------------------------------------
show_help() {
    echo "Ubuntu 24.04 Fresh Install Script"
    echo ""
    echo "Uso:"
    echo "  ./install.sh                          Ejecutar todo"
    echo "  ./install.sh --section <nombre>       Ejecutar solo una seccion"
    echo "  ./install.sh <nombre>                 Atajo: igual que --section (ej. system-monitor)"
    echo "  ./install.sh --section sec1,sec2      Ejecutar varias secciones"
    echo "  ./install.sh --list                   Listar secciones"
    echo "  ./install.sh --dry-run                Ver que haria sin ejecutar"
    echo "  ./install.sh --help                   Mostrar esta ayuda"
    echo ""
    echo "Secciones disponibles:"
    for desc in "${SECTION_DESCRIPTIONS[@]}"; do
        local name="${desc%%:*}"
        local text="${desc#*:}"
        printf "  %-16s %s\n" "$name" "$text"
    done
}

list_sections() {
    echo "Secciones disponibles:"
    echo ""
    for desc in "${SECTION_DESCRIPTIONS[@]}"; do
        local name="${desc%%:*}"
        local text="${desc#*:}"
        printf "  %-16s %s\n" "$name" "$text"
    done
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --help|-h)
                show_help
                exit 0
                ;;
            --list|-l)
                list_sections
                exit 0
                ;;
            --dry-run)
                DRY_RUN="true"
                shift
                ;;
            --section|-s)
                if [[ -z "${2:-}" ]]; then
                    log_error "Se necesita un nombre de seccion despues de --section"
                    exit 1
                fi
                IFS=',' read -ra SELECTED_SECTIONS <<< "$2"
                shift 2
                ;;
            *)
                # Allow single section name without --section (e.g. ./install.sh system-monitor)
                if [[ "$1" != -* ]] && [[ -n "${SECTIONS[$1]+x}" ]]; then
                    SELECTED_SECTIONS=("$1")
                    shift
                else
                    log_error "Argumento desconocido: $1"
                    show_help
                    exit 1
                fi
                ;;
        esac
    done
}

# -----------------------------------------------------------------------------
# Fix system state so the rest of the script can run from a clean state
# (broken repos, dpkg, VirtualBox crash file). Runs once at start, no manual steps.
# -----------------------------------------------------------------------------
fix_system_state_before_install() {
    log_section "Preparando sistema"
    # Remove Cursor apt repo (often 403; we install Cursor via .deb)
    for f in /etc/apt/sources.list.d/cursor.list /etc/apt/sources.list.d/cursor.sources; do
        if [[ -f "$f" ]]; then
            sudo rm -f "$f"
            log_info "Eliminado repo Cursor apt: $f"
        fi
    done
    for f in /etc/apt/sources.list.d/*.list /etc/apt/sources.list.d/*.sources; do
        [[ -f "$f" ]] || continue
        if sudo grep -ql "downloads\.cursor\.com\|cursor\.com/aptrepo" "$f" 2>/dev/null; then
            sudo rm -f "$f"
            log_info "Eliminado (contenia repo Cursor): $f"
        fi
    done
    # So virtualbox-dkms postinst does not fail with "Cannot create report: File exists"
    if sudo rm -f /var/crash/virtualbox-dkms*.crash 2>/dev/null; then
        log_info "Eliminado archivo de crash anterior de virtualbox-dkms"
    fi
    # Try to fix half-configured packages (e.g. from a previous failed run)
    log_info "Intentando recuperar estado de dpkg..."
    sudo dpkg --configure -a 2>/dev/null || true
    log_info "Sistema preparado"
}

# -----------------------------------------------------------------------------
# Ejecucion principal
# -----------------------------------------------------------------------------
run_preflight() {
    log_section "Pre-flight checks"
    check_ubuntu_version || true

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY-RUN] Saltando verificacion de sudo e internet"
        return 0
    fi

    if ! check_sudo; then
        log_error "No se puede continuar sin acceso sudo"
        exit 1
    fi

    if ! check_internet; then
        log_error "No se puede continuar sin conexion a internet"
        exit 1
    fi
}

run_all_sections() {
    for section in "${SECTION_ORDER[@]}"; do
        local func="${SECTIONS[$section]}"
        run_section "$section" "$func"
    done
}

run_selected_sections() {
    for section in "${SELECTED_SECTIONS[@]}"; do
        if [[ -z "${SECTIONS[$section]:-}" ]]; then
            log_error "Seccion desconocida: $section"
            log_info "Usa --list para ver las secciones disponibles"
            exit 1
        fi
        local func="${SECTIONS[$section]}"
        run_section "$section" "$func"
    done
}

main() {
    parse_args "$@"

    echo ""
    echo -e "\033[1m========================================\033[0m"
    echo -e "\033[1m  Ubuntu 24.04 Fresh Install Script\033[0m"
    echo -e "\033[1m========================================\033[0m"
    echo ""

    if [[ "$DRY_RUN" == "true" ]]; then
        log_warn "MODO DRY-RUN: No se ejecutara nada, solo se mostrara lo que se haria"
        echo ""
    fi

    run_preflight

    if [[ "${DRY_RUN:-false}" != "true" ]]; then
        fix_system_state_before_install
    fi

    if [[ ${#SELECTED_SECTIONS[@]} -gt 0 ]]; then
        log_info "Ejecutando secciones seleccionadas: ${SELECTED_SECTIONS[*]}"
        run_selected_sections
    else
        log_info "Ejecutando todas las secciones"
        run_all_sections
    fi

    print_summary
}

main "$@"
