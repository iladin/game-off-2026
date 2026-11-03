// Browser smoke test of the exported build (build/web) in headless Chromium:
// boots the real HTML5 export, checks the console for the hub and for errors,
// clicks the first hub card, and saves screenshots to .tools/shots/browser/.
// Needs Node + Playwright (`npm i -D playwright && npx playwright install chromium`).
// Usage: node scripts/browser_check.mjs        (run ./scripts/export_web.sh first)
import { createServer } from "node:http";
import { readFile, mkdir } from "node:fs/promises";
import { extname, join, resolve } from "node:path";
import { createRequire } from "node:module";

const require = createRequire(import.meta.url);
let chromium;
try { ({ chromium } = require("playwright")); } catch {
  try { ({ chromium } = await import("playwright")); } catch {
    console.log("SKIP browser check: playwright not installed"); process.exit(0);
  }
}
const ROOT = resolve(new URL("..", import.meta.url).pathname);
const WEB = join(ROOT, "build", "web");
const OUT = join(ROOT, ".tools", "shots", "browser");
const TYPES = { ".html": "text/html", ".js": "text/javascript", ".wasm": "application/wasm",
  ".pck": "application/octet-stream", ".png": "image/png" };

const server = createServer(async (req, res) => {
  try {
    const path = join(WEB, decodeURIComponent(new URL(req.url, "http://x").pathname.replace(/\/$/, "/index.html")));
    const body = await readFile(path);
    res.writeHead(200, { "content-type": TYPES[extname(path)] || "application/octet-stream" });
    res.end(body);
  } catch { res.writeHead(404); res.end(); }
}).listen(0);
const port = server.address().port;
await mkdir(OUT, { recursive: true });

const browser = await chromium.launch({ args: ["--use-gl=angle", "--use-angle=swiftshader", "--enable-unsafe-swiftshader"] });
const page = await browser.newPage({ viewport: { width: 1280, height: 720 } });
const logs = [];
page.on("console", (m) => logs.push(m.text()));
page.on("pageerror", (e) => logs.push("PAGEERROR " + e.message));
await page.goto(`http://localhost:${port}/`);
const wait = async (re, ms) => {
  const end = Date.now() + ms;
  while (Date.now() < end) { if (logs.some((l) => re.test(l))) return true; await page.waitForTimeout(250); }
  return false;
};
let ok = await wait(/ARCADE hub/, 30000);
await page.screenshot({ path: join(OUT, "hub.png") });
if (ok) {
  // Focus the canvas (click empty space), open the selected hub game with Enter, play a few seconds.
  await page.mouse.click(640, 200); await page.waitForTimeout(300); await page.keyboard.press("Enter");
  const launched = await wait(/ARCADE launch/, 5000);
  await page.waitForTimeout(2500);
  await page.screenshot({ path: join(OUT, "game.png") });
  if (!launched) logs.push("NOTE no game launched from the hub (empty hub?)");
}
await browser.close(); server.close();
const bad = logs.filter((l) => /SCRIPT ERROR|PAGEERROR|Parse Error|Invalid call|^ERROR/.test(l));
for (const l of logs.filter((l) => /ARCADE|ERROR|NOTE/.test(l))) console.log(l);
if (!ok || bad.length) { console.log(`FAIL browser check${ok ? "" : ": hub never booted"}`); process.exit(1); }
console.log(`PASS browser check (screenshots in .tools/shots/browser/)`);
