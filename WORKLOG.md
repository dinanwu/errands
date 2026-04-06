# Errands — Work Log

## Phase 4: Bad Actors and Weapons (2026-04-05)

**Goal:** Bad NPCs appear, unlock milkshake with karma, throw it at them.

### Completed

**Bad Actor NPC**
- `scenes/npcs/bad_actor.gd` — CharacterBody2D with PunishableArea (Area2D) for click targeting. Spawns at event trigger location, shows behavior label. Lingers 15s then wanders off if not punished. Mouse hover highlights when weapon selected.
- `scenes/npcs/bad_actor.tscn` — Red placeholder character (same isometric shape as player), collision disabled (layer 0) so player walks through, PunishableArea with 35px click radius, floating BehaviorLabel

**Bad Event Data**
- `data/events/bad/` — 5 bad actor events: honking (1.0), littering (1.0), double_parking (0.8), sidewalk_wall (0.9), spitting (0.7). All reference `bad_actor.tscn` via `npc_scene_path`
- `data/errands/grocery_store.tres` — Updated with all 5 bad_event_ids

**Milkshake Weapon**
- `data/weapons/milkshake.tres` — Tier 1, karma_cost 30 (unlocks after ~3 good deeds), 5s cooldown
- `scenes/weapons/milkshake.gd` — Projectile that tweens from player to target over 0.35s, emits `hit` signal on arrival, splash expand+fade effect
- `scenes/weapons/milkshake.tscn` — Pink cup-shaped Polygon2D

**GameManager Updates**
- Weapon registry: loads all `.tres` from `res://data/weapons/` on startup
- Auto-unlock: `_check_weapon_unlocks()` runs after every `add_karma()`, unlocks weapons when karma >= cost
- Auto-select: first weapon unlocked is auto-selected
- Weapon selection: `select_weapon()` toggles on/off, emits `weapon_selected` signal
- Cooldown system: `use_weapon()` starts cooldown, `_tick_cooldowns()` in `_process()` counts down and emits `weapon_cooldown_finished`
- `can_use_weapon()` checks both unlocked and not on cooldown

**EventManager Updates**
- Loads both good and bad event pools from disk (`_load_events_from_dir()` helper)
- `load_for_errand()` filters both pools by errand's event IDs
- `_roll_event()` combines both pools for weighted random selection
- `try_spawn_event(trigger_position)` now accepts spawn position; routes to `_spawn_prompt()` for good deeds or `_spawn_bad_actor()` for bad actors
- Bad actor spawning: instantiates NPC from `event.npc_scene_path`, adds to `spawn_parent` (Y-sorted Entities node), connects `resolved` signal for cleanup
- One event active at a time (good deed OR bad actor), slot frees when resolved

**HUD Weapon Bar**
- Dynamically adds buttons to WeaponBar on `weapon_unlocked` signal
- Number keys (1-9) select weapons
- Button click also selects
- Selected weapon highlighted with yellow tint
- Cooldown display: shows remaining seconds on button text, disables button during cooldown

**Wiring**
- `errand_level.gd` sets `EventManager.spawn_parent = $Entities` and passes `trigger.global_position` to `try_spawn_event()`
- `player.gd` adds self to "player" group (used by bad_actor to find projectile origin)
- Bad actor click flow: PunishableArea.input_event → check weapon → GameManager.use_weapon() → spawn milkshake projectile → hit reaction → queue_free

---

## Phase 3: Event Triggers and Good Deeds (2026-03-28)

**Goal:** Walk into zones, see prompts, press E, earn karma.

### Completed

- `scripts/data/event_data.gd` — EventData resource class
- `scripts/data/errand_data.gd` — ErrandData resource class
- `data/events/good/` — 4 good deed .tres files (pick_up_litter 5k, help_tourist 10k, help_elderly_cross 15k, catch_puppy 20k)
- `data/errands/grocery_store.tres` — V1 errand definition
- `scripts/autoloads/event_manager.gd` — Full implementation: loads events from disk, rolls random events (no recent repeats), spawns/dismisses prompt, wires to GameManager.add_karma()
- `scenes/events/good_deed_prompt.tscn` / `.gd` — CanvasLayer prompt with event name + [E] text, auto-expires after 8s
- `errand_level.tscn` — 4 EventTrigger (Area2D) zones placed along the street at grid intervals
- `errand_level.gd` — Connects trigger body_entered signals; disables trigger after first entry
- `player.gd` — E key calls EventManager.handle_interact()

---

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
