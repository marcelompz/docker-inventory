#!/bin/bash
#
# Docker Port Conflict Checker
# Verifica conflictos de puertos antes de levantar contenedores Docker
#
# Copyright (C) 2026 marcelompz
# License: GNU General Public License v3.0 (GPL-3.0)
# See LICENSE file or https://www.gnu.org/licenses/gpl-3.0.html
#
# Usage: ./check-ports.sh [directorio-con-docker-compose]
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INVENTORY_FILE="$SCRIPT_DIR/inventory.md"
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Función para obtener puertos en uso
get_used_ports() {
    ss -tlnp 2>/dev/null | grep LISTEN | awk '{print $4}' | grep -oE '[0-9]+$' | sort -n | uniq
}

# Función para obtener puertos de un docker-compose.yml
get_compose_ports() {
    local file="$1"
    # Extraer puertos externos (antes del : en "externo:interno")
    grep -E '^\s*-[[:space:]]*"[0-9]+:[0-9]+"' "$file" 2>/dev/null | \
        awk -F'"' '{print $2}' | \
        awk -F':' '{print $1}' | \
        sort -n | uniq
}

# Función para verificar conflictos
check_conflicts() {
    local compose_file="$1"
    local conflicts=0
    local project_name=$(basename "$(dirname "$compose_file")")

    echo -e "${YELLOW}Verificando puertos en $compose_file...${NC}"

    # Obtener puertos del compose
    local compose_ports=$(get_compose_ports "$compose_file")

    # Obtener puertos en uso
    local used_ports=$(get_used_ports)

    # Verificar cada puerto
    for port in $compose_ports; do
        if echo "$used_ports" | grep -q "^${port}$"; then
            # Verificar si es un contenedor del mismo proyecto
            local matching_containers=$(docker ps --format "{{.Names}}" 2>/dev/null | grep "^${project_name}_" | wc -l)
            
            if [ "$matching_containers" -gt 0 ]; then
                # Verificar si este puerto específico pertenece a este proyecto
                local port_in_use_by_project=0
                for container in $(docker ps --format "{{.Names}}" | grep "^${project_name}_"); do
                    if docker port "$container" 2>/dev/null | grep -q ":${port}"; then
                        port_in_use_by_project=1
                        break
                    fi
                done
                
                if [ "$port_in_use_by_project" -eq 1 ]; then
                    echo -e "${GREEN}✓ Puerto $port (contenedor ya corriendo)${NC}"
                else
                    echo -e "${RED}✗ Puerto $port ya está en uso por otro servicio${NC}"
                    conflicts=$((conflicts + 1))
                fi
            else
                echo -e "${RED}✗ Puerto $port ya está en uso${NC}"
                conflicts=$((conflicts + 1))
            fi
        else
            echo -e "${GREEN}✓ Puerto $port disponible${NC}"
        fi
    done

    return $conflicts
}

# Función para generar inventario actual
generate_inventory() {
    echo "# Inventario de Puertos Docker - $(date '+%Y-%m-%d %H:%M')" > "$INVENTORY_FILE"
    echo "" >> "$INVENTORY_FILE"

    echo "## Contenedores corriendo:" >> "$INVENTORY_FILE"
    docker ps --format "table {{.Names}}\t{{.Ports}}" | tail -n +2 >> "$INVENTORY_FILE"
    echo "" >> "$INVENTORY_FILE"

    echo "## Puertos en uso (sistema):" >> "$INVENTORY_FILE"
    # Mostrar solo puertos relevantes (3000-9999)
    get_used_ports | awk '$1 >= 3000 && $1 <= 9999' | tr '\n' ' ' >> "$INVENTORY_FILE"
    echo "" >> "$INVENTORY_FILE"

    echo "" >> "$INVENTORY_FILE"
    echo "## Proyectos Docker detectados:" >> "$INVENTORY_FILE"
    # Buscar en directorios comunes
    local search_dirs=("$HOME" "/opt" "/srv" "$HOME/projects" "$HOME/dev")
    for search_dir in "${search_dirs[@]}"; do
        if [ -d "$search_dir" ]; then
            for d in "$search_dir"/*/; do
                if [ -f "$d/docker-compose.yml" ] || [ -f "$d/docker-compose.yaml" ]; then
                    local name=$(basename "$d")
                    local ports=$(grep -E '^\s*-[[:space:]]*"[0-9]+:[0-9]+"' "$d/docker-compose."* 2>/dev/null | \
                        awk -F'"' '{print $2}' | \
                        awk -F':' '{print $1}' | \
                        tr '\n' ',' | sed 's/,$//')
                    echo "- $name ($d): ${ports:-sin puertos}" >> "$INVENTORY_FILE"
                fi
            done
        fi
    done

    echo -e "${GREEN}✓ Inventario actualizado: $INVENTORY_FILE${NC}"
}

# Función para instalar aliases automáticamente
install_aliases() {
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local check_script="$script_dir/check-ports.sh"
    local alias_block='
# Docker Port Conflict Checker (docker-inventory)
# Auto-instalado el '"$(date '+%Y-%m-%d')"'
alias dcup='"'"'"$check_script" . && docker compose up -d'"'"'
alias dcup-force='"'"'docker compose up -d'"'"'
dccheck() {
    "'"$check_script"' "${1:-.}"
}
'

    local shell_configs=()
    
    # Detectar shell configs existentes
    [ -f ~/.bashrc ] && shell_configs+=("$HOME/.bashrc")
    [ -f ~/.zshrc ] && shell_configs+=("$HOME/.zshrc")
    [ -f ~/.bash_profile ] && shell_configs+=("$HOME/.bash_profile")
    
    if [ ${#shell_configs[@]} -eq 0 ]; then
        echo -e "${YELLOW}No se encontró ~/.bashrc, ~/.zshrc o ~/.bash_profile${NC}"
        echo "Agrega manualmente los aliases a tu shell config."
        return 1
    fi
    
    local installed=0
    
    for config in "${shell_configs[@]}"; do
        if grep -q "docker-inventory" "$config" 2>/dev/null; then
            echo -e "${GREEN}✓ $config ya tiene los aliases configurados${NC}"
        else
            echo "$alias_block" >> "$config"
            echo -e "${GREEN}✓ Aliases agregados a $config${NC}"
            installed=1
        fi
    done
    
    if [ $installed -eq 1 ]; then
        echo ""
        echo -e "${YELLOW}Para activar los aliases, ejecuta:${NC}"
        echo "  source ~/.bashrc  # o source ~/.zshrc"
    fi
    
    return 0
}

# Main
main() {
    # Modo instalación
    if [[ "$1" == "--install" || "$1" == "-i" ]]; then
        echo "================================"
        echo "  Docker Inventory Installer"
        echo "================================"
        echo ""
        install_aliases
        exit $?
    fi

    local target_dir="${1:-.}"
    local compose_file="$target_dir/docker-compose.yml"

    echo "================================"
    echo "  Docker Port Conflict Checker"
    echo "================================"
    echo ""

    # Generar inventario primero
    generate_inventory

    echo ""

    if [ ! -f "$compose_file" ]; then
        echo -e "${RED}Error: No se encontró docker-compose.yml en $target_dir${NC}"
        exit 1
    fi

    # Verificar conflictos
    if check_conflicts "$compose_file"; then
        echo ""
        echo -e "${GREEN}================================${NC}"
        echo -e "${GREEN}  ✓ Sin conflictos de puertos${NC}"
        echo -e "${GREEN}================================${NC}"
        echo ""
        echo "Puedes ejecutar: docker compose up -d"
        exit 0
    else
        echo ""
        echo -e "${RED}================================${NC}"
        echo -e "${RED}  ✗ Conflictos detectados${NC}"
        echo -e "${RED}================================${NC}"
        echo ""
        echo "Opciones:"
        echo "  1. Cambiar puertos en docker-compose.yml"
        echo "  2. Detener contenedores en conflicto: docker stop <nombre>"
        echo "  3. Usar docker compose down y volver a levantar"
        exit 1
    fi
}

main "$@"
