import { defineConfig } from "vite";

// The Godot project's art lives in ../assets and is served as-is, so both
// versions of the game share one copy of every sprite atlas and the font.
export default defineConfig({
  base: "./",
  publicDir: "../assets",
  build: { outDir: "dist", assetsInlineLimit: 0 },
  test: { include: ["tests/**/*.test.ts"] },
});
