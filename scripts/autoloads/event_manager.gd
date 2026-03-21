extends Node

## Manages event pools, rolls random events, and spawns NPCs/prompts.
## Stub for Phase 1 — fleshed out in Phase 3.

signal event_spawned(event_data: Resource, event_node: Node)
signal event_resolved(event_data: Resource, was_acted_on: bool)
signal good_deed_prompt_shown(event_data: Resource)
signal good_deed_completed(event_data: Resource)
signal good_deed_expired(event_data: Resource)
