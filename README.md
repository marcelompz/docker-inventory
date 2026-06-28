# Docker Port Conflict Checker

Sistema de prevención de conflictos de puertos para contenedores Docker.

**Licencia:** [GPL-3.0](LICENSE)  
**Autor:** marcelompz  
**Repositorio:** https://github.com/marcelompz/docker-inventory

## Descripción

Verifica los puertos disponibles **antes** de ejecutar `docker compose up -d` para evitar el error:

```
Bind for 0.0.0.0:XXXX failed: port is already allocated
```

## Archivos

| Archivo | Propósito |
|---------|-----------|
| `check-ports.sh` | Script principal que verifica conflictos antes de `docker compose up` |
| `inventory.md` | Inventario generado automáticamente del estado actual (se actualiza en cada verificación) |
| `README.md` | Esta documentación |

## Instalación

### Opción 1: Instalación automática (recomendado)

El script detecta y configura automáticamente tus archivos de shell (`~/.bashrc`, `~/.zshrc`, `~/.bash_profile`):

```bash
# Instalar aliases
./check-ports.sh --install

# O usar el alias corto
./check-ports.sh -i
```

Luego recarga tu shell:
```bash
source ~/.bashrc  # o source ~/.zshrc
```

**¿Qué hace la instalación?**

Agrega los siguientes aliases a tu shell config:
- `dcup` - Verifica puertos y levanta contenedores
- `dcup-force` - Levanta sin verificar
- `dccheck [dir]` - Solo verifica puertos

### Opción 2: Manual

Agregar al `~/.bashrc` o `~/.zshrc`:

```bash
# Docker Port Conflict Checker
alias dcup='/path/to/check-ports.sh . && docker compose up -d'
alias dcup-force='docker compose up -d'
dccheck() {
    /path/to/check-ports.sh "${1:-.}"
}
```

## Uso

### Verificación manual antes de levantar un contenedor

```bash
cd mi-proyecto
/path/to/check-ports.sh .
```

Si no hay conflictos:
```
✓ Sin conflictos de puertos
Puedes ejecutar: docker compose up -d
```

Si hay conflictos:
```
✗ Puerto 5432 ya está en uso por otro servicio
```

### Usando los aliases (después de instalar)

```bash
# Verificar y levantar
cd mi-proyecto
dcup

# Solo verificar
dccheck /ruta/a/proyecto

# Levantar sin verificar (si estás seguro)
dcup-force
```

## Características

- ✅ Detecta puertos en uso por otros contenedores o servicios
- ✅ Ignora puertos ya usados por el mismo proyecto (contenedores existentes)
- ✅ Genera inventario automático de proyectos Docker en directorios comunes
- ✅ Muestra puertos del sistema (3000-9999)
- ✅ Funciona con proyectos que tienen múltiples servicios
- ✅ Búsqueda multi-directorio: `$HOME`, `/srv`, `~/projects`, `~/dev`, etc.

## ¿Por qué ocurren conflictos?

Docker asigna puertos en el momento de levantar el contenedor. Si otro proceso (otro contenedor o servicio nativo) ya está escuchando en ese puerto, Docker falla con:

```
Error response from daemon: failed to set up container networking: 
driver failed programming external connectivity on endpoint: 
Bind for 0.0.0.0:5432 failed: port is already allocated
```

**Este script verifica ANTES de intentar levantar los contenedores**, dándote la oportunidad de:

1. Cambiar los puertos en el `docker-compose.yml`
2. Detener los contenedores en conflicto
3. Usar `docker compose down` y volver a levantar

## Ejemplo de inventario

```markdown
# Inventario de Puertos Docker - 2026-06-28

## Contenedores corriendo:
mi_proyecto_db       0.0.0.0:5432->5432/tcp
mi_proyecto_api      0.0.0.0:8080->8080/tcp

## Puertos en uso (sistema):
3000 5432 6379 8080 9000

## Proyectos Docker detectados:
- mi-proyecto ($HOME/docker/mi-proyecto/): 5432,8080
- otro-proyecto ($HOME/dev/otro-proyecto/): 3000,9000
```

## Solución de problemas

### "Puerto ya está en uso" pero el contenedor es del mismo proyecto

Esto puede pasar si los contenedores están en estado `Exited` pero no fueron eliminados. Solución:

```bash
docker compose down
docker compose up -d
```

### Falso positivo con puertos de sistema

Algunos puertos pueden estar en uso por servicios del sistema (systemd, DNS, etc.). El script solo muestra puertos en el rango 3000-9999 para reducir ruido.

### Quiero deshabilitar la verificación

Usa el alias `dcup-force` o ejecuta directamente:
```bash
docker compose up -d
```

### Los aliases no funcionan después de instalar

Recarga tu shell:
```bash
source ~/.bashrc   # para bash
source ~/.zshrc    # para zsh
```

O reinicia la terminal.

## Licencia

GNU General Public License v3.0 (GPL-3.0). Ver [LICENSE](LICENSE) para más detalles.
