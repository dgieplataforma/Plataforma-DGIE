import fs from 'node:fs';
import path from 'node:path';
import { execSync } from 'node:child_process';
import { pathToFileURL } from 'node:url';

const ROOT = 'I:/Mi unidad/PLATAFORMA DGIE';
const OUT = path.join(ROOT, 'portfolio-linkedin');
const globalRoot = execSync('npm root -g', { encoding: 'utf8' }).trim();
const { chromium } = await import(pathToFileURL(path.join(globalRoot, 'playwright', 'index.mjs')).href);
const source = fs.readFileSync(path.join(ROOT, 'index.html'), 'utf8');
const appCss = [...source.matchAll(/<style[^>]*>([\s\S]*?)<\/style>/gi)].map(m => m[1]).join('\n');

const extraCss = `
  html,body{width:100%;height:100%;overflow:hidden;background:#dfe7f0}
  body{margin:0}.app.demo-shell{width:1280px;max-width:1280px;height:900px;min-height:900px;margin:0 auto;overflow:hidden;background:#f7f9fc}
  .demo-shell .topbar{position:relative}.demo-shell .content{height:785px;min-height:0;overflow:hidden;padding:20px 22px}
  .demo-brand-mark{width:42px;height:42px;border-radius:12px;background:linear-gradient(145deg,#005aa9,#00a3e0);color:white;display:grid;place-items:center;font-weight:950;font-size:14px;letter-spacing:-.5px;box-shadow:0 7px 16px rgba(0,90,169,.22)}
  .demo-view-head{display:flex;align-items:flex-start;justify-content:space-between;gap:18px;margin-bottom:16px}
  .demo-title{font-size:23px;font-weight:950;color:#123c69;line-height:1.1}.demo-subtitle{font-size:13px;color:#64748b;margin-top:5px}
  .demo-tag{font-size:11px;font-weight:850;color:#47627e;background:#edf4fa;border:1px solid #d7e4f0;padding:6px 9px;border-radius:999px;white-space:nowrap}
  .demo-shell .metric-card{padding:15px 17px}.demo-shell .metric-val{font-size:30px}.demo-shell .metrics-grid{gap:12px;margin-bottom:14px}
  .demo-shell .card{padding:17px;border-radius:15px;margin-bottom:0}.demo-shell .card-title{font-size:15px}
  .demo-grid-2{display:grid;grid-template-columns:1.22fr .78fr;gap:14px}.demo-grid-even{display:grid;grid-template-columns:1fr 1fr;gap:14px}
  .demo-row{display:flex;align-items:center;gap:10px}.demo-between{display:flex;align-items:center;justify-content:space-between;gap:12px}
  .demo-muted{font-size:12px;color:#64748b}.demo-strong{font-weight:900;color:#183b5b}.demo-mini{font-size:11px;color:#64748b}
  .demo-progress{height:8px;background:#e8eef5;border-radius:999px;overflow:hidden}.demo-progress>i{display:block;height:100%;border-radius:999px;background:linear-gradient(90deg,#005aa9,#00a3e0)}
  .demo-bars{height:212px;display:flex;align-items:flex-end;gap:18px;padding:15px 8px 0;border-bottom:1px solid #dbe4ee;background:repeating-linear-gradient(to top,#edf2f7 0,#edf2f7 1px,transparent 1px,transparent 50px)}
  .demo-bar-col{flex:1;height:100%;display:flex;flex-direction:column;justify-content:flex-end;align-items:center;gap:7px}.demo-bar{width:62%;min-width:28px;border-radius:8px 8px 3px 3px;background:linear-gradient(180deg,#00a3e0,#005aa9);box-shadow:0 5px 12px rgba(0,90,169,.16)}
  .demo-bar.alt{background:linear-gradient(180deg,#48bb78,#218838)}.demo-bar.warn{background:linear-gradient(180deg,#ffbd59,#d97706)}
  .demo-bar-label{font-size:11px;color:#64748b;font-weight:750}.demo-bar-value{font-size:11px;color:#123c69;font-weight:900}
  .demo-donut{width:178px;height:178px;border-radius:50%;background:conic-gradient(#218838 0 46%,#0072ce 46% 74%,#f3a11a 74% 91%,#dc3545 91%);position:relative;margin:8px auto}.demo-donut:after{content:'';position:absolute;inset:34px;background:white;border-radius:50%;box-shadow:inset 0 0 0 1px #e5edf5}.demo-donut-label{position:absolute;inset:0;z-index:1;display:grid;place-content:center;text-align:center;color:#123c69;font-weight:950;font-size:23px}.demo-donut-label small{font-size:11px;color:#64748b;font-weight:750}
  .demo-legend{display:grid;grid-template-columns:1fr 1fr;gap:9px 14px;margin-top:6px}.demo-legend span{font-size:11px;color:#52677e}.demo-legend i{display:inline-block;width:9px;height:9px;border-radius:50%;margin-right:6px}
  .demo-activity{display:flex;gap:11px;padding:10px 0;border-bottom:1px solid #e8eef5}.demo-activity:last-child{border:0}.demo-activity-icon{width:32px;height:32px;flex:0 0 32px;border-radius:9px;display:grid;place-items:center;background:#e6f1fb;color:#005aa9;font-weight:900}
  .demo-filters{display:flex;gap:9px;flex-wrap:wrap;margin-bottom:12px}.demo-filter{padding:8px 11px;border:1px solid #d9e2ef;border-radius:10px;background:white;color:#475569;font-size:12px;font-weight:800}.demo-filter.active{background:#e6f1fb;border-color:#96bee4;color:#005aa9}
  .demo-intervention{background:white;border:1px solid #dbe4ee;border-radius:14px;padding:14px 16px;margin-bottom:10px;display:grid;grid-template-columns:1.25fr .72fr .72fr auto;gap:14px;align-items:center;box-shadow:0 5px 16px rgba(15,23,42,.04)}
  .demo-intervention:last-child{margin-bottom:0}.demo-school{font-size:14px;font-weight:950;color:#173b60}.demo-code{font-size:11px;color:#6b7d90;margin-top:3px}.demo-task{font-size:12px;color:#354b63;line-height:1.4}
  .demo-timeline{display:flex;align-items:center;margin-top:8px}.demo-step{position:relative;flex:1;text-align:center;font-size:10px;color:#6b7d90;padding-top:21px}.demo-step:before{content:'';position:absolute;top:2px;left:50%;width:13px;height:13px;border-radius:50%;background:#cbd7e4;border:3px solid white;box-shadow:0 0 0 1px #cbd7e4}.demo-step:after{content:'';position:absolute;top:9px;left:calc(50% + 9px);right:calc(-50% + 9px);height:2px;background:#dbe4ee}.demo-step:last-child:after{display:none}.demo-step.done:before{background:#218838;box-shadow:0 0 0 1px #218838}.demo-step.done:after{background:#6ab477}.demo-step.current:before{background:#0072ce;box-shadow:0 0 0 2px #b8d8f4}
  .demo-measure{border:1px solid #dbe4ee;border-radius:14px;background:white;padding:14px;margin-bottom:11px}.demo-measure:last-child{margin:0}.demo-measure-grid{display:grid;grid-template-columns:1.2fr .65fr .65fr .8fr;gap:12px;align-items:center}
  .demo-file{display:flex;align-items:center;gap:8px;color:#005aa9;font-size:12px;font-weight:800}.demo-file-icon{width:29px;height:33px;border-radius:6px;background:#e6f1fb;display:grid;place-items:center;font-size:10px;color:#005aa9}
  .demo-budget-grid{display:grid;grid-template-columns:repeat(5,1fr);gap:9px;margin-top:11px}.demo-budget{background:#f7fafc;border:1px solid #e2eaf2;border-radius:10px;padding:9px}.demo-budget b{display:block;color:#123c69;font-size:13px}.demo-budget span{font-size:10px;color:#64748b}
  .demo-analytics{display:grid;grid-template-columns:1.05fr .95fr;gap:14px}.demo-hbars{display:grid;gap:11px;margin-top:15px}.demo-hbar-row{display:grid;grid-template-columns:95px 1fr 35px;gap:9px;align-items:center;font-size:11px;color:#52677e}.demo-hbar-track{height:11px;background:#edf2f7;border-radius:999px;overflow:hidden}.demo-hbar-track i{display:block;height:100%;border-radius:999px;background:linear-gradient(90deg,#005aa9,#00a3e0)}
  .demo-comm-grid{display:grid;grid-template-columns:.77fr 1.23fr;gap:14px}.demo-thread{border:1px solid #dbe4ee;border-radius:14px;background:#f9fbfd;padding:14px}.demo-message{max-width:82%;padding:10px 12px;border-radius:12px;margin-bottom:9px;font-size:12px;line-height:1.45}.demo-message.admin{background:#fff0e8;border:1px solid #f5d2bf;color:#704229}.demo-message.inspector{margin-left:auto;background:#e6f1fb;border:1px solid #c7def3;color:#174a72}.demo-message.company{background:#eef8ef;border:1px solid #cce7ce;color:#245c29}.demo-message small{display:block;margin-bottom:3px;font-size:10px;font-weight:900;opacity:.8}
  .demo-file-row{display:flex;align-items:center;justify-content:space-between;gap:9px;padding:10px 0;border-bottom:1px solid #e6edf4}.demo-file-row:last-child{border:0}.demo-pill{font-size:10px;border-radius:999px;padding:4px 7px;font-weight:900;background:#eef2f7;color:#52677e}
  .demo-callout{border-left:4px solid #218838;background:#edf8ef;color:#245c29;border-radius:10px;padding:11px 13px;font-size:12px;font-weight:750}
  .demo-shell table{font-size:11px}.demo-shell .os-table th{padding:10px}.demo-shell .os-table td{padding:9px 10px}
`;

const navs = ['Dashboard','Gestión','Seguimiento','Indicadores','Comunicaciones'];
const brand = `<div class="topbar-brand"><div class="demo-brand-mark">DGIE</div><div><div class="brand-text">Plataforma de Infraestructura Educativa</div><div class="brand-sub">Gestión integral y trazabilidad</div></div></div>`;

function shell(active, title, subtitle, body) {
  return `<!doctype html><html lang="es"><head><meta charset="utf-8"><style>${appCss}\n${extraCss}</style></head><body><div class="app demo-shell">
    <div class="topbar">${brand}<div class="topbar-right"><span class="demo-tag">Vista provincial</span><div class="user-chip"><div class="avatar">CO</div><div><div style="font-size:12px;font-weight:900;color:#173b60">Coordinación Demo</div><div style="font-size:10px;color:#64748b">Sesión de presentación</div></div></div></div></div>
    <div class="nav-tabs">${navs.map(n=>`<div class="tab ${n===active?'active':''}">${n}</div>`).join('')}</div>
    <main class="content"><div class="demo-view-head"><div><div class="demo-title">${title}</div><div class="demo-subtitle">${subtitle}</div></div><span class="demo-tag">Actualizado hoy · 10:30</span></div>${body}</main>
  </div></body></html>`;
}

const dashboard = shell('Dashboard','Dashboard provincial','Resumen ejecutivo de infraestructura educativa y mantenimiento preventivo.',`
  <div class="metrics-grid" style="grid-template-columns:repeat(5,1fr)">
    <div class="metric-card"><div class="metric-lbl">Establecimientos</div><div class="metric-val">428</div><span class="badge b-info">17 zonas</span></div>
    <div class="metric-card"><div class="metric-lbl">Reclamos activos</div><div class="metric-val v-warn">36</div><span class="demo-mini">−12% este mes</span></div>
    <div class="metric-card"><div class="metric-lbl">Órdenes en curso</div><div class="metric-val v-info">24</div><span class="demo-mini">8 con prioridad alta</span></div>
    <div class="metric-card"><div class="metric-lbl">Intervenciones</div><div class="metric-val">157</div><span class="demo-mini">92% documentadas</span></div>
    <div class="metric-card"><div class="metric-lbl">Finalizadas</div><div class="metric-val v-ok">311</div><span class="demo-mini">Últimos 12 meses</span></div>
  </div>
  <div class="demo-grid-2">
    <div class="card"><div class="card-header"><div><div class="card-title">Actividad mensual</div><div class="demo-muted">Órdenes iniciadas y finalizadas</div></div><span class="badge b-info">2026</span></div>
      <div class="demo-bars">${[['Ene',48,39],['Feb',62,52],['Mar',74,64],['Abr',58,55],['May',83,71],['Jun',70,68],['Jul',91,77],['Ago',76,73]].map(([m,a,b])=>`<div class="demo-bar-col"><div class="demo-row" style="height:170px;align-items:flex-end;gap:4px"><div class="demo-bar" style="height:${a}%"></div><div class="demo-bar alt" style="height:${b}%"></div></div><div class="demo-bar-label">${m}</div></div>`).join('')}</div>
      <div class="demo-row" style="justify-content:center;margin-top:12px"><span class="demo-mini"><i style="display:inline-block;width:9px;height:9px;background:#0072ce;border-radius:2px;margin-right:5px"></i>Iniciadas</span><span class="demo-mini"><i style="display:inline-block;width:9px;height:9px;background:#218838;border-radius:2px;margin-right:5px"></i>Finalizadas</span></div>
    </div>
    <div style="display:grid;grid-template-rows:1fr 1fr;gap:14px">
      <div class="card"><div class="card-header"><div class="card-title">Estado de órdenes</div><span class="badge b-ok">76% resueltas</span></div><div class="demo-row"><div class="demo-donut" style="width:138px;height:138px"><div class="demo-donut-label">412<small>órdenes</small></div></div><div class="demo-legend" style="flex:1"><span><i style="background:#218838"></i>Finalizadas · 189</span><span><i style="background:#0072ce"></i>En ejecución · 115</span><span><i style="background:#f3a11a"></i>Pendientes · 70</span><span><i style="background:#dc3545"></i>Críticas · 38</span></div></div></div>
      <div class="card"><div class="card-header"><div class="card-title">Actividad reciente</div><span class="secondary-btn">Ver seguimiento</span></div>
        <div class="demo-activity"><div class="demo-activity-icon">✓</div><div><div class="demo-strong" style="font-size:12px">Medición Nº 08 finalizada</div><div class="demo-mini">Zona Demo 03 · 14 certificados procesados</div></div><span class="badge b-ok" style="margin-left:auto">Completa</span></div>
        <div class="demo-activity"><div class="demo-activity-icon">OS</div><div><div class="demo-strong" style="font-size:12px">Nueva orden en ejecución</div><div class="demo-mini">Escuela Demo Norte · Cubiertas</div></div><span class="badge b-info" style="margin-left:auto">En curso</span></div>
        <div class="demo-activity"><div class="demo-activity-icon">!</div><div><div class="demo-strong" style="font-size:12px">Reclamo priorizado</div><div class="demo-mini">Instituto Modelo 01 · Instalación eléctrica</div></div><span class="badge b-warn" style="margin-left:auto">Alta</span></div>
      </div>
    </div>
  </div>`);

const gestion = shell('Gestión','Gestión de intervenciones','Seguimiento operativo de obras, visitas técnicas y órdenes asociadas.',`
  <div class="demo-filters"><span class="demo-filter active">Todas · 18</span><span class="demo-filter">En ejecución · 7</span><span class="demo-filter">Pendientes · 4</span><span class="demo-filter">Finalizadas · 7</span><span class="demo-filter" style="margin-left:auto">Zona Demo 03⌄</span><span class="primary-btn" style="padding:8px 12px">Nueva intervención</span></div>
  <div class="card" style="padding:14px 16px;margin-bottom:12px"><div class="demo-between"><div><div class="card-title">Intervenciones activas</div><div class="demo-muted">Priorizadas por estado y última actualización</div></div><div class="demo-muted">18 resultados</div></div></div>
  <div class="demo-intervention"><div><div class="demo-school">Escuela Demo Norte</div><div class="demo-code">INT-DEMO-018 · Zona Demo 03</div></div><div class="demo-task"><b>Cubiertas y desagües</b><br>Reparación preventiva de cubierta</div><div><div class="demo-muted">Progreso</div><div class="demo-progress" style="margin:6px 0"><i style="width:72%"></i></div><div class="demo-mini">3 de 4 visitas</div></div><div style="text-align:right"><span class="badge b-info">En ejecución</span><div class="demo-mini" style="margin-top:7px">Actualizada hoy</div></div></div>
  <div class="demo-intervention"><div><div class="demo-school">Instituto Modelo 01</div><div class="demo-code">INT-DEMO-015 · Zona Demo 03</div></div><div class="demo-task"><b>Instalación eléctrica</b><br>Adecuación de tablero principal</div><div><div class="demo-muted">Progreso</div><div class="demo-progress" style="margin:6px 0"><i style="width:48%"></i></div><div class="demo-mini">2 de 5 visitas</div></div><div style="text-align:right"><span class="badge b-warn">Prioridad alta</span><div class="demo-mini" style="margin-top:7px">Ayer · 16:40</div></div></div>
  <div class="demo-intervention"><div><div class="demo-school">Centro Educativo Demo Sur</div><div class="demo-code">INT-DEMO-012 · Zona Demo 05</div></div><div class="demo-task"><b>Instalación sanitaria</b><br>Renovación de núcleo sanitario</div><div><div class="demo-muted">Progreso</div><div class="demo-progress" style="margin:6px 0"><i style="width:100%;background:#218838"></i></div><div class="demo-mini">5 de 5 visitas</div></div><div style="text-align:right"><span class="badge b-ok">Finalizada</span><div class="demo-mini" style="margin-top:7px">Hace 2 días</div></div></div>
  <div class="demo-intervention"><div><div class="demo-school">Jardín Modelo Arcoíris</div><div class="demo-code">INT-DEMO-009 · Zona Demo 08</div></div><div class="demo-task"><b>Carpinterías</b><br>Relevamiento y presupuesto</div><div><div class="demo-muted">Progreso</div><div class="demo-progress" style="margin:6px 0"><i style="width:22%;background:#f3a11a"></i></div><div class="demo-mini">1 de 3 visitas</div></div><div style="text-align:right"><span class="badge b-neutral">Pendiente</span><div class="demo-mini" style="margin-top:7px">Hace 3 días</div></div></div>
  <div class="card" style="margin-top:12px;padding:14px"><div class="demo-between"><div class="demo-row"><span class="badge b-info">Trazabilidad</span><span class="demo-muted">Cada intervención conserva visitas, comentarios, fotos y órdenes vinculadas.</span></div><span class="secondary-btn">Exportar listado</span></div></div>`);

const seguimiento = shell('Seguimiento','Certificaciones y mediciones','Liquidación dinámica basada en certificados vigentes, con respaldo firmado obligatorio.',`
  <div class="metrics-grid" style="grid-template-columns:repeat(5,1fr)"><div class="metric-card"><div class="metric-lbl">Presupuesto de módulos</div><div class="metric-val">24.600</div></div><div class="metric-card"><div class="metric-lbl">Consumidos</div><div class="metric-val v-info">9.845</div><div class="demo-progress" style="margin-top:8px"><i style="width:40%"></i></div></div><div class="metric-card"><div class="metric-lbl">Disponibles</div><div class="metric-val v-ok">14.755</div></div><div class="metric-card"><div class="metric-lbl">Mediciones cerradas</div><div class="metric-val">8</div></div><div class="metric-card"><div class="metric-lbl">Certificados vigentes</div><div class="metric-val">47</div></div></div>
  <div class="demo-grid-2">
    <div class="card"><div class="card-header"><div><div class="card-title">Medición Nº 09 · Vista preliminar</div><div class="demo-muted">Se actualiza al incorporar certificados</div></div><span class="badge b-info">Abierta</span></div>
      <div class="demo-measure"><div class="demo-measure-grid"><div><div class="demo-school">Escuela Demo Norte</div><div class="demo-code">CERT-DEMO-023 · Versión vigente</div></div><div class="demo-file"><span class="demo-file-icon">XLS</span>Certificado_023.xlsx</div><div><div class="demo-muted">Módulos</div><div class="demo-strong">684,32</div></div><span class="badge b-ok">Leído</span></div></div>
      <div class="demo-measure"><div class="demo-measure-grid"><div><div class="demo-school">Instituto Modelo 01</div><div class="demo-code">CERT-DEMO-024 · Versión vigente</div></div><div class="demo-file"><span class="demo-file-icon">XLS</span>Certificado_024.xlsx</div><div><div class="demo-muted">Módulos</div><div class="demo-strong">512,18</div></div><span class="badge b-ok">Leído</span></div></div>
      <div class="demo-callout" style="margin-top:12px">El PDF firmado es respaldo obligatorio para finalizar. Los módulos y rubros se calculan desde los certificados vigentes.</div>
    </div>
    <div class="card"><div class="card-header"><div><div class="card-title">Flujo de la medición</div><div class="demo-muted">Control completo antes del cómputo</div></div><span class="badge b-warn">En revisión</span></div>
      <div class="demo-timeline"><div class="demo-step done">Certificados</div><div class="demo-step done">Lectura</div><div class="demo-step current">Liquidación</div><div class="demo-step">PDF firmado</div><div class="demo-step">Finalizada</div></div>
      <div style="margin-top:20px"><div class="demo-between"><span class="demo-muted">Total preliminar</span><b class="demo-strong">1.196,50 módulos</b></div><div class="demo-budget-grid"><div class="demo-budget"><b>318,20</b><span>Materiales</span></div><div class="demo-budget"><b>286,10</b><span>Mano de obra</span></div><div class="demo-budget"><b>244,80</b><span>Equipos</span></div><div class="demo-budget"><b>205,40</b><span>Servicios</span></div><div class="demo-budget"><b>142,00</b><span>Otros</span></div></div></div>
      <div class="demo-between" style="margin-top:17px;padding-top:14px;border-top:1px solid #e5edf5"><div class="demo-file"><span class="demo-file-icon" style="background:#fdecec;color:#b42318">PDF</span><div><div>Medicion_09_firmada.pdf</div><div class="demo-mini">Pendiente de carga</div></div></div><span class="secondary-btn">Subir respaldo</span></div>
    </div>
  </div>`);

const indicadores = shell('Indicadores','Indicadores de gestión','Lectura comparativa por zonas, estados y rubros para la toma de decisiones.',`
  <div class="metrics-grid" style="grid-template-columns:repeat(4,1fr)"><div class="metric-card"><div class="metric-lbl">Resolución promedio</div><div class="metric-val v-ok">18 días</div><span class="demo-mini">−3 días vs. trimestre anterior</span></div><div class="metric-card"><div class="metric-lbl">Cumplimiento</div><div class="metric-val v-info">87%</div><span class="demo-mini">Objetivo: 85%</span></div><div class="metric-card"><div class="metric-lbl">Alta prioridad</div><div class="metric-val v-warn">14</div><span class="demo-mini">4 requieren seguimiento</span></div><div class="metric-card"><div class="metric-lbl">Zonas activas</div><div class="metric-val">17</div><span class="demo-mini">Cobertura provincial</span></div></div>
  <div class="demo-analytics"><div class="card"><div class="card-header"><div><div class="card-title">Evolución de resolución</div><div class="demo-muted">Casos finalizados por mes</div></div><span class="badge b-ok">+18% interanual</span></div><div class="demo-bars" style="height:250px">${[['Ene',49],['Feb',58],['Mar',64],['Abr',61],['May',72],['Jun',78],['Jul',88],['Ago',93]].map(([m,v])=>`<div class="demo-bar-col"><div class="demo-bar-value">${v}</div><div class="demo-bar alt" style="height:${v}%"></div><div class="demo-bar-label">${m}</div></div>`).join('')}</div></div>
    <div class="card"><div class="card-header"><div><div class="card-title">Distribución por estado</div><div class="demo-muted">Universo de seguimiento</div></div><span class="badge b-info">412 casos</span></div><div class="demo-row"><div class="demo-donut"><div class="demo-donut-label">87%<small>cumplimiento</small></div></div><div class="demo-legend" style="flex:1"><span><i style="background:#218838"></i>Finalizados · 46%</span><span><i style="background:#0072ce"></i>En ejecución · 28%</span><span><i style="background:#f3a11a"></i>Pendientes · 17%</span><span><i style="background:#dc3545"></i>Críticos · 9%</span></div></div></div></div>
  <div class="demo-grid-even" style="margin-top:14px"><div class="card"><div class="card-title">Demanda por rubro</div><div class="demo-hbars">${[['Cubiertas',84],['Sanitaria',71],['Eléctrica',62],['Carpinterías',48],['Pintura',39]].map(([n,v])=>`<div class="demo-hbar-row"><span>${n}</span><div class="demo-hbar-track"><i style="width:${v}%"></i></div><b>${v}</b></div>`).join('')}</div></div><div class="card"><div class="card-title">Cumplimiento por zona demo</div><div class="demo-hbars">${[['Zona Demo 03',92],['Zona Demo 05',89],['Zona Demo 08',86],['Zona Demo 11',82],['Zona Demo 14',78]].map(([n,v])=>`<div class="demo-hbar-row"><span>${n}</span><div class="demo-hbar-track"><i style="width:${v}%;background:linear-gradient(90deg,#218838,#55b96a)"></i></div><b>${v}%</b></div>`).join('')}</div></div></div>`);

const comunicaciones = shell('Comunicaciones','Trazabilidad de comunicaciones','Conversaciones, decisiones y versiones documentales reunidas en un mismo expediente.',`
  <div class="demo-comm-grid"><div><div class="card" style="margin-bottom:14px"><div class="card-header"><div><div class="card-title">CERT-DEMO-023</div><div class="demo-muted">Escuela Demo Norte · Medición Nº 09</div></div><span class="badge b-warn">Observado</span></div><div class="demo-callout">Administración solicitó una aclaración. El inspector respondió y la conversación permanece disponible.</div><div class="demo-timeline" style="margin-top:15px"><div class="demo-step done">Enviado</div><div class="demo-step done">Observado</div><div class="demo-step current">Respondido</div><div class="demo-step">Finalizado</div></div></div>
    <div class="card"><div class="card-header"><div class="card-title">Historial de archivos</div><span class="badge b-info">3 versiones</span></div><div class="demo-file-row"><div class="demo-file"><span class="demo-file-icon">XLS</span><div><b>Certificado_original.xlsx</b><div class="demo-mini">Empresa Demo · 20/08/2026</div></div></div><span class="demo-pill">Original</span></div><div class="demo-file-row"><div class="demo-file"><span class="demo-file-icon">XLS</span><div><b>Revision_inspector.xlsx</b><div class="demo-mini">Inspector 01 · 22/08/2026</div></div></div><span class="demo-pill">Revisión</span></div><div class="demo-file-row"><div class="demo-file"><span class="demo-file-icon">XLS</span><div><b>Certificado_vigente.xlsx</b><div class="demo-mini">Inspector 01 · 25/08/2026</div></div></div><span class="badge b-ok">Vigente</span></div></div></div>
    <div class="card"><div class="card-header"><div><div class="card-title">Conversación con Administración</div><div class="demo-muted">Registro visible para las partes autorizadas</div></div><span class="badge b-info">Respuesta recibida</span></div><div class="demo-thread"><div class="demo-message admin"><small>Administración · 25/08/2026 · 09:55</small>Revisar el criterio aplicado en el ítem de instalaciones y confirmar el alcance certificado.</div><div class="demo-message inspector"><small>Inspector 01 · 25/08/2026 · 11:20</small>Se verificó en obra. El alcance coincide con lo ejecutado y se adjunta una nueva versión con la aclaración incorporada.</div><div class="demo-message admin"><small>Administración · 26/08/2026 · 08:40</small>Respuesta recibida. La documentación quedó lista para continuar con la medición.</div></div><div class="demo-between" style="margin-top:12px"><div class="demo-row"><span class="badge b-ok">Registro completo</span><span class="demo-muted">Mensajes y archivos conservados</span></div><span class="primary-btn" style="padding:9px 13px">Finalizar observación</span></div></div></div>
  <div class="card" style="margin-top:14px;padding:13px 16px"><div class="demo-between"><div class="demo-row"><span class="demo-activity-icon">↻</span><div><div class="demo-strong" style="font-size:12px">Trazabilidad sin pérdidas</div><div class="demo-mini">Cada respuesta, cambio de estado y versión del certificado queda asociada a la medición.</div></div></div><span class="secondary-btn">Descargar certificado vigente</span></div></div>`);

const views = [
  ['01-dashboard.png', dashboard],
  ['02-gestion.png', gestion],
  ['03-seguimiento.png', seguimiento],
  ['04-indicadores.png', indicadores],
  ['05-funcionalidad-destacada.png', comunicaciones]
];

const forbidden = [
  /[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}/i,
  /\b[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\b/i,
  /https?:\/\//i,
  /\bCUE\b/i,
  /supabase|cloudinary/i,
  /Mat[ií]as Soler|Carlos Saavedra Lamas|Ra[uú]l [AÁ]ngel Ferreyra|Coronel Olmedo|Abalseiro/i
];

const browser = await chromium.launch({ headless: true });
const page = await browser.newPage({ viewport: { width: 1440, height: 900 }, deviceScaleFactor: 1 });
const consoleErrors = [];
page.on('console', msg => { if (msg.type() === 'error') consoleErrors.push(msg.text()); });
page.on('pageerror', error => consoleErrors.push(error.message));

for (const [name, html] of views) {
  await page.setContent(html, { waitUntil: 'load' });
  await page.evaluate(() => document.fonts?.ready);
  const visible = await page.locator('body').innerText();
  const hit = forbidden.find(rx => rx.test(visible));
  if (hit) throw new Error(`Privacidad: ${name} contiene un patrón prohibido: ${hit}`);
  const links = await page.locator('a').evaluateAll(nodes => nodes.map(n => n.getAttribute('href')).filter(Boolean));
  if (links.some(href => /https?:|file:|blob:/i.test(href))) throw new Error(`Privacidad: ${name} contiene un enlace externo`);
  const layout = await page.evaluate(() => ({ width: document.documentElement.scrollWidth, height: document.documentElement.scrollHeight }));
  if (layout.width > 1440 || layout.height > 900) throw new Error(`Diseño fuera del lienzo en ${name}: ${JSON.stringify(layout)}`);
  await page.screenshot({ path: path.join(OUT, name), type: 'png' });
  console.log(`OK ${name} · ${visible.length} caracteres visibles · ${layout.width}x${layout.height}`);
}

await browser.close();
if (consoleErrors.length) throw new Error('Errores de consola: ' + consoleErrors.join(' | '));
console.log('PRIVACIDAD_OK · sin correos, teléfonos, UUID, URLs, CUE, tecnologías internas ni nombres reales conocidos');
