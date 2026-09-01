# AGENTS.md

Instrucciones para agentes que trabajen en este repositorio de QuesadaLab.

## Alcance del repositorio

Este repositorio documenta y gestiona configuración versionada del homelab
QuesadaLab:

- infraestructura Proxmox;
- stacks Docker en `docker01`;
- configuración administrada en `config/`;
- runbooks operativos en `docs/runbooks/`;
- documentación por servicio en `docs/services/`;
- scripts de respaldo, restauración, validación y despliegue en `scripts/`;
- perfiles y contexto operativo de Hermes en `hermes/`.

La ruta operativa del repo en el homelab es:

```text
/opt/quesadalab-repo
```

La configuración viva normalmente se despliega hacia:

```text
/opt/quesadalab
```

## Reglas de seguridad

- No commitear secretos, tokens, contraseñas, llaves privadas, cookies, archivos
  `.env` reales ni respaldos con credenciales.
- Los archivos `.env.example` deben contener solo placeholders.
- No imprimir secretos en logs, documentación, comandos sugeridos ni salidas de
  diagnóstico.
- Antes de editar o diagnosticar credenciales, confirma rutas y muestra solo
  presencia, conteos, fingerprints parciales no reversibles o placeholders.
- No borrar volúmenes, bases de datos, backups, imágenes, cachés ni datos de
  servicios sin autorización explícita.
- Antes de cualquier cambio destructivo o irreversible, crear respaldo
  verificable y documentar reversión.

## Estado operativo base

### Infraestructura

- Nodo Proxmox: `quesada`
- Proxmox VE: 9.2.4
- Hardware actual: Dell OptiPlex 9020 MT, Intel Core i7-4790, ~16 GiB RAM
- VM 200 `docker01`: 4 vCPU, 8 GiB RAM, 80 GB, siempre activa
- VM 300 `homeassistant`: 2 vCPU, 2 GiB RAM, en retirada
- VM 400 `agent01`: 4 vCPU, 4 GiB RAM, siempre activa y crítica
- LXC 100 `adguard`: 1 CPU, 512 MiB RAM, 512 MiB swap, 2 GB, crítico

### Servicios críticos y siempre activos

- Proxmox
- `docker01`
- `agent01`
- AdGuard
- Traefik
- Vaultwarden
- Cloudflare Tunnel
- OmniRoute

### Servicios siempre activos no críticos

- Nextcloud
- Homepage
- Uptime Kuma
- Portainer
- Node Exporter
- Prometheus

### Servicios bajo demanda

- Immich
- Jellyfin
- Grafana
- cAdvisor

### Servicios en retirada

- Home Assistant

## Reglas específicas por servicio

### OmniRoute

- OmniRoute es persistente y crítico.
- `stacks/omniroute/docker-compose.yml` debe mantener `restart:
  unless-stopped` para `omniroute` y `omniroute-redis`.
- No cambiar límites de CPU, RAM, PIDs, healthchecks, redes, volúmenes ni
  medidas de seguridad sin revisión de capacidad.
- La imagen debe permanecer pineada por digest inmutable.
- No confundir OmniRoute con OpenRouter:
  - OmniRoute es el gateway interno en `docker01`.
  - OpenRouter es un proveedor externo que puede estar documentado en perfiles
    o historial de Hermes.

### Prometheus, Grafana y cAdvisor

- Prometheus es permanente.
- Prometheus debe mantener:
  - `restart: unless-stopped`;
  - almacenamiento persistente;
  - `--storage.tsdb.retention.time=30d`;
  - `--storage.tsdb.retention.size=5GB`.
- Node Exporter permanece siempre activo.
- Grafana permanece bajo demanda.
- cAdvisor permanece bajo demanda.
- No eliminar el target de cAdvisor de Prometheus por el solo hecho de que
  cAdvisor esté apagado. Cuando cAdvisor esté detenido intencionalmente,
  Prometheus puede mostrar ese target como `DOWN`; documentarlo como estado
  esperado, no como falla de Prometheus.

### Home Assistant

- Home Assistant está en retirada.
- No eliminar la VM 300, su configuración ni sus respaldos sin autorización
  explícita.
- No documentarlo como servicio bajo demanda normal. Debe figurar como
  `en retirada`, `retiring` o `pendiente de eliminación`.

### Hermes Agent

- Hermes corre en `agent01`.
- El perfil default puede ser personal; perfiles dedicados como `ithakidev`
  deben mantener contexto, memoria y prompts separados.
- Para preguntas de memoria, buscar primero en:

```text
/home/hermes/.hermes/obsidian
```

- La sección de memoria de IthakiDev vive en:

```text
/home/hermes/.hermes/obsidian/ithakidev
```

- No guardar secretos, tokens, credenciales de clientes ni datos privados en la
  memoria de Obsidian.

## Patrones del repositorio

### Stacks Docker

- Cada servicio Docker vive en `stacks/<servicio>/docker-compose.yml`.
- Si necesita variables, usar `.env.example` con placeholders.
- No versionar `.env` reales.
- Los datos persistentes deben vivir bajo `/opt/quesadalab/data`.
- La configuración administrada debe vivir bajo `/opt/quesadalab/config`.
- Los backups deben vivir bajo `/opt/quesadalab/backups`.

### Documentación

- Documentación general:

```text
README.md
docs/architecture/
docs/networking/
docs/services/README.md
```

- Documentación por servicio:

```text
docs/services/<servicio>/README.md
```

- Runbooks:

```text
docs/runbooks/
```

- Decisiones arquitectónicas:

```text
adr/
```

Si una decisión histórica ya no coincide con la configuración real, no
reescribirla silenciosamente. Agregar una nota de estado actual o crear una
decisión nueva, según corresponda.

## Flujo de trabajo para cambios

1. Inspeccionar estado del repo:

```bash
git status --short
rg --files
```

2. Revisar archivos relacionados antes de editar.
3. Mantener cambios dentro del alcance solicitado.
4. Usar parches pequeños y revisables.
5. Actualizar documentación junto con configuración cuando cambie el estado
   operativo.
6. Revisar el diff completo antes de entregar.
7. No hacer commit ni push salvo autorización explícita.

## Validación local

Ejecutar cuando sea posible:

```bash
bash scripts/validate.sh
git diff --check
```

Validar sintaxis Bash si se modifican scripts:

```bash
bash -n deploy.sh scripts/*.sh scripts/lib/*.sh
```

Buscar secretos comunes antes de entregar. Preferir el mecanismo de validación
del repo o una herramienta dedicada de secret scanning. Como mínimo, revisar que
no haya archivos sensibles versionados:

```bash
git status --short
rg -n --hidden '\.env|private key|api key|token|password|secret' \
  . --glob '!**/.git/**'
```

## Validación en `docker01`

Cuando el cambio afecte stacks Docker, validar en `docker01`:

```bash
cd /opt/quesadalab-repo
bash scripts/validate.sh
```

Validar Compose:

```bash
docker compose \
  --project-directory /opt/quesadalab/stacks/<servicio> \
  --file /opt/quesadalab/stacks/<servicio>/docker-compose.yml \
  config --quiet
```

Si el stack requiere `.env`, incluir:

```bash
--env-file /opt/quesadalab/stacks/<servicio>/.env
```

## Despliegue

Usar `deploy.sh` para cambios administrados desde el repo.

Simulación:

```bash
cd /opt/quesadalab-repo
bash deploy.sh <servicio> --dry-run
```

Despliegue real:

```bash
cd /opt/quesadalab-repo
bash deploy.sh <servicio>
```

Despliegue base:

```bash
bash deploy.sh all
```

El despliegue base no debe encender servicios bajo demanda como Grafana,
cAdvisor, Immich o Jellyfin.

## Comprobaciones post-despliegue

Para servicios Docker:

```bash
docker inspect <contenedor> \
  --format 'name={{.Name}} status={{.State.Status}} health={{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}} restart={{.HostConfig.RestartPolicy.Name}} image={{.Config.Image}}'
```

Prometheus:

```bash
curl --silent --show-error --fail \
  http://prometheus.lab/-/ready
```

OmniRoute:

```bash
curl --silent --show-error --insecure \
  --output /dev/null \
  --write-out 'OmniRoute HTTPS %{http_code}\n' \
  https://omniroute.lab/
```

Recursos:

```bash
docker stats --no-stream
free -h
df -h /
```

## Entrega esperada

Al finalizar un cambio, reportar:

- resumen de cambios;
- archivos modificados;
- validaciones ejecutadas y resultados;
- despliegue realizado o pendiente;
- riesgos, inconsistencias restantes y decisiones pendientes.

Si alguna validación no puede ejecutarse por falta de herramientas o acceso,
indicarlo explícitamente y dar el comando exacto para ejecutarla en el entorno
correcto.
