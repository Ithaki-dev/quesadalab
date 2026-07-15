# Troubleshooting

## El sitio no carga

Comprobar contenedor:

```bash
docker ps
```

Logs:

```bash
docker logs uptime-kuma
```

---

## Error 404

Verificar Traefik:

```bash
docker logs traefik
```

Comprobar etiquetas:

```yaml
traefik.enable=true

traefik.http.routers.kuma.rule=Host(`kuma.lab`)
```

---

## No resuelve kuma.lab

Verificar DNS:

```bash
nslookup kuma.lab
```

Debe responder:

```
192.168.1.30
```

---

## Homepage no muestra el estado

Comprobar:

```bash
docker ps
```

Verificar el nombre del contenedor:

```
uptime-kuma
```

Comprobar la configuración en Homepage:

```yaml
server: my-docker

container: uptime-kuma
```

---

## Reiniciar el servicio

```bash
cd /opt/quesadalab/stacks/uptime-kuma

docker compose restart
```

---

## Recrear el contenedor

```bash
docker compose up -d --force-recreate
```

---

## Actualizar la imagen

```bash
docker compose pull

docker compose up -d
```