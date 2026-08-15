# Tarea periódica de búsqueda laboral

Lee cuidadosamente:

- `profile.md`
- los 12 CV especializados de `cv/` enumerados en la sección `Selección del CV`

El objetivo es encontrar las mejores oportunidades laborales para Robert Quesada, priorizando calidad sobre cantidad.

`profile.md` es la única fuente de verdad para experiencia, tecnologías, nivel, puestos y exclusiones. Si este archivo contradice el presente prompt, prevalece `profile.md`.

## Perfil profesional objetivo

Robert posee más de 10 años de experiencia en infraestructura TI y soporte empresarial, además de experiencia reciente como Software Engineer.

- Buscar primero los puestos de prioridad Muy Alta y Alta definidos en `profile.md`.
- Considerar después los puestos de prioridad Media.
- Respetar estrictamente la sección `No buscar` de `profile.md`.
- Las tecnologías de la sección `Tecnologías objetivo` sirven para descubrir oportunidades adyacentes, pero no demuestran experiencia ni aumentan la puntuación.

## Selección del CV

Para cada vacante, elige exactamente un CV según el rol y el idioma de la publicación:

| Familia de la vacante | CV en inglés | CV en español |
|---|---|---|
| Backend, Python, Node.js, API | `cv/robert-quesada-backend-en.pdf` | `cv/robert-quesada-backend-es.pdf` |
| Full Stack, React, Web Application | `cv/robert-quesada-fullstack-en.pdf` | `cv/robert-quesada-fullstack-es.pdf` |
| Java Backend | `cv/robert-quesada-java-backend-en.pdf` | `cv/robert-quesada-java-backend-es.pdf` |
| AI Integration, AI Automation, LLM Applications | `cv/robert-quesada-ai-integration-en.pdf` | `cv/robert-quesada-ai-integration-es.pdf` |
| DevOps, Infrastructure, Linux, Cloud Support, SRE | `cv/robert-quesada-devops-en.pdf` | `cv/robert-quesada-devops-es.pdf` |
| Solutions, Integration, Application Support | `cv/robert-quesada-solutions-en.pdf` | `cv/robert-quesada-solutions-es.pdf` |

Reglas obligatorias para escogerlo:

- Usar la versión inglesa para publicaciones en inglés y la española para publicaciones en español.
- Basar la puntuación únicamente en afirmaciones explícitas del CV seleccionado y en `profile.md`.
- El enfoque o título del CV no demuestra por sí mismo una tecnología.
- No convertir C o .NET en C#, ni .NET en .NET Core.
- El nivel de inglés confirmado es B2; nunca aumentarlo a C1 ni describirlo como nativo.
- No asumir equivalencia entre Diploma, Bachillerato, BA o Bachelor's degree. Informar cualquier requisito académico como posible brecha si la equivalencia no está clara.
- No afirmar experiencia en Scrum o SDLC cuando la evidencia solo sea Agile, sprint planning o code reviews.

## Nivel objetivo

Priorizar:

- Junior
- Junior+
- Intermediate
- Mid-Level
- Associate

Aceptar Senior únicamente cuando:

- La descripción indique 3-5 años.
- No requiera liderazgo de equipos grandes.
- La mayoría de tecnologías coincidan con el CV.

Descartar automáticamente:

- Staff
- Principal
- Lead
- Architect
- Director
- Manager

## Ubicación

Buscar únicamente vacantes publicadas durante los últimos 7 días que acepten candidatos ubicados en Costa Rica.

Prioridad:

1. Remoto desde Costa Rica
2. Remoto LATAM aceptando Costa Rica
3. Remoto Americas aceptando Costa Rica
4. Híbrido Costa Rica
5. Presencial Costa Rica

También aceptar empresas internacionales que indiquen explícitamente contratación en Costa Rica.

Idiomas:

- Español
- Inglés

## Fuentes prioritarias

Buscar primero mediante fuentes públicas estructuradas que no requieran inicio de sesión:

- Greenhouse
- Lever
- Ashby

Usar, cuando corresponda, sus endpoints públicos oficiales:

- Greenhouse: `https://boards-api.greenhouse.io/v1/boards/{board_token}/jobs?content=true`
- Lever: `https://api.lever.co/v0/postings/{site}?mode=json`
- Ashby: `https://api.ashbyhq.com/posting-api/job-board/{job_board_name}`

Utilizar buscadores únicamente para descubrir páginas de empresas y los identificadores públicos de sus bolsas. La publicación original o la respuesta del API oficial debe ser la fuente de verificación.

Después revisar directamente las páginas públicas de empleo de empresas tecnológicas.

Usar también LinkedIn Jobs e Indeed como fuentes secundarias de descubrimiento:

- realizar como máximo 5 consultas de descubrimiento por plataforma;
- priorizar resultados cuyo título, empresa, ubicación y enlace sean visibles públicamente;
- intentar localizar la misma vacante en la página de empleo de la empresa o en su ATS oficial;
- usar como enlace final la publicación original de la empresa cuando exista;
- si la página pública de LinkedIn o Indeed puede abrirse y verificarse sin autenticación, puede usarse como enlace final indicando claramente la fuente;
- si aparece CAPTCHA, login o verificación de seguridad, no intentar evadirlo ni repetirlo durante esa ejecución;
- si no existe una publicación oficial equivalente y la página de LinkedIn o Indeed no puede verificarse, excluir el resultado.

No usar como fuente primaria otros sitios que estén mostrando CAPTCHA, autenticación o controles anti-bot, incluyendo:

- Glassdoor
- Wellfound
- We Work Remotely

No reintentar repetidamente una fuente bloqueada durante la misma ejecución.

Dar prioridad a empresas de:

- SaaS
- Cloud
- IA
- Ciberseguridad
- HealthTech
- FinTech
- EdTech
- Developer Tools
- Infraestructura
- Startups
- Empresas internacionales con contratación remota

## Integridad obligatoria

Debes utilizar herramientas web durante esta ejecución.

No basta con leer profile.md ni los CV.

Cada vacante debe abrirse y verificarse.

No inventes:

- empresas
- enlaces
- salarios
- fechas
- reclutadores
- requisitos

No utilices páginas agregadoras si no enlazan a la publicación original.

Si la vacante redirige a Greenhouse, Lever, Ashby o Careers, utiliza la URL original.

No inicies sesión.

No resuelvas CAPTCHA.

No uses ni recomiendes stealth, proxies residenciales, rotación de identidades ni otras técnicas para evadir controles de acceso o detección de bots.

No delegues la búsqueda a subagentes.

Para controlar tiempo, costo y tamaño del contexto:

- consultar como máximo 20 bolsas o páginas de empresas por ejecución;
- conservar como máximo 10 candidatas antes de puntuarlas;
- reportar como máximo 5 vacantes verificadas;
- no volver a abrir una URL ya descartada.

No envíes postulaciones.

Si la búsqueda no puede verificarse responde únicamente:

[SEARCH_FAILED] No fue posible verificar vacantes reales en esta ejecución; no se generó ningún reporte ni postulación.

## Sistema de puntuación

Califica cada vacante de 0 a 100.

### Coincidencia del rol (30)

- Backend
- Full Stack
- Platform
- Automation
- DevOps
- Software Engineer

### Tecnologías demostradas (25)

Basarse únicamente en experiencia demostrable del CV.

No asumir conocimientos.

Las tecnologías objetivo o de aprendizaje reciben cero puntos en esta categoría.

### Modalidad y ubicación (15)

Priorizar remoto desde Costa Rica.

### Nivel requerido (10)

Favorecer Junior+, Mid y Associate.

Penalizar Senior.

### Industria (10)

Priorizar IA, Cloud, SaaS, FinTech, HealthTech y empresas tecnológicas.

### Publicación (10)

Más reciente y fuente oficial obtiene mayor puntuación.

Excluir resultados menores a 60.

## Para cada vacante indicar

- Puntuación
- Puesto
- Empresa
- Modalidad
- Ubicación
- Fecha de publicación
- Tecnologías requeridas
- Coincidencias con el CV
- Brechas técnicas
- Idioma de la vacante
- CV recomendado (nombre exacto del archivo y motivo de selección)
- Enlace directo a la publicación
- Fuente de descubrimiento (empresa/ATS, LinkedIn o Indeed)

## Reporte

Asunto:

Vacantes recomendadas - AAAA-MM-DD

### Resumen

- Fecha (America/Costa_Rica)
- Número de vacantes encontradas
- Fuentes consultadas
- Vacantes nuevas
- Vacantes descartadas

### Top oportunidades

Mostrar como máximo 5 vacantes ordenadas por puntuación.

Para cada una explicar brevemente:

- Por qué es una buena oportunidad.
- Qué porcentaje del perfil cumple.
- Riesgos o brechas.
- Si vale la pena postular.

## Priorización

Al finalizar seleccionar:

🥇 Mejor oportunidad

🥈 Segunda mejor

🥉 Tercera mejor

explicando en pocas líneas por qué deberían ser las primeras en revisarse.

No redactes postulaciones.

No generes cartas de presentación.

No envíes correos.

La tarea termina al entregar el reporte verificado.
