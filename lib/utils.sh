#!/bin/bash
# =============================================================================
# utils.sh - Utilidades compartidas (logging, error handling, wrappers)
# =============================================================================

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Array global de errores
declare -a INSTALL_ERRORS=()
declare -a INSTALL_WARNINGS=()
declare -a INSTALL_SUCCESS=()

# -----------------------------------------------------------------------------
# Logging
# -----------------------------------------------------------------------------
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
    INSTALL_WARNINGS+=("$1")
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_section() {
    local title="$1"
    local line
    line=$(printf '=%.0s' {1..60})
    echo ""
    echo -e "${CYAN}${BOLD}${line}${NC}"
    echo -e "${CYAN}${BOLD}  $title${NC}"
    echo -e "${CYAN}${BOLD}${line}${NC}"
    echo ""
}

log_subsection() {
    echo -e "${BLUE}${BOLD}--- $1 ---${NC}"
}

# -----------------------------------------------------------------------------
# Pre-flight checks
# -----------------------------------------------------------------------------
check_ubuntu_version() {
    if [[ ! -f /etc/os-release ]]; then
        log_error "No se encontro /etc/os-release"
        return 1
    fi
    source /etc/os-release
    if [[ "$ID" != "ubuntu" ]]; then
        log_error "Este script esta disenado para Ubuntu, detectado: $ID"
        return 1
    fi
    if [[ "$VERSION_CODENAME" != "noble" ]]; then
        log_warn "Este script esta disenado para Ubuntu 24.04 (noble), detectado: $VERSION_CODENAME"
    fi
    log_info "Sistema detectado: $PRETTY_NAME"
}

check_sudo() {
    if [[ $EUID -eq 0 ]]; then
        log_error "No ejecutar como root directamente. Usa tu usuario normal (el script pedira sudo cuando lo necesite)."
        return 1
    fi
    if ! sudo -v 2>/dev/null; then
        log_error "Se necesita acceso sudo."
        return 1
    fi
    log_info "Acceso sudo verificado"
}

check_internet() {
    if ! ping -c 1 -W 3 google.com &>/dev/null; then
        log_error "No hay conexion a internet."
        return 1
    fi
    log_info "Conexion a internet verificada"
}

# -----------------------------------------------------------------------------
# Wrappers de instalacion
# -----------------------------------------------------------------------------
apt_install() {
    local packages=("$@")
    log_info "Instalando via apt: ${packages[*]}"
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log_info "[DRY-RUN] sudo apt-get install -y ${packages[*]}"
        return 0
    fi
    if sudo apt-get install -y "${packages[@]}" 2>&1; then
        return 0
    else
        log_error "Fallo al instalar: ${packages[*]}"
        return 1
    fi
}

snap_install() {
    local name="$1"
    shift
    local flags=("$@")
    log_info "Instalando via snap: $name ${flags[*]}"
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log_info "[DRY-RUN] sudo snap install $name ${flags[*]}"
        return 0
    fi
    if snap list "$name" &>/dev/null; then
        log_info "$name ya esta instalado via snap"
        return 0
    fi
    if sudo snap install "$name" "${flags[@]}" 2>&1; then
        return 0
    else
        log_error "Fallo al instalar snap: $name"
        return 1
    fi
}

# -----------------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------------
ensure_dir() {
    mkdir -p "$1"
}

backup_file() {
    local filepath="$1"
    if [[ -f "$filepath" ]]; then
        local backup="${filepath}.bak.$(date +%Y%m%d_%H%M%S)"
        sudo cp "$filepath" "$backup"
        log_info "Backup creado: $backup"
    fi
}

is_installed() {
    dpkg -l "$1" 2>/dev/null | grep -q "^ii"
}

command_exists() {
    command -v "$1" &>/dev/null
}

# -----------------------------------------------------------------------------
# Section runner con manejo de errores
# -----------------------------------------------------------------------------
run_section() {
    local name="$1"
    shift
    local func="$1"
    shift

    log_section "$name"

    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log_info "[DRY-RUN] Ejecutaria seccion: $name"
    fi

    if "$func" "$@"; then
        INSTALL_SUCCESS+=("$name")
        log_info "Seccion '$name' completada correctamente"
    else
        INSTALL_ERRORS+=("$name")
        log_error "Seccion '$name' fallo (continuando con el resto)"
    fi
}

# -----------------------------------------------------------------------------
# Resumen final
# -----------------------------------------------------------------------------
print_summary() {
    log_section "RESUMEN DE INSTALACION"

    if [[ ${#INSTALL_SUCCESS[@]} -gt 0 ]]; then
        echo -e "${GREEN}${BOLD}Completado correctamente (${#INSTALL_SUCCESS[@]}):${NC}"
        for item in "${INSTALL_SUCCESS[@]}"; do
            echo -e "  ${GREEN}✓${NC} $item"
        done
        echo ""
    fi

    if [[ ${#INSTALL_WARNINGS[@]} -gt 0 ]]; then
        echo -e "${YELLOW}${BOLD}Avisos (${#INSTALL_WARNINGS[@]}):${NC}"
        for item in "${INSTALL_WARNINGS[@]}"; do
            echo -e "  ${YELLOW}!${NC} $item"
        done
        echo ""
    fi

    if [[ ${#INSTALL_ERRORS[@]} -gt 0 ]]; then
        echo -e "${RED}${BOLD}Fallaron (${#INSTALL_ERRORS[@]}):${NC}"
        for item in "${INSTALL_ERRORS[@]}"; do
            echo -e "  ${RED}✗${NC} $item"
        done
        echo ""
    fi

    echo -e "${BOLD}Notas importantes:${NC}"
    echo "  - Necesitas cerrar sesion y volver a entrar para que los cambios de grupo surtan efecto (docker)"
    echo "  - Las extensiones GNOME pueden necesitar reiniciar la sesion (Alt+F2, 'r', Enter en X11)"
    echo "  - Es recomendable reiniciar el sistema para aplicar todos los cambios"
    echo ""

    if [[ ${#INSTALL_ERRORS[@]} -gt 0 ]]; then
        return 1
    fi
    return 0
}
