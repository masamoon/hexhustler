# HexHustler Beta Testing Notes

HexHustler is a single-player roguelite trick-shot pool prototype set in a cursed casino back room. The current beta target is a readable 5-table contract with unlockable cues, boards, relic drafts, chalk tools, hover help, and enough run feedback to report useful issues.

## Launch

From this repo:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path /Users/andrelopes/hex-hustler
```

Headless sanity check:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/andrelopes/hex-hustler --quit-after 2
```

## Main Menu Flow

- `Start 5-Table Contract`: compact route. This is the main smoke test.
- `Full Route`: 12-room clear with the boss route intact.
- `House Rules`: readable reference for scoring tags, special balls, rewards, and unlocks.

Use `Esc` during play for controls, current build, audio/juice settings, reset, and debug export.

## Controls

- Left mouse: hold to charge, release to shoot.
- Mouse movement: aim from cue ball.
- Right mouse on a pocket: call that pocket.
- `Q` / `E`: side English.
- `W` / `S`: follow / draw.
- `X`: reset spin.
- `D`: print a compact debug report to the Godot output.
- `Esc`: pause/options.

## Competitive Pitfall Guardrails

These are review-informed checks from nearby roguelike billiards games. Do not ship a build that violates them.

- North star: pool shots should feel honest, relics should make you rethink the table, and the casino theme should make scoring feel like a house payout rather than a spreadsheet.
- Aim guide honesty: the visual guide must never imply a shot outcome it cannot reasonably predict. The guide should show first contact and target direction, not a fake full simulation.
- Pool feel first: ball motion, pocket mouths, rail bounce, and low-power control must feel intentional before scoring modifiers get louder.
- No max-power autopilot: full-power shots should be risky and occasionally useful, not a dominant solve-by-chaos strategy.
- Readable upgrades: relics, chalk, cues, and boards need one-sentence effects, hover detail, and visible impact during play.
- Rival pressure: AI rivals should telegraph what they want before the shot, reward answering the tell, and only punish repeated whiffs or scratches.
- Minimal punishment traps: negative effects should create decisions, not silently ruin a run or make a correct shot feel bad.
- Visual restraint by default: the default juice setting should be readable and avoid frequent flashing; high-juice effects stay opt-in.
- Variety pressure: a 5-table run should expose different table goals, ball types, and reward choices without repeating the same build rhythm.
- Stability and scaling: no crashes, no fixed-resolution assumptions, no clipped text, and no UI panel should hide the aim-critical table area.

## Recommended Beta Pass

1. Start a 5-table contract with the default case.
2. Hover balls, active relics, chalk rows, reward offers, cue cards, and board cards.
3. Verify low-power shots are controllable and max-power shots do not solve tables by endless bouncing.
4. Try called pockets, bank/kick shots, caroms, multi-pots, a scratch, and at least one chalk.
5. Check each rival tell: satisfy one tell, ignore one tell with a clean pot, and miss or scratch twice to verify heat pressure.
6. Finish or fail the contract, then confirm the route ledger, unlock messages, and run-end summary.
7. Press `D` during play or use `Esc` -> `Copy Debug` to capture reproduction data for any odd result.
8. Confirm the first-contact aim preview matches actual cue-ball contact on straight shots, cut shots, and near misses.

## What To Report

Copy the `Report:` line from the House Ledger whenever possible. Include:

- Seed and table.
- Last shot grade and tags.
- What cue, board, relics, and chalk were active.
- Whether the issue happened during aiming, shot motion, reward draft, menu, or run transition.
- Expected result versus actual result.

High-priority issues:

- Balls leaving the board or tunneling through rails.
- Pocket captures that feel unfair, too lax, or too strict.
- Shots resolving while balls are visibly still moving.
- Score tags or breakdowns that disagree with what happened.
- Reward choices applying twice or not applying.
- Unlocks, selected cue/board, seed replay, or practice markers not persisting.
- UI text too small, clipped, overlapping, or hiding aim-critical geometry.

## Resetting

Open `Esc` -> `Reset Unlock Progress` to return to a fresh starter case. This clears unlocked cues, boards, relics, chalk, best runs, and practice progress.
