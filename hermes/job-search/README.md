# Hermes: búsqueda laboral con reporte por correo

Este paquete configura una búsqueda asistida los lunes, miércoles y viernes. Hermes encuentra, deduplica y prioriza vacantes; no se postula ni contacta reclutadores.

## 1. Preparar el correo

Hermes necesita IMAP para recibir mensajes y SMTP para enviar reportes. En la VM, configura mediante `hermes gateway setup` o agrega al archivo privado `/home/hermes/.hermes/.env`:

```dotenv
EMAIL_ADDRESS=cuenta-del-agente@example.com
EMAIL_PASSWORD=CONTRASENA_DE_APLICACION
EMAIL_IMAP_HOST=imap.example.com
EMAIL_IMAP_PORT=993
EMAIL_SMTP_HOST=smtp.example.com
EMAIL_SMTP_PORT=587
EMAIL_ALLOWED_USERS=correo-personal@example.com
EMAIL_HOME_ADDRESS=correo-personal@example.com
```

Para Gmail, usa una contraseña de aplicación; no guardes la contraseña normal de la cuenta. Mantén `EMAIL_ALLOWED_USERS` limitado a tu correo y no publiques estos valores.

## 2. Instalar el perfil en la VM

Según la documentación de QuesadaLab, Hermes se ejecuta directamente como el usuario `hermes`; sus datos persistentes están en `/home/hermes/.hermes` y el gateway usa `hermes-gateway.service`. Crea:

```text
/home/hermes/.hermes/workspaces/job-search/
├── profile.md
├── daily-search-prompt.md
└── cv/
    ├── robert-quesada-ai-integration-en.pdf
    ├── robert-quesada-ai-integration-es.pdf
    ├── robert-quesada-backend-en.pdf
    ├── robert-quesada-backend-es.pdf
    ├── robert-quesada-devops-en.pdf
    ├── robert-quesada-devops-es.pdf
    ├── robert-quesada-fullstack-en.pdf
    ├── robert-quesada-fullstack-es.pdf
    ├── robert-quesada-java-backend-en.pdf
    ├── robert-quesada-java-backend-es.pdf
    ├── robert-quesada-solutions-en.pdf
    └── robert-quesada-solutions-es.pdf
```

Copia los dos archivos Markdown y los 12 CV. Los CV contienen información personal y están excluidos de Git mediante `.gitignore`; transfiérelos directamente y no los agregues al repositorio. Protege los documentos:

```bash
chown -R hermes:hermes /home/hermes/.hermes/workspaces/job-search
find /home/hermes/.hermes/workspaces/job-search -type d -exec chmod 700 {} \;
find /home/hermes/.hermes/workspaces/job-search -type f -exec chmod 600 {} \;
```

## 3. Verificar Hermes y el correo

Ejecuta como el usuario `hermes` dentro de `agent01`:

```bash
hermes config check
hermes doctor
systemctl --user restart hermes-gateway.service
systemctl --user is-active hermes-gateway.service
journalctl --user -u hermes-gateway.service -n 100 --no-pager
```

Después, verifica que el adaptador de correo aparezca activo. Si rechaza mensajes entrantes, revisa `EMAIL_ALLOWED_USERS`.

## 4. Verificar herramientas web

Ejecuta `hermes doctor` y confirma que `web` y `file` aparezcan disponibles. En instalaciones que muestren una plataforma `cron` dentro de `hermes tools`, habilita allí ambas herramientas. Si la versión instalada no muestra esa plataforma, no cambies la configuración global: valida la ejecución de prueba y exige `[SEARCH_FAILED]` cuando no pueda verificar fuentes reales.

## 5. Crear la tarea periódica

Desde una sesión interactiva con Hermes, pega:

```text
Crea una tarea cron llamada "busqueda-laboral-lunes-miercoles-viernes" para
los lunes, miércoles y viernes a las 08:00 en la zona horaria
America/Costa_Rica. Debe trabajar en
/home/hermes/.hermes/workspaces/job-search, leer daily-search-prompt.md y ejecutar
exactamente esa tarea. Entrega el resultado por email a la dirección de inicio.
Habilita solamente las herramientas web y file. No debe postular, iniciar
sesión, evadir CAPTCHA ni enviar mensajes a terceros. Muéstrame la tarea
creada y ejecútala una vez ahora como prueba.
```

También puede crearse desde la CLI:

```bash
hermes cron create "0 8 * * 1,3,5" \
  "Lee daily-search-prompt.md y ejecuta exactamente esa tarea." \
  --name "busqueda-laboral-lunes-miercoles-viernes" \
  --workdir /home/hermes/.hermes/workspaces/job-search \
  --deliver email
```

Verifica después con:

```bash
hermes cron list
```

## 6. Validación

El primer reporte debe:

- llegar a la dirección configurada en `EMAIL_HOME_ADDRESS`;
- contener enlaces directos y puntuaciones;
- distinguir experiencia demostrada de tecnologías deseadas;
- excluir duplicados y vacantes incompatibles;
- limitarse al reporte y no iniciar una postulación.

Si el reporte no llega, confirma que el gateway está activo, que SMTP funciona, que `EMAIL_HOME_ADDRESS` es correcto y que la VM tiene salida a Internet. Revisa `hermes cron list` y el journal del gateway para errores de entrega.
