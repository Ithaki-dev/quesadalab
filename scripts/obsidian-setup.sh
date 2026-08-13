#!/bin/bash
# ============================================
# Obsidian Setup Script for Hermes Agent
# Ejecuta la inicialización de Obsidian en el host agent01
# ============================================

set -euo pipefail

VAULT_PATH="/opt/quesadalab/obsidian-vault"
HOST="192.168.1.60"  # agent01
USER="hermes"

# 1. Crear directorio del vault en docker01 (si no existe)
ssh root@${HOST} "mkdir -p ${VAULT_PATH}"
ssh root@${HOST} "chown -R 1000:1000 ${VAULT_PATH}"

# 2. Montar el vault vía NFS en agent01
MOUNT_POINT="/home/hermes/obsidian-vault"
if ! mountpoint -q "${MOUNT_POINT}"; then
    echo "Mounting Obsidian vault from docker01 to ${MOUNT_POINT}..."
    sudo mount -t nfs ${HOST}:${VAULT_PATH} "${MOUNT_POINT}"
fi

# 4. Configurar variable de entorno en Hermes
ENV_FILE="/home/hermes/.hermes/.env"
if [ ! -f "${ENV_FILE}" ]; then
    mkdir -p /home/hermes/.hermes
    echo "OBSIDIAN_VAULT_PATH=${VAULT_PATH}" > "${ENV_FILE}"
    chmod 600 "${ENV_FILE}"
    echo "✅ Variable OBSIDIAN_VAULT_PATH configurada en ${ENV_FILE}"
else
    # Asegurarse de que la variable exista
    if ! grep -q "^OBSIDIAN_VAULT_PATH=" "${ENV_FILE}"; then
        echo "OBSIDIAN_VAULT_PATH=${VAULT_PATH}" >> "${ENV_FILE}"
        echo "✅ Variable OBSIDIAN_VAULT_PATH agregada a ${ENV_FILE}"
    fi
fi

# 5. Crear directorio de pruebas en el vault
TEST_DIR="${MOUNT_POINT}/pruebas"
mkdir -p "${TEST_DIR}"
cat > "${TEST_DIR}/hermes_test.md" <<'TESTNOTE'
# Nota de prueba de Hermes Agent

## Generado por Hermes Agent

- Fecha: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
- Propósito: Validar integración de Obsidian como memoria persistente

## Contenido

Hermes Agent ha sido configurado para utilizar Obsidian como memoria persistente.
El vault se encuentra en: ${VAULT_PATH}

Notas relevantes:
- Vault path: ${VAULT_PATH}
- Host: agent01 (192.168.1.60)
- Usuario: hermes (UID 1000)

## Validación

Se puede verificar la conexión con:
```bash
hermes doctor
```

Esta nota será visible en la aplicación Obsidian local.
TESTNOTE

echo "✅ Obsidian setup completed!"
echo "Vault mounted at: ${MOUNT_POINT}"
echo "OBSIDIAN_VAULT_PATH=$OBSIDIAN_VAULT_PATH"
EOF