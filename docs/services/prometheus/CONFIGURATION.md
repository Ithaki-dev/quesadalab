# Configuración

## Archivo principal

```
/opt/quesadalab/config/prometheus/prometheus.yml
```

---

## Configuración global

```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s
```

---

## Scrape inicial

```yaml
scrape_configs:

- job_name: prometheus

  static_configs:

  - targets:
      - prometheus:9090
```

---

## Targets futuros

Durante el crecimiento del laboratorio se añadirán:

```
node-exporter:9100

cadvisor:8080
```

---

## Redes Docker

Prometheus utiliza:

```
proxy
```

para Traefik.

```
monitoring
```

para la comunicación interna con los exportadores.

---

## Endpoint de salud

```
http://prometheus.lab/-/healthy
```

---

## Endpoint de métricas

```
http://prometheus.lab/metrics
```