"""Página pública de reservas que el negocio comparte con sus clientes.

Se sirve en `/r/{slug}` sin autenticación. Es una sola página autocontenida
(HTML + CSS + JavaScript, sin dependencias externas) que consume la API pública
`/api/v1/public/{slug}`. El cliente elige servicio, día y hora, deja su nombre y
teléfono, y recibe un enlace propio para consultar o cancelar su cita.
"""

from __future__ import annotations

import json
from pathlib import Path
from string import Template
from typing import Annotated, Any

from fastapi import APIRouter, Depends, HTTPException, Request
from fastapi.responses import FileResponse, HTMLResponse
from psycopg import Connection

from app.core.db import get_connection
from app.services.public_booking import load_business

router = APIRouter(tags=["public"])

ConnectionDep = Annotated[Connection[Any], Depends(get_connection)]

_STATIC_DIR = Path(__file__).resolve().parents[2] / "static"

_PAGE = Template(
    """<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="theme-color" content="#0F766E">
<meta name="robots" content="noindex">
<title>Reservar cita · $business_name</title>
<meta name="description" content="$og_description">
<link rel="canonical" href="$public_url">
<meta property="og:type" content="website">
<meta property="og:site_name" content="$business_name">
<meta property="og:title" content="$og_title">
<meta property="og:description" content="$og_description">
<meta property="og:url" content="$public_url">
<meta property="og:image" content="$og_image">
<meta property="og:image:width" content="1024">
<meta property="og:image:height" content="500">
<meta property="og:locale" content="es_NI">
<meta name="twitter:card" content="summary_large_image">
<style>
  :root {
    --brand: #0F766E;
    --brand-soft: #ECFDF5;
    --ink: #0f172a;
    --muted: #64748b;
    --line: #e2e8f0;
    --bg: #f6f9f8;
    --card: #ffffff;
    --ok: #047857;
    --warn: #b45309;
    color-scheme: light;
  }
  * { box-sizing: border-box; -webkit-tap-highlight-color: transparent; }
  body {
    margin: 0;
    font-family: "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
    background: var(--bg);
    color: var(--ink);
    line-height: 1.5;
    padding-bottom: 3rem;
  }
  header {
    background: var(--brand);
    color: #fff;
    padding: 1.5rem 1.25rem 1.75rem;
    border-radius: 0 0 1.5rem 1.5rem;
  }
  header .kicker { font-size: .72rem; letter-spacing: .12em; text-transform: uppercase; opacity: .85; }
  header h1 { margin: .35rem 0 0; font-size: 1.4rem; line-height: 1.2; }
  .meta-line { font-size: .85rem; color: #d1fae5; margin-top: .3rem; }
  .header-actions { display: flex; gap: .5rem; margin-top: .85rem; }
  .hbtn {
    flex: 1; text-align: center; text-decoration: none; font-size: .85rem; font-weight: 600;
    color: #fff; border: 1px solid rgba(255,255,255,.55); border-radius: .65rem;
    padding: .5rem .4rem;
  }
  .chips { display: flex; gap: .4rem; overflow-x: auto; padding-bottom: .3rem; margin-bottom: .8rem; }
  .chip {
    flex: 0 0 auto; border: 1px solid var(--line); background: #fff;
    border-radius: 999px; padding: .35rem .75rem; font-size: .82rem; font-weight: 600;
    color: var(--ink);
  }
  .chip.on { border-color: var(--brand); background: var(--brand-soft); color: var(--brand); }
  .slot .count { display: block; font-size: .6rem; color: var(--muted); margin-top: .1rem; }
  main { max-width: 32rem; margin: 0 auto; padding: 1.25rem 1rem 0; }
  .card {
    background: var(--card);
    border: 1px solid var(--line);
    border-radius: 1rem;
    padding: 1rem;
    margin-bottom: .9rem;
  }
  h2 { font-size: .95rem; margin: 0 0 .6rem; }
  .muted { color: var(--muted); font-size: .85rem; }
  .steps { display: flex; gap: .35rem; margin-bottom: 1rem; }
  .steps span { flex: 1; height: 4px; border-radius: 999px; background: var(--line); }
  .steps span.on { background: var(--brand); }
  button { font: inherit; cursor: pointer; }
  .option {
    display: flex; align-items: center; gap: .75rem; width: 100%;
    text-align: left; background: #fff; border: 1px solid var(--line);
    border-radius: .85rem; padding: .8rem .9rem; margin-bottom: .55rem;
    transition: border-color .15s, background .15s;
  }
  .option.on { border-color: var(--brand); background: var(--brand-soft); }
  .option .grow { flex: 1; min-width: 0; }
  .option strong { display: block; font-size: .95rem; }
  .option .meta { font-size: .8rem; color: var(--muted); }
  .price { font-weight: 700; font-size: .9rem; white-space: nowrap; }
  .days { display: flex; gap: .4rem; overflow-x: auto; padding-bottom: .35rem; margin: 0 -.25rem .85rem; }
  .day {
    flex: 0 0 auto; border: 1px solid var(--line); background: #fff;
    border-radius: .75rem; padding: .45rem .7rem; text-align: center; min-width: 3.6rem;
    color: var(--ink);
  }
  .day small { display: block; font-size: .68rem; color: var(--muted); text-transform: uppercase; }
  .day b { font-size: .95rem; }
  .day.on { border-color: var(--brand); background: var(--brand-soft); }
  .day:disabled { opacity: .4; }
  .slots { display: grid; grid-template-columns: repeat(auto-fill, minmax(5.2rem, 1fr)); gap: .5rem; }
  .slot {
    border: 1px solid var(--line); background: #fff; border-radius: .7rem;
    padding: .55rem .3rem; text-align: center; font-variant-numeric: tabular-nums;
    color: var(--ink);
  }
  .slot small { display: block; font-size: .65rem; color: var(--muted); }
  .slot.on { border-color: var(--brand); background: var(--brand); color: #fff; }
  .slot.on small { color: #d1fae5; }
  label { display: block; font-size: .82rem; font-weight: 600; margin: .8rem 0 .3rem; }
  input, textarea {
    width: 100%; font: inherit; padding: .7rem .8rem; border-radius: .7rem;
    border: 1px solid var(--line); background: #fff; color: var(--ink);
  }
  input:focus, textarea:focus { outline: 2px solid var(--brand); outline-offset: 1px; }
  .cta {
    width: 100%; background: var(--brand); color: #fff; border: 0;
    border-radius: .85rem; padding: .95rem; font-weight: 700; font-size: 1rem;
    margin-top: 1rem;
  }
  .cta:disabled { opacity: .5; }
  .ghost {
    width: 100%; background: #fff; color: var(--brand); border: 1px solid var(--brand);
    border-radius: .85rem; padding: .8rem; font-weight: 600; margin-top: .6rem;
  }
  .error { color: #b91c1c; font-size: .85rem; margin-top: .6rem; display: none; }
  .pill { display: inline-block; font-size: .72rem; font-weight: 700; padding: .15rem .5rem;
          border-radius: 999px; background: var(--brand-soft); color: var(--ok); }
  .summary dt { font-size: .72rem; color: var(--muted); text-transform: uppercase; letter-spacing: .04em; }
  .summary dd { margin: 0 0 .7rem; font-size: .95rem; font-weight: 600; }
  .center { text-align: center; }
  .tick { font-size: 2.5rem; line-height: 1; }
  footer { text-align: center; font-size: .75rem; color: var(--muted); padding: 1.5rem 1rem 0; }
  footer a { color: var(--muted); }
  .spinner {
    width: 1.6rem; height: 1.6rem; border: 3px solid var(--line);
    border-top-color: var(--brand); border-radius: 50%;
    animation: spin .8s linear infinite; margin: 2rem auto;
  }
  @keyframes spin { to { transform: rotate(360deg); } }
  [hidden] { display: none !important; }
</style>
</head>
<body>
<header>
  <div class="kicker">Reserva en línea</div>
  <h1 id="biz-name">$business_name</h1>
  <div class="meta-line" id="biz-sub"></div>
  <div class="meta-line" id="biz-hours" hidden></div>
  <div class="meta-line" id="biz-address" hidden></div>
  <div class="header-actions" id="biz-actions" hidden>
    <a class="hbtn" id="btn-call" hidden>Llamar</a>
    <a class="hbtn" id="btn-map" target="_blank" rel="noopener" hidden>Cómo llegar</a>
  </div>
</header>
<main>
  <div class="steps" id="steps"><span></span><span></span><span></span></div>

  <div id="loading"><div class="spinner"></div></div>
  <div id="fatal" class="card" hidden>
    <h2>Este enlace no está disponible</h2>
    <p class="muted" id="fatal-msg">Pide al negocio un enlace nuevo.</p>
  </div>

  <div id="not-bookable" class="card" hidden>
    <h2>Todavía no hay horarios publicados</h2>
    <p class="muted" id="not-bookable-msg">
      Este negocio aún no abrió su agenda en línea. Escríbele o llámalo para reservar.
    </p>
    <a class="cta" id="not-bookable-wa" style="display:block;text-align:center;text-decoration:none;margin-top:.8rem" hidden>Escribir por WhatsApp</a>
  </div>

  <section id="step-service" hidden>
    <div class="card">
      <h2>¿Qué servicio necesitas?</h2>
      <div id="services"></div>
    </div>
  </section>

  <section id="step-time" hidden>
    <div class="card">
      <h2>¿Cuándo te queda bien?</h2>
      <div id="staff-filter" hidden>
        <div class="muted" style="margin-bottom:.4rem">¿Con quién?</div>
        <div class="chips" id="staff-chips"></div>
      </div>
      <div class="days" id="days"></div>
      <div id="slots-empty" class="muted" hidden></div>
      <div class="slots" id="slots"></div>
      <button class="ghost" id="back-service">Cambiar servicio</button>
    </div>
  </section>

  <section id="step-data" hidden>
    <div class="card">
      <h2>Tus datos</h2>
      <p class="muted" id="picked"></p>
      <label for="f-name">Nombre</label>
      <input id="f-name" autocomplete="name" maxlength="120" placeholder="Tu nombre">
      <label for="f-phone">Teléfono (WhatsApp)</label>
      <input id="f-phone" type="tel" inputmode="tel" autocomplete="tel" maxlength="32" placeholder="8888 8888">
      <label for="f-notes">Comentario (opcional)</label>
      <textarea id="f-notes" rows="2" maxlength="500"></textarea>
      <button class="cta" id="confirm">Confirmar cita</button>
      <div class="error" id="form-error"></div>
      <button class="ghost" id="back-time">Cambiar hora</button>
    </div>
  </section>

  <section id="step-done" hidden>
    <div class="card center">
      <div class="tick">✅</div>
      <h2 style="margin-top:.5rem">¡Cita confirmada!</h2>
      <p class="muted" id="done-lead"></p>
    </div>
    <div class="card summary" id="done-summary"></div>
    <div class="card">
      <p class="muted" style="margin-top:0">Guarda tu enlace para consultar o cancelar la cita.</p>
      <button class="ghost" id="copy-link">Copiar mi enlace</button>
      <a class="ghost" id="wa-business" style="display:block;text-align:center;text-decoration:none;margin-top:.6rem" hidden>Avisar al negocio por WhatsApp</a>
    </div>
  </section>

  <section id="step-mine" hidden>
    <div class="card">
      <h2>Tu cita</h2>
      <div class="summary" id="mine-summary"></div>
      <button class="cta" id="cancel-booking" hidden>Cancelar mi cita</button>
      <div class="error" id="mine-error"></div>
    </div>
    <button class="ghost" id="new-booking" hidden>Reservar otra cita</button>
  </section>

  <footer>
    Reservas gestionadas con $business_name ·
    <a href="/privacidad">Privacidad</a>
  </footer>
</main>
<script>
const SLUG = $slug_json;
const API = "/api/v1/public/" + encodeURIComponent(SLUG);
const state = { business: null, services: [], staff: [], hours: [], daysAhead: 21,
                service: null, day: null, days: [], slot: null, token: null,
                staffFilter: null };
const el = (id) => document.getElementById(id);
const esc = (text) => String(text == null ? "" : text)
  .replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")
  .replace(/"/g, "&quot;");

const INDUSTRIES = {
  barberia: "Barbería", salon_belleza: "Salón de belleza",
  taller_mecanico: "Taller mecánico", veterinaria: "Veterinaria",
  gimnasio: "Gimnasio", academia: "Academia", fotografia: "Fotografía",
  otro: "Servicios",
};
const WEEKDAYS = ["Domingo", "Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado"];

function industryLabel(code) {
  if (!code) return "";
  return INDUSTRIES[code] || String(code).replace(/_/g, " ");
}
function phoneLabel(raw) {
  const digits = String(raw || "").replace(/[^0-9]/g, "");
  if (digits.length === 11 && digits.startsWith("505")) {
    return "+505 " + digits.slice(3, 7) + " " + digits.slice(7);
  }
  if (digits.length === 8) return digits.slice(0, 4) + " " + digits.slice(4);
  return raw || "";
}
// Resume los días con atención en una sola línea legible.
function hoursLabel(hours) {
  if (!hours || !hours.length) return "";
  const byWeekday = {};
  hours.forEach((h) => { byWeekday[h.weekday] = h; });
  const groups = [];
  [1, 2, 3, 4, 5, 6, 0].forEach((weekday) => {
    const h = byWeekday[weekday];
    if (!h) return;
    const text = h.opens_at + "–" + h.closes_at;
    const last = groups[groups.length - 1];
    if (last && last.text === text) last.days.push(weekday);
    else groups.push({ text, days: [weekday] });
  });
  return groups.map((group) => {
    const names = group.days.map((d) => WEEKDAYS[d].slice(0, 3));
    const label = names.length > 1
      ? names[0] + "–" + names[names.length - 1]
      : names[0];
    return label + " " + group.text;
  }).join(" · ");
}
function mapsUrl(address, name) {
  const query = [name, address].filter(Boolean).join(", ");
  return "https://www.google.com/maps/search/?api=1&query=" + encodeURIComponent(query);
}

function money(value, currency) {
  if (value == null) return "";
  try {
    return new Intl.NumberFormat("es", { style: "currency", currency, maximumFractionDigits: 2 })
      .format(value);
  } catch (e) { return currency + " " + value.toFixed(2); }
}
// La hora se muestra SIEMPRE en la zona del negocio, no en la del visitante.
let bizTz = undefined;
function dayLabel(iso) {
  const d = new Date(iso + "T12:00:00Z");
  return {
    top: d.toLocaleDateString("es", { weekday: "short", timeZone: "UTC" }),
    bottom: d.toLocaleDateString("es", { day: "numeric", month: "short", timeZone: "UTC" }),
  };
}
// Fecha sin hora (YYYY-MM-DD): se formatea en UTC para no correr un día.
function dayOnlyLabel(iso) {
  return new Date(iso + "T12:00:00Z").toLocaleDateString("es", {
    weekday: "long", day: "numeric", month: "long", timeZone: "UTC",
  });
}
function bizDate(offset) {
  const today = new Intl.DateTimeFormat("en-CA", {
    timeZone: bizTz, year: "numeric", month: "2-digit", day: "2-digit",
  }).format(new Date());
  const day = new Date(today + "T12:00:00Z");
  day.setUTCDate(day.getUTCDate() + offset);
  return day.toISOString().slice(0, 10);
}
function timeLabel(iso) {
  return new Date(iso).toLocaleTimeString("es", {
    hour: "2-digit", minute: "2-digit", timeZone: bizTz,
  });
}
function dateLabel(iso) {
  return new Date(iso).toLocaleDateString("es", {
    weekday: "long", day: "numeric", month: "long", timeZone: bizTz,
  });
}
function show(section) {
  ["step-service", "step-time", "step-data", "step-done", "step-mine"].forEach((id) => {
    const node = el(id);
    if (node) node.hidden = id !== section;
  });
  const order = ["step-service", "step-time", "step-data", "step-done"];
  const index = order.indexOf(section);
  document.querySelectorAll("#steps span").forEach((bar, i) => {
    bar.classList.toggle("on", index >= 0 && i <= index);
  });
  window.scrollTo({ top: 0, behavior: "smooth" });
}

async function api(path, options) {
  const response = await fetch(API + path, options);
  let data = null;
  try { data = await response.json(); } catch (e) { data = null; }
  if (!response.ok) {
    const detail = data && data.detail;
    const message = typeof detail === "string" ? detail
      : (detail && detail.message) ? detail.message
      : "No se pudo completar la reserva. Intenta de nuevo.";
    throw new Error(message);
  }
  return data;
}

function fatal(message) {
  el("loading").hidden = true;
  el("fatal").hidden = false;
  el("fatal-msg").textContent = message;
  el("steps").hidden = true;
}

function renderServices() {
  const currency = state.business.currency;
  el("services").innerHTML = state.services.map((s) => `
    <button class="option" data-service="${esc(s.id)}">
      <span class="grow">
        <strong>${esc(s.name)}</strong>
        <span class="meta">${esc(s.duration_minutes)} min${s.description ? " · " + esc(s.description) : ""}</span>
      </span>
      <span class="price">${esc(money(s.price, currency))}</span>
    </button>`).join("") || '<p class="muted">Este negocio aún no publicó servicios.</p>';

  el("services").querySelectorAll("[data-service]").forEach((button) => {
    button.addEventListener("click", () => selectService(button.dataset.service));
  });
  show("step-service");
}

function selectService(id) {
  state.service = state.services.find((s) => s.id === id) || null;
  state.slot = null;
  state.staffFilter = null;
  el("services").querySelectorAll("[data-service]").forEach((button) => {
    button.classList.toggle("on", button.dataset.service === id);
  });
  renderStaffChips();
  loadDays();
}

// "Cualquier profesional" (null) o un empleado concreto.
function renderStaffChips() {
  if (state.staff.length < 2) {
    el("staff-filter").hidden = true;
    return;
  }
  el("staff-filter").hidden = false;
  const options = [{ id: null, name: "Cualquiera" }].concat(state.staff);
  el("staff-chips").innerHTML = options.map((person) => `
    <button class="chip${state.staffFilter === person.id ? " on" : ""}"
            data-staff="${esc(person.id || "")}">${esc(person.name || person.display_name)}</button>`
  ).join("");
  el("staff-chips").querySelectorAll("[data-staff]").forEach((button) => {
    button.addEventListener("click", () => {
      state.staffFilter = button.dataset.staff || null;
      state.slot = null;
      renderStaffChips();
      loadSlots(state.day);
    });
  });
}

async function loadDays() {
  state.days = [];
  const total = Math.max(1, Math.min(state.daysAhead || 14, 21));
  for (let i = 0; i < total; i += 1) {
    state.days.push(bizDate(i));
  }
  el("days").innerHTML = state.days.map((iso) => {
    const label = dayLabel(iso);
    return `<button class="day" data-day="${iso}">
      <small>${esc(label.top)}</small><b>${esc(label.bottom)}</b></button>`;
  }).join("");
  el("days").querySelectorAll("[data-day]").forEach((button) => {
    button.addEventListener("click", () => loadSlots(button.dataset.day));
  });

  show("step-time");
  el("slots").innerHTML = '<div class="spinner"></div>';
  el("slots-empty").hidden = true;

  // Precarga los primeros días para abrir directamente el primero con cupo.
  const preview = state.days.slice(0, 5);
  const results = await Promise.all(preview.map((iso) => availability(iso).catch(() => [])));
  results.forEach((slots, index) => {
    const button = el("days").querySelector('[data-day="' + preview[index] + '"]');
    if (button && slots.length === 0) button.disabled = true;
  });
  const firstWithSlots = results.findIndex((slots) => slots.length > 0);
  if (firstWithSlots === -1) {
    el("slots").innerHTML = "";
    el("slots-empty").hidden = false;
    el("slots-empty").textContent = "No hay horarios libres estos días. Prueba otra fecha más adelante.";
    return;
  }
  const target = preview[firstWithSlots];
  await loadSlots(target, results[firstWithSlots]);
}

async function availability(iso) {
  let url = "/availability?service_id=" + encodeURIComponent(state.service.id)
    + "&date=" + encodeURIComponent(iso);
  if (state.staffFilter) url += "&staff_id=" + encodeURIComponent(state.staffFilter);
  const data = await api(url);
  const flat = [];
  (data.staff || []).forEach((person) => {
    (person.slots || []).forEach((slot) => {
      flat.push({ starts_at: slot.starts_at, ends_at: slot.ends_at,
                  staff_id: person.staff_id, staff_name: person.staff_name });
    });
  });
  flat.sort((a, b) => a.starts_at.localeCompare(b.starts_at));
  return flat;
}

// Agrupa por hora cuando no se eligió profesional: una fila por hora real.
function groupByTime(slots) {
  const byTime = new Map();
  slots.forEach((slot) => {
    const group = byTime.get(slot.starts_at);
    if (group) group.push(slot);
    else byTime.set(slot.starts_at, [slot]);
  });
  return Array.from(byTime.values());
}

async function loadSlots(iso, preloaded) {
  state.day = iso;
  el("days").querySelectorAll("[data-day]").forEach((button) => {
    button.classList.toggle("on", button.dataset.day === iso);
  });
  el("slots-empty").hidden = true;
  el("slots").innerHTML = '<div class="spinner"></div>';
  let slots = preloaded;
  if (!slots) {
    try { slots = await availability(iso); } catch (e) { slots = []; }
  }
  if (!slots.length) {
    el("slots").innerHTML = "";
    el("slots-empty").hidden = false;
    el("slots-empty").textContent = "Este día ya no tiene horarios libres.";
    return;
  }
  el("slots").innerHTML = groupByTime(slots).map((group) => {
    const first = group[0];
    const count = group.length;
    const subtitle = count > 1
      ? `<span class="count">${count} disponibles</span>`
      : `<small>${esc(first.staff_name)}</small>`;
    return `<button class="slot" data-slot="${esc(first.starts_at)}"
            data-staff="${count === 1 ? esc(first.staff_id) : ""}"
            data-staff-name="${count === 1 ? esc(first.staff_name) : ""}">
      ${esc(timeLabel(first.starts_at))}${subtitle}
    </button>`;
  }).join("");
  el("slots").querySelectorAll("[data-slot]").forEach((button) => {
    button.addEventListener("click", () => {
      state.slot = { starts_at: button.dataset.slot,
                     staff_id: button.dataset.staff || null,
                     staff_name: button.dataset.staffName || "" };
      el("slots").querySelectorAll("[data-slot]").forEach((other) => {
        other.classList.toggle("on", other === button);
      });
      goToData();
    });
  });
}

function goToData() {
  const currency = state.business.currency;
  el("picked").textContent = [
    state.service.name,
    dayOnlyLabel(state.day),
    timeLabel(state.slot.starts_at),
    state.slot.staff_name || "con quien esté libre",
    money(state.service.price, currency),
  ].filter(Boolean).join(" · ");
  show("step-data");
  el("f-name").focus({ preventScroll: true });
}

async function confirmBooking() {
  const button = el("confirm");
  const error = el("form-error");
  error.style.display = "none";
  button.disabled = true;
  button.textContent = "Reservando…";
  try {
    const created = await api("/appointments", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        service_id: state.service.id,
        staff_id: state.slot.staff_id || null,
        starts_at: state.slot.starts_at,
        client_name: el("f-name").value,
        client_phone: el("f-phone").value,
        notes: el("f-notes").value || null,
      }),
    });
    state.token = created.token;
    renderDone(created);
  } catch (e) {
    error.textContent = e.message;
    error.style.display = "block";
  } finally {
    button.disabled = false;
    button.textContent = "Confirmar cita";
  }
}

function summaryRows(appointment) {
  const currency = appointment.currency;
  const address = appointment.business_address;
  const mapRow = address
    ? `<dt>Dónde</dt><dd>${esc(address)}<br>
         <a href="${esc(mapsUrl(address, appointment.business_name))}" target="_blank"
            rel="noopener" style="font-weight:600">Ver en el mapa</a></dd>`
    : "";
  return `
    <dt>Negocio</dt><dd>${esc(appointment.business_name)}</dd>
    <dt>Servicio</dt><dd>${esc(appointment.service_name || "—")}</dd>
    <dt>Fecha</dt><dd>${esc(dateLabel(appointment.starts_at))} · ${esc(timeLabel(appointment.starts_at))}</dd>
    <dt>Con</dt><dd>${esc(appointment.staff_name || "Cualquier empleado")}</dd>
    <dt>Precio</dt><dd>${esc(money(appointment.price, currency))}</dd>
    ${mapRow}`;
}

function myLink(token) {
  return location.origin + "/r/" + encodeURIComponent(SLUG) + "?c=" + encodeURIComponent(token);
}

function renderDone(appointment) {
  bizTz = appointment.timezone || bizTz;
  el("done-lead").textContent = "Te esperamos. Guarda tu enlace para cualquier cambio.";
  el("done-summary").innerHTML = "<dl style='margin:0'>" + summaryRows(appointment) + "</dl>";
  const phone = (appointment.business_phone || "").replace(/[^0-9]/g, "");
  const wa = el("wa-business");
  if (phone) {
    wa.hidden = false;
    wa.href = "https://wa.me/" + phone + "?text="
      + encodeURIComponent("Hola, acabo de reservar una cita por el enlace.");
  }
  history.replaceState({}, "", myLink(appointment.token));
  show("step-done");
}

function renderMine(appointment) {
  bizTz = appointment.timezone || bizTz;
  el("mine-summary").innerHTML = "<dl style='margin:0'>" + summaryRows(appointment) + "</dl>";
  const statusText = appointment.status === "cancelada" ? "Cancelada"
    : appointment.status === "completada" ? "Completada" : "Confirmada";
  el("mine-summary").insertAdjacentHTML("beforeend",
    `<dt>Estado</dt><dd><span class="pill">${esc(statusText)}</span></dd>`);
  el("cancel-booking").hidden = !appointment.cancellable;
  el("new-booking").hidden = false;
  show("step-mine");
}

async function loadMine(token) {
  try {
    const appointment = await api("/appointments/" + encodeURIComponent(token));
    el("loading").hidden = true;
    renderMine(appointment);
  } catch (e) {
    el("loading").hidden = true;
    show("step-mine");
    el("mine-summary").innerHTML = '<p class="muted">' + esc(e.message) + "</p>";
    el("new-booking").hidden = false;
  }
}

async function cancelMine() {
  if (!confirm("¿Cancelar la cita?")) return;
  const error = el("mine-error");
  error.style.display = "none";
  try {
    const appointment = await api("/appointments/" + encodeURIComponent(state.token) + "/cancel",
      { method: "POST" });
    renderMine(appointment);
  } catch (e) {
    error.textContent = e.message;
    error.style.display = "block";
  }
}

async function copyLink() {
  const button = el("copy-link");
  const link = myLink(state.token);
  try {
    await navigator.clipboard.writeText(link);
    button.textContent = "¡Enlace copiado!";
  } catch (e) {
    window.prompt("Copia tu enlace:", link);
  }
  setTimeout(() => { button.textContent = "Copiar mi enlace"; }, 2500);
}

el("back-service").addEventListener("click", () => show("step-service"));
el("back-time").addEventListener("click", () => { show("step-time"); loadSlots(state.day); });
el("confirm").addEventListener("click", confirmBooking);
el("copy-link").addEventListener("click", copyLink);
el("cancel-booking").addEventListener("click", cancelMine);
el("new-booking").addEventListener("click", () => {
  state.token = null;
  state.staffFilter = null;
  history.replaceState({}, "", "/r/" + encodeURIComponent(SLUG));
  el("step-mine").hidden = true;
  renderServices();
});

function renderHeader(data) {
  const business = data.business;
  el("biz-name").textContent = business.name;
  el("biz-sub").textContent = industryLabel(business.industry);

  const hours = hoursLabel(data.hours);
  if (hours) {
    el("biz-hours").hidden = false;
    el("biz-hours").textContent = "🕘 " + hours;
  }

  if (business.address) {
    el("biz-address").hidden = false;
    el("biz-address").textContent = "📍 " + business.address;
  }

  const actions = [];
  if (business.phone) {
    const call = el("btn-call");
    call.hidden = false;
    call.href = "tel:" + business.phone.replace(/[^0-9+]/g, "");
    call.textContent = phoneLabel(business.phone);
    actions.push(call);
  }
  if (business.address) {
    const map = el("btn-map");
    map.hidden = false;
    map.href = mapsUrl(business.address, business.name);
    actions.push(map);
  }
  if (actions.length) el("biz-actions").hidden = false;

  document.title = "Reservar cita · " + business.name;
}

function notBookable(data) {
  el("loading").hidden = true;
  el("steps").hidden = true;
  el("not-bookable").hidden = false;
  const phone = (data.business.phone || "").replace(/[^0-9]/g, "");
  if (phone) {
    const wa = el("not-bookable-wa");
    wa.hidden = false;
    wa.href = "https://wa.me/" + phone + "?text="
      + encodeURIComponent("Hola, quiero reservar una cita.");
  }
}

(async function boot() {
  const params = new URLSearchParams(location.search);
  const token = params.get("c");
  if (token) { state.token = token; await loadMine(token); return; }

  try {
    const data = await api("");
    state.business = data.business;
    state.services = data.services || [];
    state.staff = data.staff || [];
    state.hours = data.hours || [];
    state.daysAhead = data.days_ahead || 21;
    bizTz = data.business.timezone;
    renderHeader(data);

    if (!data.bookable || !state.services.length) {
      notBookable(data);
      return;
    }

    el("loading").hidden = true;
    renderServices();
  } catch (e) {
    fatal(e.message);
  }
})();
</script>
</body>
</html>
"""
)


@router.get(
    "/r/{slug}",
    response_class=HTMLResponse,
    summary="Página pública de reservas del negocio",
)
def public_booking_page(
    slug: str, request: Request, conn: ConnectionDep
) -> HTMLResponse:
    """Sirve la página; los datos los pide el propio navegador a la API.

    Si el slug no existe se entrega igual la página: su JavaScript consulta la
    API y muestra el aviso de "enlace no disponible", que es mejor experiencia
    que un JSON de error.
    """
    try:
        business = load_business(conn, slug)
        name = business["name"]
    except HTTPException:
        name = "Reservar cita"

    base = str(request.base_url).rstrip("/")
    public_url = f"{base}/r/{slug}"
    description = (
        f"Reserva tu cita en {name} en menos de un minuto. "
        "Mira servicios, precios y horarios disponibles."
    )

    return HTMLResponse(
        _PAGE.safe_substitute(
            business_name=_escape(name),
            slug_json=json.dumps(slug),
            og_title=_escape(f"{name} · Reserva en línea"),
            og_description=_escape(description),
            public_url=_escape(public_url),
            og_image=_escape(f"{base}/og-cover.png"),
        )
    )


@router.get("/og-cover.png", include_in_schema=False)
def og_cover() -> FileResponse:
    """Imagen que se ve al compartir el enlace por WhatsApp o redes."""
    return FileResponse(
        _STATIC_DIR / "og-cover.png",
        media_type="image/png",
        headers={"Cache-Control": "public, max-age=604800"},
    )


def _escape(value: str) -> str:
    return (
        value.replace("&", "&amp;")
        .replace("<", "&lt;")
        .replace(">", "&gt;")
        .replace('"', "&quot;")
    )
