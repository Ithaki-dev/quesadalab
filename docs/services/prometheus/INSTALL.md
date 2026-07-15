# Instalación de Prometheus

## Crear estructura

```bash
mkdir -p /opt/quesadalab/stacks/prometheus
mkdir -p /opt/quesadalab/config/prometheus
mkdir -p /opt/quesadalab/data/prometheus
```

---

## Docker Compose

Ubicación

```
/opt/quesadalab/stacks/prometheus/docker-compose.yml
```

Desplegar

```bash
docker compose up -d
```

Verificar

```bash
docker compose ps
```

---

## Configuración

Archivo

```
/opt/quesadalab/config/prometheus/prometheus.yml
```

Validar configuración

```bash
docker run --rm \
-v /opt/quesadalab/config/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml:ro \
prom/prometheus \
promtool check config /etc/prometheus/prometheus.yml
```

---

## DNS

Registrar

```
prometheus.lab
```

↓

```
192.168.1.30
```

---

## Integración

- Traefik
- Homepage
- Uptime Kuma

---

## Snapshot recomendado

```
clean-prometheus
```