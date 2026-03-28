# Errands — Work Log

## Phase 2: Game State and HUD (2026-03-28)

**Goal:** Karma counter on screen, manually awardable via debug key.

### Completed

- `scripts/data/weapon_data.gd` — WeaponData resource class (id, display_name, karma_cost, cooldown_seconds, effect_scene_path, tier)
- `scenes/ui/hud.tscn` / `hud.gd` — CanvasLayer with top bar (KarmaLabel, ProgressLabel) and bottom WeaponBar placeholder
- Wired HUD to `GameManager.karma_changed` signal
- Debug K key (+10 karma) in `errand_level.gd`

---

## Phase 1: Player Movement on Isometric Street (2026-03-21)

**Goal:** Character moves on an isometric tile grid, camera follows.

### Completed

**Project setup**
- Reconfigured `project.godot`: GL Compatibility renderer, 960x540 viewport, nearest-neighbor filtering for pixel art, removed 3D physics
- Created full directory structure (scenes, scripts, data, assets)
- Registered three autoloads: SceneManager, GameManager, EventManager

**Core scenes**
- `scenes/main/main.tscn` — Root scene with CurrentScene container, loads errand level on startup
- `scenes/player/player.tscn` — Blue placeholder character (Polygon2D) with collision and interaction area
- `scenes/player/player.gd` — Isometric WASD movement + click-to-move, using `CharacterBody2D.move_and_slide()`
- `scenes/errand/errand_level.tscn` — Level scene with ground, Y-sorted entities, and camera
- `scenes/errand/errand_level.gd` — Delta-scaled smooth camera follow
- `scenes/errand/ground.gd` — Procedural isometric street renderer (sidewalks, road, dashed yellow center line, zebra crosswalks)

**Autoloads**
- `scripts/autoloads/scene_manager.gd` — Scene transitions with optional data passing
- `scripts/autoloads/game_manager.gd` — Karma tracking, weapon unlock state, errand lifecycle signals
- `scripts/autoloads/event_manager.gd` — Stub with signal declarations for Phase 3

### Code review fixes
- Fixed frame-rate-dependent camera lerp (was using fixed 0.1 factor, now uses `1.0 - exp(-10.0 * delta)`)
- Fixed unclosed polyline in tile outline rendering
- Consolidated duplicate `_grid_to_screen` / `_fractional_grid_to_screen` into single function
- Fixed state inconsistency in `GameManager.complete_errand()` (progress now set before clearing ID)
- Simplified SceneManager to single `change_scene()` method with default param
- Removed unused `COLOR_GRASS` constant

### Visual iterations
- Adjusted yellow center line to follow isometric road direction and increased thickness
- Converted crosswalk from solid white tiles to zebra stripes parallel to road
- Adjusted crosswalk stripe positioning
