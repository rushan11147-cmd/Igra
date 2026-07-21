extends Node
## Manages shift tasks, production quota, and area unlocking.

const TASK_POOL: Array[Dictionary] = [
	{
		"id": &"start_line_3",
		"title": "Запустить линию №3",
		"description": "Активируйте конвейеры в цехе A.",
		"priority": 1,
		"min_night": 1,
	},
	{
		"id": &"check_pressure",
		"title": "Проверить давление",
		"description": "Убедитесь, что давление в реакторе в норме.",
		"priority": 2,
		"min_night": 1,
	},
	{
		"id": &"replace_filter",
		"title": "Заменить фильтр",
		"description": "Замените засорённый фильтр в вентиляции.",
		"priority": 2,
		"min_night": 3,
	},
	{
		"id": &"repair_pump",
		"title": "Отремонтировать насос",
		"description": "Насос в подвале неисправен — найдите и почините.",
		"priority": 3,
		"min_night": 5,
	},
	{
		"id": &"clean_reactor",
		"title": "Очистить реактор",
		"description": "Удалите отложения из главного реактора.",
		"priority": 2,
		"min_night": 4,
	},
	{
		"id": &"check_warehouse",
		"title": "Проверить склад",
		"description": "Проведите инвентаризацию склада.",
		"priority": 2,
		"min_night": 2,
	},
	{
		"id": &"mix_batch",
		"title": "Смешать партию",
		"description": "Поддерживайте пропорции компонентов A:B = 60:40.",
		"priority": 2,
		"min_night": 1,
	},
	{
		"id": &"fix_equipment",
		"title": "Устранить поломку",
		"description": "Найдите и почините неисправное оборудование.",
		"priority": 3,
		"min_night": 1,
	},
	{
		"id": &"meet_quota",
		"title": "Выполнить план производства",
		"description": "Произведите необходимое количество единиц.",
		"priority": 1,
		"min_night": 1,
	},
]

const TASKS_PER_SHIFT := 5

var active_tasks: Array[Dictionary] = []
var completed_tasks: Array[StringName] = []
var production_current: int = 0
var production_target: int = 10
var _night: int = 1


func _ready() -> void:
	EventBus.equipment_broken.connect(_on_equipment_broken)
	EventBus.task_completed.connect(_on_task_completed_internal)


func setup_shift(night: int) -> void:
	_night = night
	active_tasks.clear()
	completed_tasks.clear()
	production_current = 0
	production_target = 6 + night

	var available: Array[Dictionary] = []
	for template in TASK_POOL:
		if template.get("min_night", 1) <= night:
			available.append(template)

	available.shuffle()
	var count := mini(TASKS_PER_SHIFT, available.size())
	for i in count:
		var task := available[i].duplicate(true)
		task["completed"] = false
		task["original_title"] = task.get("title", "")
		if SanitySystem.active_effects.has(&"corrupted_tasks"):
			task["title"] = SanitySystem.corrupt_text(task["original_title"])
			EventBus.task_display_corrupted.emit(task["id"], task["title"])
		active_tasks.append(task)
		EventBus.task_added.emit(task)

	EventBus.production_quota_changed.emit(production_current, production_target)


func complete_task(task_id: StringName) -> void:
	if task_id in completed_tasks:
		return
	completed_tasks.append(task_id)
	for task in active_tasks:
		if task.get("id") == task_id:
			task["completed"] = true
			break
	EventBus.task_completed.emit(task_id)
	AreaManager.on_task_completed(task_id)


func add_production(amount: int, is_defect: bool = false) -> void:
	if is_defect:
		return
	production_current += amount
	EventBus.production_quota_changed.emit(production_current, production_target)
	if production_current >= production_target:
		complete_task(&"meet_quota")
		if StoryManager.current_goal == StoryManager.PlayerGoal.EARN_MONEY and _night >= 25:
			StoryManager.mark_production_complete()


func build_shift_report(success: bool) -> Dictionary:
	var quota_met := production_current >= production_target
	var tasks_done := completed_tasks.size()
	return {
		"success": success,
		"quota_met": quota_met,
		"production": production_current,
		"production_target": production_target,
		"tasks_completed": tasks_done,
		"tasks_total": active_tasks.size(),
		"score": _calculate_score(success, quota_met, tasks_done),
	}


func get_active_tasks() -> Array[Dictionary]:
	return active_tasks


func _calculate_score(success: bool, quota_met: bool, tasks_done: int) -> int:
	var score := tasks_done * 100
	if quota_met:
		score += 500
	if success:
		score += 300
	return score


func _on_equipment_broken(_machine_id: StringName) -> void:
	pass


func _on_task_completed_internal(task_id: StringName) -> void:
	pass
