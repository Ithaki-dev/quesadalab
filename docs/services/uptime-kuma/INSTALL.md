# Instalación de Uptime Kuma

## Crear directorios

```bash
mkdir -p /opt/quesadalab/stacks/uptime-kuma
mkdir -p /opt/quesadalab/data/uptime-kuma
```

---

## Docker Compose

Ubicación:

```
/opt/quesadalab/stacks/uptime-kuma/docker-compose.yml
```

Desplegar:

```bash
docker compose up -d
```

Verificar:

```bash
docker compose ps
```

---

## DNS

Registrar en AdGuard Home:

```
kuma.lab

↓

192.168.1.30
```

---

## Acceso

```
http://kuma.lab
```

Crear el usuario administrador durante el primer inicio.

---

## Snapshot recomendado

Nombre:

```
docker01-after-uptime-kuma
```