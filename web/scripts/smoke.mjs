// Headless smoke test: builds nothing, expects `vite preview` or `vite` already serving.
// Usage: node scripts/smoke.mjs [url] [outDir]
import { chromium } from "playwright-core";
import { mkdirSync } from "node:fs";

const url = process.argv[2] ?? "http://localhost:4173/";
const out = process.argv[3] ?? "screenshots";
mkdirSync(out, { recursive: true });

const executablePath = process.env.CHROMIUM_PATH ?? "/opt/pw-browsers/chromium-1194/chrome-linux/chrome";
const browser = await chromium.launch({ executablePath });
const page = await browser.newPage({ viewport: { width: 1280, height: 800 } });
const errors = [];
page.on("pageerror", (e) => errors.push(String(e)));
page.on("console", (m) => m.type() === "error" && errors.push(m.text()));

await page.goto(url + "?mute");
await page.waitForFunction(() => window.hex);
await page.screenshot({ path: `${out}/01-menu.png` });

// Start a run through the menu button.
const start = await page.evaluate(() => window.hex.renderer.buttons.find((b) => b.id === "start")?.rect);
const ui = await page.evaluate(() => window.hex.renderer.uiScale);
await page.mouse.click((start.x + start.w / 2) * ui, (start.y + start.h / 2) * ui);
await page.waitForTimeout(400);
await page.screenshot({ path: `${out}/02-intro.png` });

// Dismiss the intro, then aim at the rack and charge a shot.
await page.mouse.click(640, 400);
const target = await page.evaluate(() => {
  const { game } = window.hex;
  const ball = game.world.balls.find((b) => b.kind === "normal");
  const r = window.hex.renderer;
  const sx = (ball.pos.x - r.camPosCurrent.x) * r.camZoomCurrent + innerWidth / 2;
  const sy = (ball.pos.y - r.camPosCurrent.y) * r.camZoomCurrent + innerHeight / 2;
  return { x: sx, y: sy };
});
await page.mouse.move(target.x, target.y);
await page.mouse.down();
await page.waitForTimeout(700);
await page.screenshot({ path: `${out}/03-aiming.png` });
await page.mouse.up();
await page.waitForTimeout(450);
await page.screenshot({ path: `${out}/04-motion.png` });
await page.waitForFunction(() => window.hex.game.state !== "SHOT_IN_MOTION", null, { timeout: 20000 });
await page.waitForTimeout(300);
await page.screenshot({ path: `${out}/05-resolved.png` });
const state = await page.evaluate(() => window.hex.game.debugText());
console.log(state);

// Jump to a few later tables to check special rooms render.
for (const t of [5, 13, 16]) {
  await page.goto(url + `?mute&seed=4242&table=${t}`);
  await page.waitForFunction(() => window.hex);
  await page.waitForTimeout(300);
  await page.keyboard.press("Space");
  await page.mouse.move(900, 300);
  await page.waitForTimeout(200);
  await page.screenshot({ path: `${out}/06-table-${t}.png` });
}

await browser.close();
if (errors.length) {
  console.error("Page errors:\n" + errors.join("\n"));
  process.exit(1);
}
console.log("Smoke test passed.");
