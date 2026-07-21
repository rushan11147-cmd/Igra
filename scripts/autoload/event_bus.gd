extends Node
## Global signal bus for decoupled game systems.

# Shift lifecycle
signal shift_started(night: int)
signal shift_ended(success: bool, report: Dictionary)
signal shift_choice_required(report: Dictionary)
signal shift_choice_made(choice: StringName)
signal time_updated(minutes_left: float, progress: float)
signal factory_time_updated(hour: int, minute: int, progress: float)

# Story
signal goal_changed(goal: int, description: String)
signal document_found(doc_id: StringName, title: String)
signal ending_triggered(ending_id: StringName)
signal money_earned(amount: int, total: int)

# Factory rules (viral hook)
signal rule_announced(rule: Dictionary)
signal rule_violated(rule_id: StringName)
signal hall8_event_started()
signal hall8_choice_made(choice: StringName, consequence: String)

# Sanity
signal sanity_changed(value: float, effects: Array)
signal sanity_effect(effect_id: StringName)

# Living factory
signal factory_mutated(mutations: Array)

# Night events
signal night_event_started(event_id: StringName, description: String)
signal night_event_resolved(event_id: StringName)

# Production
signal production_quota_changed(current: int, target: int)
signal reactor_state_changed(state: Dictionary)
signal mixer_ratio_changed(ratio_a: float, ratio_b: float)
signal defect_produced(amount: int)
signal equipment_broken(machine_id: StringName)
signal equipment_repaired(machine_id: StringName)
signal emergency_triggered(type: StringName)
signal minigame_started(game_id: StringName)
signal minigame_completed(game_id: StringName, success: bool)

# Horror & creatures
signal threat_level_changed(level: float, phase: int)
signal paranormal_event(event_id: StringName, data: Dictionary)
signal entity_spawned(is_hallucination: bool, creature_type: StringName)
signal entity_despawned()
signal entity_sabotage(type: StringName, target: Node)
signal black_mass_growth(amount: float, total: float)
signal creature_type_changed(creature_type: StringName)
signal monster_memory_updated(data: Dictionary)

# Radio partner
signal radio_message(speaker: String, text: String, is_fake: bool)
signal radio_silence()

# Player
signal player_interacted(target: Node)
signal player_damaged(amount: float)
signal player_died()
signal player_noise_changed(level: float)
signal player_hiding_changed(is_hiding: bool)
signal player_peek_changed(offset: float)
signal flashlight_toggled(is_on: bool)

# World
signal area_unlocked(area_id: StringName)
signal door_state_changed(door_id: StringName, is_open: bool)
signal key_acquired(key_id: StringName)

# Tasks & tools
signal task_added(task: Dictionary)
signal task_completed(task_id: StringName)
signal task_failed(task_id: StringName)
signal task_display_corrupted(task_id: StringName, fake_text: String)
signal tablet_toggle_requested()
