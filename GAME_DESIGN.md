# ERRANDS — Game Design Document

## Concept

A browser-based isometric pixel art game born from the frustration of city living. Go on everyday errands, witness urban awfulness, do good deeds to earn Karma Points, then unleash Looney Tunes-style revenge on the bad actors.

You are always the Righteous Avenger. Pure catharsis, no guilt.

## V1 Scope

One playable errand as a proof of concept: **"Go to the grocery store to get toilet paper."**

## Core Loop

1. **Pick an errand** from a list
2. **Travel** along a scrolling street toward your destination
3. **Encounter random events** — bad behaviors and good deed opportunities
4. **Do good deeds** via button prompts → earn Karma Points
5. **Spend Karma Points** to unlock revenge weapons
6. **Use weapons** on bad actors (permanent unlock + cooldown, not ammo)
7. **Arrive** at destination → errand complete

## Key Design Decisions

| Decision | Choice |
|---|---|
| **View** | Isometric pixel art (detailed urban, street-level) |
| **Engine** | Godot 4 (GDScript) → HTML5 export |
| **Errand structure** | Errands are levels, selected from a list |
| **Movement** | Scrolling street from origin to destination |
| **Player mode** | Depends on errand (pedestrian, bike, or car) |
| **Controls** | Keyboard (WASD/arrows) + mouse click-to-move |
| **Good deeds** | Simple button prompts (e.g., "Press E to pick up dog poop") |
| **Bad events** | Randomized from a pool per errand |
| **Karma system** | Earn points from good deeds, spend to unlock weapons |
| **Weapons** | Permanent unlock + cooldown. Escalating power over time |
| **Errand completion** | Arrive at destination, level ends (designed to be extendable) |
| **Tone** | One-directional righteousness, pure catharsis, Looney Tunes-style |
| **Player morality** | Cannot be a jerk — always the avenger |
| **Sound** | Deferred for V1 |
| **Platform** | Browser (HTML5) |

## Karma & Weapons Progression

Weapons are permanently unlocked at karma thresholds. Each weapon has a cooldown (no ammo management — catharsis over resource anxiety). Escalation over time:

- **Early game:** Milkshake throw, stern finger-wag, public shaming sign
- **Mid game:** Banana peel, water balloon barrage, tow truck summon
- **Late game:** Anvil drop, piano drop, comically large magnet

*(Specific weapons and thresholds TBD)*

## V1 Event Pool

### Punishable Offenses (Bad Actors)

| Offense | Description |
|---|---|
| Honking at vulnerable pedestrians | Car lays on the horn at elderly/disabled people crossing legally |
| Right turn from the left lane | Car cuts across lanes to turn, nearly clipping everyone |
| Revving engine | Driver revs obnoxiously at a red light or in a residential area |
| Spitting on the street | Pedestrian hocks a loogie on the sidewalk |
| Yanking their dog | Owner aggressively jerks leash on a small dog |
| Peeing in public | Guy peeing against a building in broad daylight |
| Littering | Person tosses trash on the ground, ignoring a nearby bin |
| Car bullying pedestrians | Driver inches forward aggressively to intimidate people crossing |
| Car blocking crosswalk | Car stops right on top of the pedestrian crossing |
| Double-parking in the bike lane | Car parked in the bike lane, forcing cyclists into traffic |
| Sidewalk wall formation | Group walking shoulder-to-shoulder blocking the entire sidewalk |

### Good Deeds (Karma Opportunities)

| Good Deed | Karma Value |
|---|---|
| Pick up litter | Low |
| Pick up dog poop | **High** |
| Help vulnerable person cross the street | Medium |
| Help a tourist with directions | Low |
| Help a fallen elderly person | Medium |
| Call wildlife services | Medium |
| Help an injured animal | Medium |
| Catch a runaway puppy | High |
| Save a kid riding too fast toward an intersection | **High** |

*(Exact karma point values TBD during balancing)*

## Extendability Notes

- Errand completion is a clean boundary — future versions can add return trips, in-store phases, or bonus objectives
- Event pool system supports adding new bad behaviors and good deeds without restructuring
- Weapon system supports new tiers and categories
- Player mode (foot/bike/car) is per-errand, so new errands can introduce new movement types

## Open Questions

- Exact karma thresholds for weapon unlocks
- Session length tuning
- Between-errand experience (home base screen vs. simple menu)
- Sound and music direction (deferred)
