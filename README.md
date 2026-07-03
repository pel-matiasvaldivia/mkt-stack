# mkt-stack — CustOS

Stack self-hosted **open source** para el motor de marketing y ventas de CustOS
(sistema operativo para empresas de seguridad privada, Argentina).

Este repo NO contiene todavía la infraestructura desplegada: contiene los **prompts
ejecutables** que arman el stack y conectan la captura de demos. Se le pasan a un agente
(Claude Code, Cursor, etc.) que genera el `docker-compose.yml`, la landing modificada y
el workflow de n8n.

## Componentes del stack (todo OSS)

| Función | Herramienta |
|---|---|
| Automatización (pegamento) | **n8n** |
| CRM / pipeline de demos | **Twenty** |
| Agenda de demos | **Cal.com** |
| Email marketing (prospección, nurture, newsletter) | **Listmonk** |
| Analítica web sin cookies | **Plausible** (community edition) |
| API de WhatsApp | **open-wa** |
| Reverse proxy / TLS | **Nginx Proxy Manager** (ya existente en el servidor) |

## Prompts

1. [`prompts/01-stack.md`](prompts/01-stack.md) — levanta el stack completo con Docker
   Compose, detrás de un Nginx Proxy Manager ya existente (sin Caddy/Traefik).
2. [`prompts/02-captura-demo.md`](prompts/02-captura-demo.md) — conecta la captura de
   demos: arregla el formulario de la landing, arma el workflow
   `form → Twenty → Listmonk → WhatsApp` en n8n y deja las secuencias de mail.

## Orden de ejecución

Ejecutá **01 primero** (dejá el stack arriba y cargá los Proxy Hosts en NPM), y recién
después **02**, porque el workflow necesita las URLs públicas ya sirviendo por HTTPS
(el webhook de n8n, la API de Twenty y el embed de Cal.com deben resolver antes de
poder probar la captura punta a punta).

## Requisitos previos

- VPS Linux con Docker + Docker Compose v2 y **mínimo 8 GB RAM** (ideal 16): Twenty,
  Plausible y Cal.com juntos piden holgura.
- Nginx Proxy Manager corriendo y una red Docker compartida.
- 6 registros DNS tipo A (uno por subdominio) → IP del VPS.
- Un relay SMTP (Brevo o Amazon SES) — el stack no monta MTA propio.
- Un número de WhatsApp **dedicado** para open-wa (no el comercial principal).

## Origen

Deriva del `PLAN_MARKETING_CUSTOS.md` y `GUION_LANZAMIENTO_CUSTOS.md` del producto.
Regla heredada: **no inventar métricas** — apoyarse en lo verificable del producto
(dotación ≈4,2, freno de credencial vencida, datos aislados por tenant).
