# USB backup storage runbook

## Alcance

El almacenamiento `qlab-usb-backup` reside en un HDD USB conectado al nodo
Proxmox `quesada`. Guarda respaldos `vzdump` y las replicas verificadas de los
conjuntos de Nextcloud.

| Elemento | Valor |
|---|---|
| Storage de Proxmox | `qlab-usb-backup` |
| Punto de montaje | `/mnt/quesadalab-backup` |
| Sistema de archivos | ext4 |
| Etiqueta | `qlab-backup` |
| UUID activo | `3bf7b34e-42c5-44e9-985d-09d1ca1f9052` |
| Ruta del gabinete | `/dev/disk/by-id/usb-Seagate_BUP_Slim_00000000-0:0` |
| Enlace USB esperado | SuperSpeed, `5000M` |

La ruta `by-id` identifica el gabinete USB. Puede conservar el mismo valor al
cambiar el HDD interno; nunca se debe usar como unica prueba de identidad antes
de borrar un disco. Confirme tambien dispositivo resuelto, capacidad, tabla de
particiones, montajes, pertenencia a LVM y UUID.

## Montaje

La entrada activa de `/etc/fstab` es:

```fstab
UUID=3bf7b34e-42c5-44e9-985d-09d1ca1f9052 /mnt/quesadalab-backup ext4 defaults,noatime,nofail,x-systemd.device-timeout=30s 0 2
```

Valide el montaje y el storage con:

```bash
findmnt --verify --verbose
findmnt /mnt/quesadalab-backup
df -hT /mnt/quesadalab-backup
pvesm status
```

## Aislamiento ante errores

Errores como `Directory block failed checksum`, `Corrupt inode bitmap`,
`Bad message` o `Data will be lost` requieren detener las escrituras de
inmediato. No ejecute otro respaldo ni repare el filesystem mientras este
montado.

```bash
systemctl disable --now pull-nextcloud-backups.timer
systemctl stop pull-nextcloud-backups.service
pvesm set qlab-usb-backup --disable 1
sync
umount /mnt/quesadalab-backup
```

Use primero `e2fsck -fn` sobre la particion desmontada. Una reparacion que
modifique metadatos requiere revision del resultado, confirmacion explicita y,
cuando sea posible, un archivo de deshacer en almacenamiento independiente.

## Reemplazo de julio de 2026

El HDD anterior presento corrupcion de metadatos ext4 durante un `vzdump`. El
kernel reporto checksums invalidos en directorios y bitmaps. El storage se
deshabilito, el filesystem se desmonto y el medio fue sustituido.

El reemplazo se inicializo con GPT y una sola particion ext4. Antes de volver a
produccion se verificaron:

- `e2fsck -fn` con salida limpia;
- escritura y lectura de un archivo de prueba de 1 GiB;
- un `vzdump` completo con `zstd --test` correcto;
- inventario del archivo mediante `pvesm list`;
- replica de Nextcloud con todos los valores de `SHA256SUMS` correctos;
- ausencia de archivos `.incoming`, `.tmp` y `.dat` residuales;
- ausencia de nuevos errores USB o ext4 en el kernel.

Solo despues de estas pruebas se habilito nuevamente
`pull-nextcloud-backups.timer`.

## Comprobacion periodica

```bash
systemctl is-enabled pull-nextcloud-backups.timer
systemctl is-active pull-nextcloud-backups.timer
systemctl list-timers pull-nextcloud-backups.timer --all --no-pager

pvesm list qlab-usb-backup --vmid 200

journalctl -k --since '24 hours ago' --no-pager |
  grep -Ei 'sdb|usb|uas|reset|disconnect|I/O error|buffer I/O|ext4|bad message' || true
```

La falta de acceso SMART a traves del gabinete no debe interpretarse como un
resultado saludable. La integridad se confirma mediante checksums, pruebas de
archivo, pruebas de los archivos Zstandard y vigilancia de eventos del kernel.
