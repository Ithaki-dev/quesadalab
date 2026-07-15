# Troubleshooting

## Grafana no inicia

Verificar

```bash
docker logs grafana
```

---

## Error Bad Gateway

Comprobar:

- Traefik
- Red proxy
- Etiqueta

```
traefik.docker.network=proxy
```

---

## Prometheus no aparece

Verificar:

```
Connections

↓

Data Sources
```

Comprobar

```
http://prometheus:9090
```

---

## Dashboards sin datos

Verificar:

```
http://prometheus.lab/targets
```

Todos los Targets deben aparecer:

```
UP
```

---

## Node Exporter

Consulta

```promql
node_uname_info
```

---

## cAdvisor

Consulta

```promql
container_last_seen
```

---

## Reiniciar

```bash
docker compose restart
```

---

## Recrear

```bash
docker compose up -d --force-recreate
```

---

## Actualizar

```bash
docker compose pull

docker compose up -d
```