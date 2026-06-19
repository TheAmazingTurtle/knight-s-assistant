# Knight's Assistant

A cozy pixel RPG MVP built in Godot 4.7 for a portrait phone viewport.

Play it here: https://theamazingturtle.github.io/knight-s-assistant/

## About

Knight's Assistant is an idle-ish stage battler where the knight fights enemies while the porter follows behind collecting dropped loot. The player sells materials, upgrades the party, and pushes through boss checkpoints toward stage 100.

Core MVP features:

- Stage-based combat with boss stages every 10 levels
- Stage clears animate the party traveling forward with parallax before the next fight starts
- Knight health carries forward when advancing into the next stage
- The knight fights in melee range and visibly swings on each attack
- Combat HUD shows health bars, bag space, gold, and attack damage numbers
- Knight damage, health, attack speed, regen, and multiplier upgrades
- Porter heal and power-up abilities with cooldown upgrades
- Special upgrades use one-material costs that rotate toward higher-value loot by level
- Single-item loot drops, porter collection, tap/swipe speed-up interaction, inventory limits, locks, and selling
- Overflow loot is discarded on pickup when the bag is full, so progression is not blocked
- Autosave for stage progress, gold, inventory, locked loot, and upgrades
- Web export hosted through GitHub Pages

## Credits

Game concept and direction by Kent.

MVP implementation, project wiring, and README by Codex.

## Development

This project uses Godot `4.7`.

Main scene:

```text
core/main.tscn
```

Important folders:

```text
autoloads/   Global managers and game state
core/        Main scene container
data/        Combat, loot, stage scaling, and upgrade JSON
entities/    Knight, porter, enemy, and loot scripts
screens/     Start and game screens
docs/        GitHub Pages web export
```

Run locally by opening the project in Godot and pressing Play.

## Web Export

The hosted build lives in `docs/` and GitHub Pages is configured to serve `master` from `/docs`.

When exporting for GitHub Pages, use a Web export with thread support disabled so the game does not require cross-origin isolation headers.
