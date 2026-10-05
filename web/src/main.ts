import { Audio } from "./audio";
import { Game } from "./game/game";
import { loadFontDescriptor, loadImages } from "./render/assets";
import { BitmapFont } from "./render/font";
import { Painter } from "./render/painter";
import { Renderer } from "./render/renderer";

async function boot(): Promise<void> {
  const canvas = document.getElementById("game") as HTMLCanvasElement;
  const [images, fontDescriptor] = await Promise.all([loadImages(), loadFontDescriptor()]);
  const font = new BitmapFont(fontDescriptor, images.font);
  const painter = new Painter(images, font);
  const renderer = new Renderer(canvas, painter);
  const audio = new Audio();
  const game = new Game(audio);
  document.getElementById("loading")?.remove();

  const params = new URLSearchParams(location.search);
  if (params.has("mute")) audio.muted = true;
  if (params.has("seed") || params.has("table")) {
    game.startRun(Number(params.get("seed")) || undefined);
    const table = Number(params.get("table"));
    if (table > 0) game.loadTable(Math.min(table - 1, game.tables.length - 1));
  }

  const toLocal = (e: PointerEvent | MouseEvent) => {
    const r = canvas.getBoundingClientRect();
    return { x: e.clientX - r.left, y: e.clientY - r.top };
  };

  const onButton = (id: string) => {
    if (id === "start" || id === "new_run") game.startRun();
    else if (id === "continue") game.continueAfterTable();
    else if (id === "menu") game.state = "MAIN_MENU";
  };

  canvas.addEventListener("contextmenu", (e) => e.preventDefault());
  canvas.addEventListener("pointermove", (e) => {
    if (game.state === "MAIN_MENU" || !game.table) return;
    const s = toLocal(e);
    game.setPointer(renderer.screenToWorld(s.x, s.y));
  });
  canvas.addEventListener("pointerdown", (e) => {
    audio.unlock();
    const s = toLocal(e);
    const hit = renderer.hitButton(s.x, s.y);
    if (hit) {
      onButton(hit);
      return;
    }
    if (game.state === "MAIN_MENU" || !game.table) return;
    canvas.setPointerCapture(e.pointerId);
    game.setPointer(renderer.screenToWorld(s.x, s.y));
    game.pointerDown(e.button);
  });
  canvas.addEventListener("pointerup", (e) => {
    if (game.state === "MAIN_MENU" || !game.table) return;
    const s = toLocal(e);
    game.setPointer(renderer.screenToWorld(s.x, s.y));
    game.pointerUp(e.button);
  });
  window.addEventListener("keydown", (e) => {
    if (e.repeat) return;
    audio.unlock();
    if (e.code === "KeyD") console.log(game.debugText());
    else if (e.code === "Enter" && game.state === "TABLE_END") game.continueAfterTable();
    else game.key(e.code);
  });

  // Expose the game for headless tests and debugging, like the Godot browser test flags.
  (window as unknown as { hex: unknown }).hex = { game, renderer };

  let last = performance.now();
  const frame = (now: number) => {
    const dt = (now - last) / 1000;
    last = now;
    game.update(dt);
    renderer.render(game, dt);
    requestAnimationFrame(frame);
  };
  requestAnimationFrame(frame);
}

boot().catch((err) => {
  const el = document.getElementById("loading");
  if (el) el.textContent = `Failed to start: ${err instanceof Error ? err.message : String(err)}`;
  console.error(err);
});
