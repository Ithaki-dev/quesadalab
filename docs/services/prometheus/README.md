# Prometheus

## Descripción

Prometheus es el sistema de recolección y almacenamiento de métricas utilizado por QuesadaLab.

Su función es recopilar métricas de la infraestructura mediante el modelo *pull*, almacenarlas en una base de datos de series temporales (TSDB) y ponerlas a disposición para consultas y visualización.

Prometheus constituye la base de la plataforma de observabilidad del laboratorio.

---

## Objetivos

- Centralizar la recolección de métricas.
- Supervisar el estado del host Docker.
- Supervisar contenedores Docker.
- Servir como fuente de datos para Grafana.
- Facilitar la generación de alertas y dashboards.

---

## Información del servicio

| Parámetro | Valor |
|-----------|-------|
| Servicio | Prometheus |
| Contenedor | prometheus |
| Imagen | prom/prometheus:latest |
| Puerto interno | 9090 |
| Acceso | http://prometheus.lab |
| Proxy | Traefik |
| Red Docker | proxy, monitoring |

---

## Componentes asociados

Prometheus recopilará métricas de:

- Node Exporter
- cAdvisor
- Prometheus (Self Monitoring)

Posteriormente se integrará con:

- Grafana

---

## Estado

✅ Producción

---

## Directorios

Docker Compose

```
/opt/quesadalab/stacks/prometheus
```

Configuración

```
/opt/quesadalab/config/prometheus
```

Datos

```
/opt/quesadalab/data/prometheus
```