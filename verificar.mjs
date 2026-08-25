// Verificación de la plataforma. Un solo comando para cualquier agente.
//
//   npm run verificar          syntax + navegador (si hay)
//   npm run verificar -- --solo-sintaxis
//
// Códigos de salida:
//   0  todo bien
//   1  algo falló: NO publicar
//   2  no hay navegador disponible: la parte visual quedó sin probar,
//      así que NO publicar por cuenta propia (ver AGENTS.md).
//
// No escribe nada en la base: sólo abre la aplicación y mira.

import fs from 'node:fs';
import http from 'node:http';
import path from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

const RAIZ = path.dirname(fileURLToPath(import.meta.url));
const soloSintaxis = process.argv.includes('--solo-sintaxis');

const ok = (m) => console.log(`  ok    ${m}`);
const mal = (m) => console.log(`  FALLA ${m}`);
const info = (m) => console.log(`  ·     ${m}`);

// ------------------------------------------------------------------
// 1. Sintaxis de todos los <script> embebidos en index.html
// ------------------------------------------------------------------
console.log('\nSintaxis de index.html');
const html = fs.readFileSync(path.join(RAIZ, 'index.html'), 'utf8');
const scripts = [...html.matchAll(/<script[^>]*>([\s\S]*?)<\/script>/gi)].map((m) => m[1]);
let fallas = 0;

for (let i = 0; i < scripts.length; i++) {
  try {
    new Function(scripts[i]);
  } catch (e) {
    mal(`script ${i}: ${e.message}`);
    fallas++;
  }
}
if (fallas) {
  console.log('\nHay errores de sintaxis. No sigue.\n');
  process.exit(1);
}
ok(`${scripts.length} scripts sin errores de sintaxis`);

if (soloSintaxis) {
  console.log('\nSólo sintaxis, como se pidió.\n');
  process.exit(0);
}

// ------------------------------------------------------------------
// 2. ¿Hay navegador?
// ------------------------------------------------------------------
// El repo vive en Google Drive y ahí `node_modules` no se puede instalar
// (la sincronización pisa los archivos mientras npm escribe). Por eso se
// busca también la instalación global.
async function cargarPlaywright() {
  try {
    return await import('playwright');
  } catch { /* sigue abajo */ }
  try {
    const { execSync } = await import('node:child_process');
    const raizGlobal = execSync('npm root -g', { encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'] }).trim();
    const destino = path.join(raizGlobal, 'playwright', 'index.mjs');
    if (fs.existsSync(destino)) return await import(pathToFileURL(destino).href);
    const cjs = path.join(raizGlobal, 'playwright');
    if (fs.existsSync(cjs)) return await import(pathToFileURL(path.join(cjs, 'index.js')).href);
  } catch { /* sin navegador */ }
  return null;
}

const playwright = await cargarPlaywright();
const chromium = playwright?.chromium;

if (!chromium) {
  console.log(`
Sintaxis correcta, pero NO hay navegador en este entorno.

La parte visual quedó sin probar, así que este cambio no se puede dar
por terminado solo. Dejá el cambio sin comitear y decilo explícitamente
al cerrar, para que lo verifique quien sí tenga navegador.

Si esta máquina puede instalarlo (global, NO dentro del repo: la carpeta
está en Google Drive y ahí npm no puede escribir):
  npm install -g playwright
  npx playwright install chromium
`);
  process.exit(2);
}

// ------------------------------------------------------------------
// 3. Servidor local y navegador
// ------------------------------------------------------------------
const TIPOS = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.mjs': 'text/javascript; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
  '.woff2': 'font/woff2'
};

const servidor = http.createServer((req, res) => {
  const url = decodeURIComponent((req.url || '/').split('?')[0]);
  const destino = path.join(RAIZ, url === '/' ? 'index.html' : url);
  if (!destino.startsWith(RAIZ)) return res.writeHead(403).end('Prohibido');
  fs.readFile(destino, (err, buf) => {
    if (err) return res.writeHead(404).end('No encontrado');
    res.writeHead(200, {
      'Content-Type': TIPOS[path.extname(destino).toLowerCase()] || 'application/octet-stream',
      'Cache-Control': 'no-store'
    }).end(buf);
  });
});
await new Promise((r) => servidor.listen(0, r));
const base = `http://localhost:${servidor.address().port}`;

let navegador;
try {
  navegador = await chromium.launch();
} catch (e) {
  console.log(`\nPlaywright está instalado pero no pudo abrir Chromium:\n  ${e.message}`);
  console.log('\nProbá:  npx playwright install chromium\n');
  servidor.close();
  process.exit(2);
}

console.log('\nAplicación en el navegador');
const errores = [];
let salida = 0;

try {
  for (const [nombre, ancho, alto] of [['escritorio', 1280, 800], ['celular', 375, 812]]) {
    const ctx = await navegador.newContext({ viewport: { width: ancho, height: alto } });
    const pagina = await ctx.newPage();
    pagina.on('console', (m) => { if (m.type() === 'error') errores.push(`[${nombre}] ${m.text()}`); });
    pagina.on('pageerror', (e) => errores.push(`[${nombre}] ${e.message}`));

    await pagina.goto(base, { waitUntil: 'load', timeout: 60000 });

    // Esperar a que baje la información (la app lee la base real, sólo lectura).
    const datos = await pagina
      .waitForFunction(
        () => typeof OS_ZONA !== 'undefined' && OS_ZONA.length > 0,
        null,
        { timeout: 90000 }
      )
      .then(() => true)
      .catch(() => false);

    const estado = await pagina.evaluate(() => ({
      ordenes: typeof OS_ZONA !== 'undefined' ? OS_ZONA.length : 0,
      reclamos: typeof RECLAMOS_ZONA !== 'undefined' ? RECLAMOS_ZONA.length : 0,
      establecimientos: typeof ESTABS !== 'undefined' ? ESTABS.length : 0,
      desborde: document.documentElement.scrollWidth > document.documentElement.clientWidth + 1
    }));

    if (datos) ok(`${nombre}: ${estado.ordenes} órdenes · ${estado.reclamos} reclamos · ${estado.establecimientos} establecimientos`);
    else { mal(`${nombre}: la información no terminó de cargar`); salida = 1; }

    if (estado.desborde) { mal(`${nombre}: la página se desborda a lo ancho`); salida = 1; }
    else ok(`${nombre}: sin desborde horizontal`);

    await ctx.close();
  }
} finally {
  await navegador.close();
  servidor.close();
}

if (errores.length) {
  salida = 1;
  console.log('\nErrores de consola');
  [...new Set(errores)].slice(0, 15).forEach((e) => mal(e));
} else {
  ok('sin errores de consola');
}

console.log(salida === 0 ? '\nTodo bien.\n' : '\nHay fallas: no publicar.\n');
process.exit(salida);
