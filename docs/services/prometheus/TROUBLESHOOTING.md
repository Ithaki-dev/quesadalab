# Troubleshooting

## El servicio no inicia

Verificar

```bash
docker logs prometheus
```

---

## Error de configuración

Validar

```bash
promtool check config prometheus.yml
```

---

## No carga prometheus.lab

Verificar

- DNS
- Traefik
- Middleware

---

## Endpoint de salud

```bash
curl http://prometheus.lab/-/healthy
```

Debe responder

```
Prometheus Server is Healthy.
```

---

## Estado de Targets

```
http://prometheus.lab/targets
```

Todos los objetivos deben aparecer como:

```
UP
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