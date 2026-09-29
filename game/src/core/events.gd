extends Node
## Global event bus. Gameplay code emits, systems/UI listen. Nothing in here has logic.

# --- interaction & magic ---------------------------------------------------
signal interaction_done(id: String, kind: String)      ## a world Interactable was used
signal power_used(power: String, target_id: String)
signal zone_entered(zone_id: String)
signal custom_event(name: String)                      ## free-form level events ("bridge_grown")

# --- quests ----------------------------------------------------------------
signal quest_started(quest_id: String)
signal quest_step_started(quest_id: String, step_id: String)
signal quest_step_completed(quest_id: String, step_id: String)
signal quest_completed(quest_id: String)

# --- progression -----------------------------------------------------------
signal stars_changed(total: int, delta: int)
signal star_earned(amount: int, world_pos: Vector3, reason: String)
signal character_stage_changed(character_id: String, old_stage: int, new_stage: int)
signal castle_feature_unlocked(feature_id: String)
signal power_unlocked(power: String)
signal crown_level_changed(level: int)

# --- dialogue --------------------------------------------------------------
signal dialogue_started(sequence_id: String)
signal dialogue_line_started(line: Dictionary)
signal dialogue_line_finished(line: Dictionary)
signal dialogue_finished(sequence_id: String)
signal character_cue(character_id: String, animation: String, emotion: String)

# --- guidance --------------------------------------------------------------
signal hint_level_changed(level: int, target_id: String)

# --- presentation ----------------------------------------------------------
signal music_cue(cue: String)
signal ui_prompt(icon: String, world_pos: Vector3, visible: bool)
signal cinematic_started
signal cinematic_finished
signal scene_changed(scene_id: String)
