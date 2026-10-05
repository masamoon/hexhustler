# Hex Hustler (web port)

TypeScript + Vite port of the Godot game in the repo root. The Godot project is untouched; this build reads the same PNG/font assets from `../assets`.

```sh
npm install
npm run dev        # http://localhost:5173  (?seed=123, ?table=5, ?mute)
npm test           # physics/pocket tests + headless autoplay bot
npm run build      # typecheck + production build into dist/
npm run smoke      # screenshot pass in headless Chromium (needs `npm run preview` running)
```

Layout: `src/game` (rules, physics, tables, scoring; no DOM), `src/render` (canvas renderer over the original atlases), `src/audio.ts` (procedural WebAudio), `src/data` (generated from the GDScript dictionaries by `tools/extract_gd_data.py`).

Ported: the full 16-table run (3 biomes + Lucien's final), physics and pocket capture, every ball kind, bosses, modifiers, scoring/tags, receipts, cash/debt, spin, called pockets, last-ball drama, FX and sound.

Not ported yet: the shop and reward drafts between tables, relics beyond Money Ball, chalk, cue/board scoring effects, Lucien's dares and meta progression.
