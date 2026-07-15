# Instalación de Grafana

## Crear estructura

```bash
mkdir -p /opt/quesadalab/stacks/grafana
mkdir -p /opt/quesadalab/data/grafana
mkdir -p /opt/quesadalab/config/grafana
```

---

## Docker Compose

Ubicación

```
/opt/quesadalab/stacks/grafana/docker-compose.yml
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

## DNS

Registrar

```
grafana.lab
```

↓

```
192.168.1.30
```

---

## Acceso

```
http://grafana.lab
```

---

## Credenciales

Las credenciales del administrador se almacenan en:

```
/opt/quesadalab/stacks/grafana/.env
```

Variables:

```
GRAFANA_ADMIN_USER
GRAFANA_ADMIN_PASSWORD
```

---

## Fuente de datos

Grafana se conecta automáticamente con Prometheus mediante provisioning.

---

## Snapshot recomendado

```
clean-grafana
```