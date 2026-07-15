# Configuración

## Directorio de configuración

```
/opt/quesadalab/config/grafana
```

---

## Provisioning

Datasource

```
provisioning/datasources/prometheus.yml
```

Dashboards

```
provisioning/dashboards/
```

---

## Fuente de datos

Nombre

```
Prometheus
```

URL interna

```
http://prometheus:9090
```

---

## Redes Docker

Grafana utiliza:

```
proxy
```

Acceso mediante Traefik.

```
monitoring
```

Comunicación con Prometheus.

---

## Dashboards

Actualmente instalados:

- Node Exporter Full
- Docker Containers (cAdvisor)
- Prometheus

---

## Integración Homepage

Servicio monitorizado mediante Docker Widget.

---

## Integración Uptime Kuma

Monitor HTTP:

```
http://grafana.lab/api/health
```

---

## Endpoint de salud

```
/api/health
```