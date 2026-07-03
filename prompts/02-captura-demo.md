# TAREA: Conectar la captura de demos — n8n + custos-landing.html

## Contexto
El stack (n8n, Twenty CRM, Cal.com, Listmonk, Plausible, open-wa) ya está corriendo
detrás de Nginx Proxy Manager. Ahora hay que hacer que el tráfico de marketing se
CONVIERTA en demos medibles. Hoy los CTA "Pedí una demo" de `custos-landing.html`
apuntan a `href="#"` (ancla vacía) → todo el tráfico se pierde. Ese es el bloqueante.

Registro rioplatense (voseo), tono del `PLAN_MARKETING_CUSTOS.md` y
`GUION_LANZAMIENTO_CUSTOS.md`. Cumplir **Ley 25.326** (opt-in explícito + baja).

## Parte A — Arreglar `custos-landing.html`
1. **Formulario de demo real** (reemplaza los `href="#"`). Campos:
   nombre, empresa, cantidad de vigiladores, provincia, WhatsApp, email, y un
   **checkbox de consentimiento** ("Acepto ser contactado por CustOS", con link a
   política de privacidad). Validación básica en cliente.
   - Enviar por `POST` (fetch, JSON) al **webhook de n8n** (URL parametrizada, no
     hardcodear el dominio en varios lados: una constante JS arriba).
   - Capturar y enviar los **UTMs** (utm_source/medium/campaign/content/term) leídos de
     la query string, más `referrer` y la URL de la página.
   - Estados de UI: enviando / éxito ("Te contactamos en breve") / error. Sin recargar.
2. **Cal.com embebido** como alternativa de autoagenda: opción "Elegí día y hora" que
   abre el embed de Cal.com (usar el embed oficial de Cal). El form y el Cal conviven:
   el form para los que dejan datos, el Cal para los que quieren cerrar en el momento.
3. **Botón flotante de WhatsApp** en toda la landing (número comercial, mensaje
   prellenado "Hola, quiero una demo de CustOS").
4. **Plausible:** insertar el snippet de tracking (script del dominio de analytics) y
   disparar un **evento de conversión** `Demo: formulario enviado` al éxito del form, y
   `Demo: WhatsApp click` / `Demo: Cal abierto`. Documentar los goals a crear en
   Plausible.
5. **Open Graph / meta** para que la landing se vea bien al compartir en WhatsApp y
   LinkedIn (título, descripción, imagen). Mantener el HTML liviano ya existente.

## Parte B — Workflow en n8n: "Captura de demo"
Exportá el workflow como JSON en el repo (`n8n/workflow-captura-demo.json`) y documentá
cómo importarlo. Flujo:
1. **Webhook** (POST) recibe el form. Validar payload; si falta algo crítico, responder
   400 con mensaje claro.
2. **Anti-spam mínimo:** honeypot y/o rate-limit básico. Descartar si el honeypot viene
   lleno.
3. **Twenty (CRM):** crear/actualizar el registro vía su API (GraphQL/REST — usá la que
   corresponda a la versión). Mapear campos: persona (nombre), empresa (empresa +
   cantidad de vigiladores + provincia), teléfono (WhatsApp), email, y los UTMs como
   `source`. Etapa del pipeline: **Lead**. Idempotente por email (no duplicar).
4. **Listmonk:** alta del contacto en la lista correspondiente vía API, con opt-in
   registrado (guardar consentimiento + fecha). Respetar baja/no-reenvío.
5. **open-wa:** notificación de WhatsApp **al equipo comercial** con el resumen del lead
   ("Nueva demo: {empresa}, {vigiladores} vigiladores, {provincia} — WhatsApp {tel}").
   Opcional: auto-respuesta al prospecto confirmando recepción (con voseo).
6. **Respuesta** al form con 200 y payload de éxito.
7. **Manejo de errores:** rama de error que loguea y notifica (WhatsApp/email al
   equipo) si Twenty o Listmonk fallan, para no perder el lead silenciosamente.

## Parte C — Secuencias en Listmonk (cargar como plantillas)
Transcribir del plan y dejar listas en Listmonk:
- **Prospección en frío (4 toques)** — §7.1 del PLAN_MARKETING_CUSTOS.md, textual.
- **Nurture post lead magnet (5 mails/3 semanas)** — §7.2.
- Newsletter mensual "Margen" — plantilla base §7.3.
Cada envío con **identificación clara + link de baja** (Ley 25.326). Un solo CTA por
mail: la demo. Documentar qué lista/campaña corresponde a cada secuencia.

## Entregables
1. `custos-landing.html` modificado (form real + Cal embed + WhatsApp + Plausible + OG).
2. `n8n/workflow-captura-demo.json` + instrucciones de import y variables/credenciales
   que hay que cargar en n8n (Twenty API key, Listmonk API, open-wa token).
3. `n8n/README.md`: qué credenciales crear, cómo probar el webhook con `curl`, y el
   mapeo de campos form → Twenty → Listmonk.
4. Lista de **goals a crear en Plausible** y de **campos custom en Twenty** (si hacen
   falta: cantidad de vigiladores, provincia, source/UTM).
5. Las 3 secuencias de mail cargadas en Listmonk (o exportadas como HTML/plantillas en
   `listmonk/` si no hay API disponible en este entorno).

## Método de trabajo
- Antes de tocar la landing, **leé** `custos-landing.html`, `PLAN_MARKETING_CUSTOS.md`
  (§6.4 copys, §7 mails, §8 web) y `GUION_LANZAMIENTO_CUSTOS.md` para respetar tono y
  claims. **No inventar métricas** (regla del plan): apoyarse en lo verificable
  (dotación ≈4,2, freno de credencial, datos aislados).
- Preguntame SOLO lo indeducible: número de WhatsApp comercial, versión de la API de
  Twenty desplegada, y la lista/segmento de Listmonk a usar.
- **Verificá de punta a punta** antes de dar por hecho nada: enviá un POST de prueba al
  webhook y comprobá que (a) aparece el lead en Twenty, (b) el contacto entra a
  Listmonk, (c) llega la notificación de WhatsApp. Reportá el resultado real de cada
  paso con la salida; si algo falla, diagnosticá y arreglá.
- Mantené el HTML liviano y accesible; no metas frameworks pesados por un formulario.

## Fuera de alcance
- No cambiar el diseño/copy central de la landing más allá de lo necesario para el form,
  el embed, WhatsApp, tracking y OG.
- No configurar pauta paga ni pixels de Meta/Google todavía (fase posterior).
