extends Node
## Central game state: 30 night shifts at Factory 17.

enum GameState { MENU, BRIEFING, SHIFT, PAUSED, SHIFT_END, CHOICE, GAME_OVER, ENDING }

const MAX_NIGHTS := 30
const MINUTES_PER_SHIFT := 12.0
const SHIFT_START_HOUR := 22
const SHIFT_DURATION_HOURS := 8.0
const SAVE_PATH := "user://horror_factory_save.cfg"

var current_night: int = 1
var game_state: GameState = GameState.MENU
var shift_time_elapsed: float = 0.0
var total_defects: int = 0
var total_accidents: int = 0
var shifts_survived: int = 0
var _pending_report: Dictionary = {}
## Если true — после загрузки игровой сцены сразу стартует смена.
var _pending_boot_action: StringName = &""

func _ready() -> void:
	EventBus.shift_choice_made.connect(_on_shift_choice_made)
	EventBus.player_died.connect(_on_player_died)
	EventBus.ending_triggered.connect(_on_ending_triggered)


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func clear_save() -> void:
	if has_save():
		DirAccess.remove_absolute(SAVE_PATH)


func save_progress() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "night", current_night)
	cfg.set_value("progress", "shifts_survived", shifts_survived)
	cfg.set_value("progress", "total_defects", total_defects)
	cfg.set_value("progress", "total_accidents", total_accidents)
	cfg.set_value("progress", "money", StoryManager.money_earned)
	cfg.save(SAVE_PATH)


func request_new_game() -> void:
	clear_save()
	_pending_boot_action = &"new_game"


func request_continue() -> void:
	_pending_boot_action = &"continue"


## Вызывается из игровой сцены после готовности мира.
func consume_boot_action() -> void:
	var action := _pending_boot_action
	_pending_boot_action = &""
	match action:
		&"new_game":
			start_new_game()
		&"continue":
			continue_game()
		_:
			# Прямой запуск сцены без меню — начинаем новую смену.
			if game_state == GameState.MENU:
				start_new_game()


func start_new_game() -> void:
	current_night = 1
	total_defects = 0
	total_accidents = 0
	shifts_survived = 0
	StoryManager.reset()
	AreaManager.reset()
	InventoryManager.reset()
	MonsterMemory.reset()
	SanitySystem.reset()
	LivingFactory.reset()
	_start_shift()
	save_progress()


func continue_game() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		start_new_game()
		return

	current_night = int(cfg.get_value("progress", "night", 1))
	shifts_survived = int(cfg.get_value("progress", "shifts_survived", 0))
	total_defects = int(cfg.get_value("progress", "total_defects", 0))
	total_accidents = int(cfg.get_value("progress", "total_accidents", 0))
	StoryManager.reset()
	StoryManager.money_earned = int(cfg.get_value("progress", "money", 0))
	AreaManager.reset()
	InventoryManager.reset()
	MonsterMemory.reset()
	SanitySystem.reset()
	LivingFactory.reset()
	_start_shift()


func start_shift() -> void:
	_start_shift()


func _start_shift() -> void:
	game_state = GameState.BRIEFING
	shift_time_elapsed = 0.0

	FactoryRules.reset_for_night(current_night)
	CreatureManager.setup_for_night(current_night)
	NightEvents.setup_for_night(current_night)
	RadioPartner.setup_for_night(current_night)
	LivingFactory.generate_for_night(current_night)
	HorrorSystem.reset_for_night(current_night)
	ShiftManager.setup_shift(current_night)

	var scene_root := get_tree().current_scene
	if scene_root:
		AreaManager.apply_to_scene(scene_root)
		LivingFactory.apply_to_scene(scene_root)

	game_state = GameState.SHIFT
	EventBus.shift_started.emit(current_night)


func _process(delta: float) -> void:
	if game_state != GameState.SHIFT:
		return

	shift_time_elapsed += delta
	var progress := clampf(shift_time_elapsed / (MINUTES_PER_SHIFT * 60.0), 0.0, 1.0)
	var minutes_left := maxf(0.0, MINUTES_PER_SHIFT - shift_time_elapsed / 60.0)

	var factory_hour := int(SHIFT_START_HOUR + progress * SHIFT_DURATION_HOURS) % 24
	var factory_minute := int((progress * SHIFT_DURATION_HOURS * 60.0)) % 60

	EventBus.time_updated.emit(minutes_left, progress)
	EventBus.factory_time_updated.emit(factory_hour, factory_minute, progress)
	FactoryRules.on_factory_time(progress, factory_hour, factory_minute)

	if progress >= 1.0:
		_request_shift_end(true)


func pause_shift() -> void:
	if game_state == GameState.SHIFT:
		game_state = GameState.PAUSED
		get_tree().paused = true


func resume_shift() -> void:
	if game_state == GameState.PAUSED:
		game_state = GameState.SHIFT
		get_tree().paused = false


func _request_shift_end(success: bool) -> void:
	game_state = GameState.CHOICE
	_pending_report = ShiftManager.build_shift_report(success)
	_pending_report["night"] = current_night
	_pending_report["defects"] = total_defects
	_pending_report["accidents"] = total_accidents
	_pending_report["money"] = StoryManager.money_earned
	_pending_report["goal"] = StoryManager.get_goal_description()
	_pending_report["shifts_remaining"] = StoryManager.get_shifts_remaining(current_night)
	_pending_report["sanity"] = SanitySystem.sanity
	_pending_report["rules"] = FactoryRules.get_rules_text()
	_pending_report["mutations"] = LivingFactory.get_mutation_descriptions()
	EventBus.shift_choice_required.emit(_pending_report)


func _on_shift_choice_made(_choice: StringName) -> void:
	_finalize_shift(_pending_report.get("success", true))


func _finalize_shift(success: bool) -> void:
	game_state = GameState.SHIFT_END
	EventBus.shift_ended.emit(success, _pending_report)

	if success:
		shifts_survived += 1
		StoryManager.on_shift_completed(current_night, _pending_report.get("quota_met", false))
		current_night = mini(current_night + 1, MAX_NIGHTS + 1)
		save_progress()


func _on_player_died() -> void:
	game_state = GameState.GAME_OVER
	_pending_report = ShiftManager.build_shift_report(false)
	_finalize_shift(false)


func _on_ending_triggered(_ending_id: StringName) -> void:
	game_state = GameState.ENDING


func get_horror_phase() -> int:
	if current_night <= 5:
		return 0
	if current_night <= 12:
		return 1
	if current_night <= 22:
		return 2
	return 3
