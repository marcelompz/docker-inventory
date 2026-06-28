# Changelog

Todos los cambios notables en este proyecto se documentan en este archivo.

El formato está basado en [Keep a Changelog](https://keepachangelog.com/es/1.0.0/)
y este proyecto se adhiere a [Versionado Semántico](https://semver.org/lang/es/).

## [1.0.0] - 2026-06-28

### Añadido

- Script `check-ports.sh` para verificar conflictos de puertos antes de `docker compose up`
- Función `get_used_ports()` que extrae puertos en uso del sistema (rango 3000-9999)
- Función `get_compose_ports()` que parsea `docker-compose.yml` para obtener puertos configurados
- Función `check_conflicts()` que detecta conflictos e ignora puertos del mismo proyecto
- Función `generate_inventory()` que crea inventario automático de contenedores y proyectos
- Función `install_aliases()` para instalación automática de aliases en shell configs
- Detección automática de `~/.bashrc`, `~/.zshrc`, `~/.bash_profile`
- Búsqueda multi-directorio para proyectos Docker: `$HOME`, `/srv`, `~/projects`, `~/dev`, `~/docker`, `~/containers`
- Aliases pre-configurados:
  - `dcup` - Verifica y levanta contenedores
  - `dcup-force` - Levanta sin verificar
  - `dccheck [dir]` - Solo verifica puertos
- Documentación completa en README.md
- Licencia GPL-3.0
- Archivo `.gitignore` para excluir archivos generados

### Cambiado

- Script hecho portátil: sin referencias hardcoded a `/opt` o proyectos específicos
- README genérico con ejemplos universales (`mi-proyecto` en lugar de `orderflow`)
- Inventario ya no está limitado a `/opt`, busca en múltiples directorios comunes

### Corregido

- Extracción correcta de puertos desde `ss -tlnp` (columna 4, formato IP:puerto)
- Filtrado de puertos no numéricos (`*`) en la salida de `ss`
- Detección de contenedores existentes del mismo proyecto para evitar falsos positivos
- Instalación de aliases con quoting correcto usando heredoc
- Idempotencia en instalación: no duplica aliases si ya existen

### Técnico

- Inicialización del repositorio en GitHub: `marcelompz/docker-inventory`
- Commits:
  - `e42a25e` - Initial commit: Docker port conflict checker
  - `bb9038f` - Add GPL-3.0 license, .gitignore, and copyright headers
  - `553c362` - Make script portable: detect projects in multiple directories, dynamic alias paths
  - `6ae0cbe` - Fix alias installation: use heredoc for proper quoting
  - `812d8af` - Update README: document auto-install feature
  - `54f185f` - Remove /opt and orderflow references: make project generic and portable

---

## Notas de versión

### v1.0.0 - Lanzamiento inicial

Primer lanzamiento estable del verificador de conflictos de puertos Docker.

**Motivación:** Resolver el error frecuente `Bind for 0.0.0.0:XXXX failed: port is already allocated` que ocurre cuando múltiples proyectos Docker compiten por los mismos puertos.

**Características principales:**
- Verificación pre-vuelo antes de levantar contenedores
- Inventario automático de todos los proyectos Docker en el sistema
- Instalación automática de aliases para flujo de trabajo simplificado
- Detección inteligente: ignora puertos ya usados por el mismo proyecto

**Requisitos:**
- Bash 4.0+
- Docker CLI
- Linux con `ss` (iproute2)
