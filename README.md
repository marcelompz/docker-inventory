# Docker Inventory & Port Conflict Checker

Sistema de prevención de conflictos de puertos para contenedores Docker.

**Licencia:** [GPL-3.0](LICENSE)  
**Autor:** marcelompz  
**Repositorio:** https://github.com/marcelompz/docker-inventory

## Descripción

Sistema de prevención de conflictos de puertos para contenedores Docker en `/opt`.

**Problema que resuelve:** Evita el error `Bind for 0.0.0.0:XXXX failed: port is already allocated` verificando los puertos disponibles **antes** de ejecutar `docker compose up -d`.

## Archivos

| Archivo | Propósito |
|---------|-----------|
| `check-ports.sh` | Script principal que verifica conflictos antes de `docker compose up` |
| `inventory.md` | Inventario generado automáticamente del estado actual (se actualiza en cada verificación) |
| `README.md` | Esta documentación |

## Uso

### Opción 1: Verificación manual antes de levantar un contenedor

```bash
cd /opt/orderflow
/opt/docker-inventory/check-ports.sh .
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

### Opción 2: Usar los aliases de zsh (recomendado)

Los siguientes aliases se agregaron automáticamente a `~/.zshrc`:

| Alias | Descripción |
|-------|-------------|
| `dcup` | Verifica puertos y levanta contenedores (`check-ports.sh && docker compose up -d`) |
| `dcup-force` | Levanta contenedores sin verificar (uso bajo tu riesgo) |
| `dccheck [dir]` | Solo verifica puertos sin levantar contenedores |

**Ejemplos:**

```bash
# Verificar y levantar OrderFlow
cd /opt/orderflow
dcup

# Solo verificar un proyecto
dccheck /opt/vitalog

# Levantar sin verificar (si estás seguro)
dcup-force
```

### Recargar zsh después de instalar

```bash
source ~/.zshrc
```

## Puertos asignados (actualizado 2026-06-28)

| Proyecto | Servicio | Puerto Externo | Puerto Interno |
|----------|----------|----------------|----------------|
| **Axon** | web-dev | 5173 | 5173 |
| | redis | 6379 | 6379 |
| | couchdb | 5984 | 5984 |
| | postgres | 5432 | 5432 |
| **OrderFlow** | db | 5433 | 5432 |
| | backend | 3010 | 3010 |
| | frontend | 3011 | 3011 |
| | odoo_adapter | 3005 | 3005 |

## ¿Por qué ocurren conflictos?

Docker asigna puertos en el momento de levantar el contenedor. Si otro proceso (otro contenedor o servicio nativo) ya está escuchando en ese puerto, Docker falla con:

```
Error response from daemon: failed to set up container networking: 
driver failed programming external connectivity on endpoint orderflow_db: 
Bind for 0.0.0.0:5432 failed: port is already allocated
```

**Este script verifica ANTES de intentar levantar los contenedores**, dándote la oportunidad de:

1. Cambiar los puertos en el `docker-compose.yml`
2. Detener los contenedores en conflicto
3. Usar `docker compose down` y volver a levantar

## Características

- ✅ Detecta puertos en uso por otros contenedores
- ✅ Ignora puertos ya usados por el mismo proyecto (contenedores existentes)
- ✅ Genera inventario automático de todos los proyectos en `/opt`
- ✅ Muestra puertos del sistema (3000-9999)
- ✅ Funciona con proyectos que tienen múltiples servicios

## Generar inventario manual

```bash
# El inventario se genera automáticamente al verificar
/opt/docker-inventory/check-ports.sh /opt/orderflow

# O usar el script original del usuario
bash ~/inventory.sh
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
