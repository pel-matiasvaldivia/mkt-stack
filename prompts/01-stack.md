# TAREA: Levantar el stack de marketing de CustOS (Docker Compose, detrás de Nginx Proxy Manager)

## Contexto
Infra self-hosted para el motor de marketing/ventas de CustOS (seguridad privada,
Argentina) en UN VPS Linux (Ubuntu 22.04+, Docker + Compose v2). **El servidor YA
tiene Nginx Proxy Manager (NPM) corriendo en Docker** y maneja el TLS/Let's Encrypt.
NO incluyas Caddy ni Traefik. Los servicios NO exponen TLS ni gestionan certificados.

## Servicios a levantar
1. **n8n** — automatización (form → CRM → mail → WhatsApp). Pegamento central.
2. **Twenty** — CRM (pipeline Lead → Demo → Propuesta → Cliente).
3. **Cal.com** — agenda de demos (para embeber en la landing).
4. **Listmonk** — email marketing (prospección, nurture, newsletter).
5. **Plausible** (community edition) — analítica web sin cookies.
6. **open-wa** (open-wa/api-server o wppconnect) — API de WhatsApp para n8n.

## Integración con Nginx Proxy Manager (clave)
- Crear una **red Docker externa compartida** (ej. `npm_network`) a la que se conecta
  cada servicio web. Asumí que NPM ya está o será conectado a esa misma red; documentá
  el comando `docker network create npm_network` y cómo unir NPM a ella.
- Los servicios web se alcanzan por **nombre de contenedor + puerto interno** (ej.
  `n8n:5678`). NPM hace de proxy hacia ahí. **No publiques puertos al host** salvo que
  sea imprescindible; si hiciera falta, bindéalos a `127.0.0.1`.
- Cada servicio recibe por `.env` su **URL pública final** (la que servirá NPM), porque
  varios la necesitan internamente: `WEBHOOK_URL` (n8n), `SERVER_URL` (Twenty),
  `NEXT_PUBLIC_WEBAPP_URL` (Cal.com), `BASE_URL` (Plausible), app root de Listmonk.
- En el README, incluí una tabla de qué **Proxy Host** cargar en NPM por servicio:
  subdominio → `contenedor:puerto`, con **Websockets Support = ON** para n8n y Twenty,
  y **Force SSL / HTTP2 = ON**.

## Restricciones y estándares (obligatorio)
- **Un solo `docker-compose.yml`** raíz + `.env` para TODOS los secretos. Nada
  hardcodeado.
- **Bases de datos:** motores que cada servicio requiere, una base por servicio:
  - Postgres compartido con una base por servicio (n8n, twenty, calcom, listmonk,
    plausible). Twenty además **Redis**. Plausible además **ClickHouse**.
  - DBs/Redis/ClickHouse **solo en la red interna**, nunca publicados al host.
- **Persistencia:** volúmenes nombrados para toda la data (DBs, uploads, sesión de
  WhatsApp). Nada efímero.
- **Secretos:** generar todos fuertes (APP_SECRET, N8N_ENCRYPTION_KEY, NEXTAUTH_SECRET,
  CALENDSO_ENCRYPTION_KEY, SECRET_KEY_BASE, passwords DB…) y documentarlos en
  `.env.example` con placeholders + `scripts/gen-secrets.sh` que los genere.
- **SMTP:** parametrizar host/user/pass/puerto por `.env` (voy a usar Brevo o SES como
  relay). Listmonk y n8n deben poder enviar. NO montar un MTA propio.
- **Healthchecks** en cada servicio + `depends_on: { condition: service_healthy }`.
- **Timezone** `America/Argentina/Buenos_Aires` donde aplique.

## Requisitos por servicio
- **n8n:** persistir workflows, `N8N_ENCRYPTION_KEY`, `WEBHOOK_URL` con el subdominio
  público (crítico para los webhooks del form de la landing), auth de admin.
- **Twenty:** server + worker (+ frontend si aplica), `APP_SECRET`, `SERVER_URL`,
  Postgres + Redis, storage local en volumen.
- **Cal.com:** `DATABASE_URL`, `NEXTAUTH_SECRET`, `CALENDSO_ENCRYPTION_KEY`,
  `NEXT_PUBLIC_WEBAPP_URL`, SMTP. Debe permitir embeber en la landing.
- **Listmonk:** migración/instalación inicial (crear admin), config por env o TOML
  montado, SMTP del `.env`.
- **Plausible community edition:** Postgres + ClickHouse, `BASE_URL`, `SECRET_KEY_BASE`.
  Dejar listo el snippet de tracking para `custos-landing.html`.
- **open-wa:** API accesible solo desde n8n por la red interna, sesión persistida en
  volumen. Documentar cómo escanear el QR la primera vez.

## Entregables
1. `docker-compose.yml` completo y comentado (con la red externa de NPM).
2. `.env.example` con TODAS las variables comentadas.
3. `scripts/gen-secrets.sh`.
4. `Makefile`: `up`, `down`, `logs`, `ps`, `backup`, `restore`.
5. `README.md`: requisitos, **DNS** (registros A por subdominio → IP del VPS),
   **cómo crear la red y unir NPM**, **tabla de Proxy Hosts a cargar en NPM**
   (subdominio, contenedor:puerto, websockets, force SSL), orden de inicialización
   (Listmonk admin, Twenty workspace, Cal primer usuario, Plausible primer sitio, QR de
   WhatsApp) y cómo hacer backup.
6. Diagrama mermaid de cómo se conectan los servicios (y dónde entra NPM).

## Método de trabajo
- Antes de escribir, preguntame SOLO lo indeducible: dominio base real y subdominios,
  nombre exacto de la red de NPM, proveedor SMTP (SES/Brevo) y si el VPS ya tiene
  Docker. El resto, defaults sensatos documentados.
- Fijá versiones de imagen con tag concreto (no `latest`) y anotá cuáles usaste.
- Al terminar: `docker compose config` para validar, `docker compose up -d`, y verificá
  con healthchecks/`curl` interno que cada servicio responde. Reportá el estado real de
  cada uno con la salida; no afirmes que algo anda sin comprobarlo. Si un servicio no
  arranca, diagnosticá con `docker compose logs <servicio>` y arreglá antes de seguir.

## Fuera de alcance
- No incluir Caddy/Traefik ni gestión de TLS (lo hace NPM).
- No montar MTA propio (usar relay SMTP).
- No exponer puertos de DB/Redis/ClickHouse.
- No cargar contenido de marketing ni workflows todavía (tarea aparte).
