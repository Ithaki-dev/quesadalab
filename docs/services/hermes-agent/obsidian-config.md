# Configuración de Obsidian para Hermes Agent

## Resumen
Hermes Agent utiliza Obsidian como memoria persistente para guardar notas, configuraciones y estado de operaciones.

## Ruta del vault
```
/opt/quesadalab/obsidian-vault
```

## Variables de entorno
- **OBSIDIAN_VAULT_PATH** – Ruta absoluta al vault (obligatoria)
- **OBSIDIAN_USER** – Usuario para autenticación (opcional, si se requiere)

## Estructura del vault
```
/opt/quesadalab/obsidian-vault/
├── README.md
├── pruebas/
│   └── hermes_notes.md
└── templates/
```

## Inicialización
1. Montar el vault vía NFS desde `docker01` a `agent01` en `/home/hermes/obsidian-vault`
2. Configurar `OBSIDIAN_VAULT_PATH` en el servicio Hermes
3. Crear notas de prueba para validar la integración

## Notas de prueba
- `pruebas/hermes_notes.md` – Notas de ejemplo generadas por Hermes
- `pruebas/backup-test.md` – Notas para validar backups