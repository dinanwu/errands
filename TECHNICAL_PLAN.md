# Errands — Technical Implementation Plan

## 0. Project Configuration (Pre-Development)

Before any development, reconfigure `project.godot`:

- Change renderer from `Forward Plus` to `GL Compatibility` (required for reliable HTML5 export)
- Remove the `[physics]` section with Jolt 3D physics (not needed for 2D)
- Set viewport: 960x540 (16:9, scales cleanly to 1080p)
- Set `display/window/stretch/mode` to `viewport` (pixel-perfect scaling)
- Set `display/window/stretch/aspect` to `keep` (preserve aspect ratio)
- Set `rendering/textures/canvas_textures/default_texture_filter` to `0` (nearest neighbor — critical for crisp pixel art)
- Register autoloads (GameManager, EventManager, SceneManager)
- Set main scene to `res://scenes/main/main.tscn`

---

## 1. Directory Structure

```
res://
├── project.godot
├── GAME_DESIGN.md
├── TECHNICAL_PLAN.md
│
├── scenes/
│   ├── main/
│   │   ├── main.tscn              # Root scene: scene manager
│   │   └── main.gd
│   ├── ui/
│   │   ├── title_screen.tscn      # Title / errand selection
│   │   ├── title_screen.gd
│   │   ├── hud.tscn               # In-game HUD overlay
│   │   ├── hud.gd
│   │   ├── errand_complete.tscn   # End-of-errand summary
│   │   ├── errand_complete.gd
│   │   ├── karma_shop.tscn        # Weapon unlock screen
│   │   └── karma_shop.gd
│   ├── errand/
│   │   ├── errand_level.tscn      # Reusable errand level shell
│   │   └── errand_level.gd
│   ├── player/
│   │   ├── player.tscn            # Player character
│   │   └── player.gd
│   ├── npcs/
│   │   ├── npc_base.tscn          # Base NPC
│   │   ├── npc_base.gd
│   │   ├── bad_actor.tscn         # Punishable NPC (inherits npc_base)
│   │   └── bad_actor.gd
│   ├── events/
│   │   ├── good_deed_prompt.tscn  # Button prompt UI
│   │   └── good_deed_prompt.gd
│   └── weapons/
│       ├── weapon_base.tscn       # Weapon visual effect base
│       ├── weapon_base.gd
│       ├── milkshake.tscn         # V1 starter weapon
│       └── milkshake.gd
│
├── scripts/
│   ├── autoloads/
│   │   ├── game_manager.gd        # Karma, unlocks, errand state
│   │   ├── event_manager.gd       # Event pool, spawning, scheduling
│   │   └── scene_manager.gd       # Scene transitions
│   └── data/
│       ├── errand_data.gd         # Errand resource schema
│       ├── event_data.gd          # Event resource schema
│       └── weapon_data.gd         # Weapon resource schema
│
├── data/
│   ├── errands/
│   │   └── grocery_store.tres     # V1 errand definition
│   ├── events/
│   │   ├── bad/
│   │   │   ├── honking.tres
│   │   │   ├── littering.tres
│   │   │   ├── double_parking.tres
│   │   │   ├── sidewalk_wall.tres
│   │   │   └── spitting.tres
│   │   └── good/
│   │       ├── pick_up_litter.tres
│   │       ├── help_elderly_cross.tres
│   │       ├── help_tourist.tres
│   │       └── catch_puppy.tres
│   └── weapons/
│       ├── milkshake.tres
│       ├── finger_wag.tres
│       └── public_shame_sign.tres
│
└── assets/
    ├── sprites/
    │   ├── player/                # Player sprite sheets
    │   ├── npcs/                  # NPC sprites
    │   ├── weapons/               # Weapon effect sprites
    │   └── environment/           # Street tiles, buildings, props
    ├── ui/                        # UI icons, button graphics
    └── tilemaps/                  # TileSet resources
```

**Why this structure:**
- `scenes/` co-locates `.tscn` + `.gd` files (Godot convention)
- `scripts/autoloads/` separates global singletons for clarity
- `scripts/data/` holds Resource class definitions (schemas); `data/` holds `.tres` instances (content). Adding a new errand or event = creating a new `.tres` file, no code changes.
- `assets/` is the raw art bucket

---

## 2. Scene Tree Architecture

### 2.1 Main Scene (`main.tscn`)

```
Main (Node)
└── CurrentScene (Node)     # Child scenes swapped by SceneManager
```

### 2.2 Title Screen (`title_screen.tscn`)

```
TitleScreen (Control)
├── VBoxContainer
│   ├── TitleLabel              # "ERRANDS"
│   ├── ErrandList              # Buttons for each errand
│   └── StartButton             # Greyed until errand selected
├── KarmaDisplay                # Total karma across runs
└── WeaponShopButton            # Opens karma shop
```

### 2.3 Errand Level (`errand_level.tscn`) — Core Gameplay

```
ErrandLevel (Node2D)
├── Street (Node2D)
│   ├── TileMapLayer            # Isometric ground (road, sidewalk, crosswalk)
│   ├── Buildings (Node2D)      # Static building sprites
│   └── Props (Node2D)          # Street furniture
├── Entities (Node2D)           # Y-sorted for depth ordering
│   ├── Player                  # Instantiated from player.tscn
│   └── NPCSpawnZone (Node2D)   # NPCs spawned here by EventManager
├── Camera2D                    # Follows player, clamped to level bounds
├── EventZones (Node2D)         # Area2D triggers along the street
│   ├── EventTrigger1 (Area2D)
│   ├── EventTrigger2 (Area2D)
│   └── ...
├── DestinationZone (Area2D)    # End-of-level trigger (grocery store)
└── HUD (CanvasLayer)           # Instantiated from hud.tscn
```

Key details:
- `Entities` has `y_sort_enabled = true` for correct isometric depth ordering
- `EventZones` are placed at intervals — player overlap triggers EventManager to roll a random event
- Camera follows player with smoothing, clamped to level bounds

### 2.4 Player (`player.tscn`)

```
Player (CharacterBody2D)
├── Sprite2D                    # Placeholder: colored rectangle
├── CollisionShape2D            # Physics hitbox
├── InteractionArea (Area2D)    # Larger radius for event/NPC detection
│   └── CollisionShape2D
└── AnimationPlayer             # Walk animations
```

### 2.5 Bad Actor (`bad_actor.tscn`, inherits npc_base)

```
BadActor (CharacterBody2D)
├── Sprite2D
├── CollisionShape2D
├── AnimationPlayer
├── PunishableArea (Area2D)     # Weapon targeting area
│   └── CollisionShape2D
└── BehaviorLabel (Label)       # "HONKING AT ELDERLY"
```

### 2.6 HUD (`hud.tscn`)

```
HUD (CanvasLayer)
├── TopBar (HBoxContainer)
│   ├── KarmaLabel              # "Karma: 150"
│   └── ErrandProgress          # "3 blocks to go"
├── WeaponBar (HBoxContainer)   # Bottom — unlocked weapon icons
├── PromptContainer             # Good deed prompts appear here
└── WeaponCooldownOverlay       # Grey overlay during cooldown
```

---

## 3. Autoloads (Singletons)

### 3.1 GameManager (`scripts/autoloads/game_manager.gd`)

Tracks karma, weapon unlocks, errand state. The signal hub.

**State:**
- `karma_points: int`
- `unlocked_weapons: Array[StringName]`
- `current_errand_id: StringName`
- `errand_progress: float` (0.0 to 1.0)
- `weapon_cooldowns: Dictionary` (weapon_id → remaining seconds)

**Signals:**
- `karma_changed(new_total, delta)`
- `weapon_unlocked(weapon_id)`
- `weapon_used(weapon_id)`
- `weapon_cooldown_finished(weapon_id)`
- `errand_started(errand_id)`
- `errand_completed(errand_id)`

### 3.2 EventManager (`scripts/autoloads/event_manager.gd`)

Holds event pools, rolls random events, spawns NPCs/prompts.

**State:**
- `bad_event_pool: Array[Resource]`
- `good_event_pool: Array[Resource]`
- `recent_events: Array[StringName]` (prevents immediate repeats)
- `active_events: Array[Node]`

**Signals:**
- `event_spawned(event_data, event_node)`
- `event_resolved(event_data, was_acted_on)`
- `good_deed_prompt_shown(event_data)`
- `good_deed_completed(event_data)`
- `good_deed_expired(event_data)`

### 3.3 SceneManager (`scripts/autoloads/scene_manager.gd`)

Manages transitions between major scenes (title, level, complete, shop). Swaps child nodes under `Main/CurrentScene`.

---

## 4. Data-Driven Resources

### ErrandData (`scripts/data/errand_data.gd`)
- `id`, `display_name`, `description`
- `player_mode` ("pedestrian", "bike", "car")
- `street_length` (number of trigger zones)
- `destination_name`
- `bad_event_ids`, `good_event_ids`

### EventData (`scripts/data/event_data.gd`)
- `id`, `event_type` ("bad_actor" or "good_deed")
- `display_name`, `description`, `prompt_text`
- `karma_reward`
- `weight` (spawn probability)
- `npc_scene_path` (for bad actors)

### WeaponData (`scripts/data/weapon_data.gd`)
- `id`, `display_name`, `description`
- `karma_cost` (to unlock)
- `cooldown_seconds`
- `effect_scene_path`
- `tier` (1=early, 2=mid, 3=late)

**Adding content = creating a `.tres` file and filling in fields. No code changes.**

---

## 5. Signal Wiring (Key Connections)

| Signal | Listener | Effect |
|---|---|---|
| `player_entered_event_zone` | EventManager | Rolls and spawns random event |
| `good_deed_completed` | GameManager | Adds karma |
| `karma_changed` | HUD | Updates karma display |
| `karma_changed` | GameManager (self) | Checks weapon unlock thresholds |
| `weapon_unlocked` | HUD | Shows notification, updates weapon bar |
| `weapon_used` | ErrandLevel | Spawns weapon effect at target |
| `player_reached_destination` | ErrandLevel | Triggers errand completion |
| `errand_completed` | SceneManager | Transitions to summary screen |

Everything communicates through signals on autoloads. Player never references HUD. HUD never references EventManager. Fully decoupled.

---

## 6. Isometric Implementation

- **Tile shape:** Isometric, 64x32 pixels (2:1 ratio)
- **Street layout:** Runs diagonally (isometric east), sidewalks on both sides, road in middle
- **Buildings:** Sprites placed above tilemap (not tiles) for varied heights

**Isometric movement mapping:**
- WASD input is screen-space, converted to iso world-space
- Transform: `iso_velocity = Vector2(input.x - input.y, (input.x + input.y) / 2.0).normalized() * speed`

**Click-to-move:**
- Mouse click → `get_global_mouse_position()` → set `target_position`
- Move toward target each frame until within threshold
- Any WASD input cancels click target

**Depth sorting:**
- `Entities` node has `y_sort_enabled = true`
- Higher Y = drawn on top = correct isometric "closer to camera"

---

## 7. Build Phases

### Phase 1: Player Movement on Isometric Street
> **Testable result:** Character moves on an isometric tile grid, camera follows, renders in browser.

- Reconfigure `project.godot` (renderer, viewport, pixel art filter)
- Create directory structure
- Create SceneManager autoload (minimal)
- Create main scene
- Create TileSet (64x32, colored shapes: road, sidewalk, crosswalk)
- Create errand level with TileMapLayer, paint a small street
- Create player scene (colored rectangle, CharacterBody2D)
- Implement WASD isometric movement + click-to-move
- Add Camera2D following player
- Configure HTML5 export, test in browser

### Phase 2: Game State and HUD
> **Testable result:** Karma counter on screen, manually awardable via debug key.

- Create GameManager autoload with karma state and signals
- Create WeaponData resource class
- Create HUD scene (karma label, errand progress, weapon bar placeholder)
- Wire HUD to `GameManager.karma_changed`
- Temporary debug key (K) to add karma for testing

### Phase 3: Event Triggers and Good Deeds
> **Testable result:** Walk into zones, see prompts, press E, earn karma.

- Create EventData and ErrandData resource classes
- Create good deed `.tres` files (4-5 events)
- Create grocery store errand `.tres`
- Create EventManager autoload
- Place Area2D trigger zones along the street
- Add InteractionArea to player
- Create good deed prompt scene
- Wire: trigger → EventManager → prompt → E key → GameManager.add_karma()

### Phase 4: Bad Actors and Weapons
> **Testable result:** Bad NPCs appear, unlock milkshake with karma, throw it at them.

- Create NPC base and bad actor scenes
- Create bad event `.tres` files (4-5 events)
- Update EventManager for bad actor spawning
- Create milkshake weapon `.tres` and weapon effect scene
- Add weapon unlock logic to GameManager
- Update HUD with weapon bar, cooldown display
- Wire weapon targeting: click bad actor → fire weapon → NPC reacts

### Phase 5: Errand Flow (Full Loop)
> **Testable result:** Title screen → pick errand → play → arrive at store → summary → menu.

- Create title screen (errand list, start button)
- Create errand complete screen (karma earned, deeds done, bad actors punished)
- Create karma shop screen (view/unlock weapons)
- Add destination zone to level
- Wire full scene flow through SceneManager
- Add errand progress tracking to HUD

### Phase 6: Polish and Juice
> **Testable result:** Game feels complete and satisfying.

- Scene transitions (fade to black)
- Floating karma text (+10 pops up and fades)
- Weapon unlock banner notification
- Tune event frequency and karma values for 2-3 minute errand
- Add 2 more weapons (finger wag, public shame sign)
- Simple walking animation (sprite bob)
- First-play instruction overlay
- Final HTML5 browser testing

---

## 8. V1 Scope Boundaries

### Building:
- 1 errand (grocery store), pedestrian mode only
- 1 scrolling isometric street with placeholder art
- ~5 good deed events, ~5 bad actor events
- Good deed prompt system (Press E)
- Karma points (earn from good deeds)
- 3 weapons (milkshake, finger wag, public shame sign) with cooldowns
- HUD: karma, progress, weapon bar
- Title screen, errand complete screen, karma shop
- HTML5 export

### Explicitly deferred:
- Sound/music
- Real pixel art (placeholders only)
- Multiple errands
- Bike/car player modes
- Save/load persistence
- Return trips, in-store phases
- Mobile/touch input
- Particle effects, parallax
- NPC pathfinding
- Difficulty scaling
- Settings menu

---

## 9. Architecture Principles

1. **One script per scene, one responsibility per script.** Player handles movement. HUD handles display. They never import each other.
2. **Autoloads are the only globals.** Need karma? Read `GameManager.karma_points`. Need to react? Connect to `GameManager.karma_changed`.
3. **Signals over direct calls.** Player never calls `hud.update_karma()`. Signals flow through autoloads.
4. **Resources over hardcoded data.** Every errand, event, weapon is a `.tres` file. New content = new file, no code edits.
5. **Scene composition over inheritance.** The level composes player, HUD, tilemap as child scenes. Each is self-contained and testable alone.
