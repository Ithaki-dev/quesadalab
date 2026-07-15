# Grafana

## Descripción

Grafana es la plataforma de visualización y análisis de métricas utilizada por QuesadaLab.

Se integra con Prometheus como fuente de datos para visualizar el estado del servidor Docker, los contenedores y los servicios de infraestructura mediante dashboards interactivos.

Grafana constituye la capa de visualización de la plataforma de observabilidad del laboratorio.

---

## Objetivos

- Visualizar métricas del host Docker.
- Visualizar métricas de los contenedores.
- Analizar tendencias históricas.
- Centralizar dashboards de infraestructura.
- Integrarse con Prometheus.

---

## Información del servicio

| Parámetro | Valor |
|-----------|-------|
| Servicio | Grafana |
| Contenedor | grafana |
| Imagen | grafana/grafana:latest |
| Puerto interno | 3000 |
| Acceso | http://grafana.lab |
| Proxy | Traefik |
| Red Docker | proxy, monitoring |

---

## Integraciones

Grafana utiliza como fuente de datos:

- Prometheus

Prometheus recopila métricas desde:

- Node Exporter
- cAdvisor
- Prometheus

Grafana también se integra con:

- Homepage
- Uptime Kuma

---

## Dashboards instalados

### Host Docker

Métricas del servidor Debian:

- CPU
- Memoria
- Disco
- Red
- Load Average
- Uptime

---

### Docker Containers

Métricas por contenedor:

- CPU
- RAM
- Red
- Disco
- Estado

---

### Prometheus

Visualización del estado de Prometheus y sus Targets.

---

## Estado

✅ Producción

---

## Directorios

Docker Compose

```
/opt/quesadalab/stacks/grafana
```

Configuración

```
/opt/quesadalab/config/grafana
```

Datos

```
/opt/quesadalab/data/grafana
```