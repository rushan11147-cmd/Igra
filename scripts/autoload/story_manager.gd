extends Node
## Story progression: Alex, goals, documents, multiple endings.

enum PlayerGoal { EARN_MONEY, DISCOVER_TRUTH, STOP_PRODUCTION }
enum Ending { NONE, BAD, GOOD, SECRET, ESCAPE, SAVE_WORKERS, SELL_SECRETS, BECOME_SUBJECT }
enum ShiftChoice { COMPLETE_PLAN, STOP_PRODUCTION, EXPLORE }

const PROTAGONIST_NAME := "Алекс"
const FACTORY_NAME := "Factory 17"
const TOTAL_SHIFTS_GOAL := 30
const SHIFT_PAYMENT := 150
const BONUS_PAYMENT := 100
const DOCUMENTS_FOR_SECRET := 5

const GOAL_DESCRIPTIONS: Dictionary = {
	PlayerGoal.EARN_MONEY: "Продержаться %d ночных смен и заработать на новую жизнь." % TOTAL_SHIFTS_GOAL,
	PlayerGoal.DISCOVER_TRUTH: "Узнать, что скрывает завод Factory 17.",
	PlayerGoal.STOP_PRODUCTION: "Остановить эксперимент. Нельзя выпускать это наружу.",
}

const DOCUMENTS: Dictionary = {
	&"doc_shift_log": {"title": "Журнал ночных смен", "type": &"log"},
	&"doc_chemical_formula": {"title": "Формула смешивания", "type": &"report"},
	&"doc_incident_report": {"title": "Отчёт об инциденте", "type": &"report"},
	&"doc_security_footage": {"title": "Запись с камеры", "type": &"photo"},
	&"doc_director_memo": {"title": "Служебная записка директора", "type": &"report"},
	&"doc_experiment_notes": {"title": "Лабораторные записи", "type": &"report"},
	&"doc_worker_badge": {"title": "Пропуск пропавшего работника", "type": &"badge"},
	&"doc_worker_photo": {"title": "Фото смены 2019", "type": &"photo"},
	&"doc_audio_log": {"title": "Аудиозапись допроса", "type": &"audio"},
}

var current_goal: PlayerGoal = PlayerGoal.EARN_MONEY
var money_earned: int = 0
var documents_found: Array[StringName] = []
var shift_choices: Array[StringName] = []
var workers_saved: int = 0
var secrets_sold: bool = false
var reactor_destroyed: bool = false
var production_completed: bool = false
var explore_nights: int = 0
var ending: Ending = Ending.NONE


func reset() -> void:
	current_goal = PlayerGoal.EARN_MONEY
	money_earned = 0
	documents_found.clear()
	shift_choices.clear()
	workers_saved = 0
	secrets_sold = false
	reactor_destroyed = false
	production_completed = false
	explore_nights = 0
	ending = Ending.NONE
	EventBus.goal_changed.emit(current_goal, get_goal_description())


func apply_shift_choice(choice: ShiftChoice, quota_met: bool) -> void:
	shift_choices.append(get_choice_id(choice))
	EventBus.shift_choice_made.emit(get_choice_id(choice))

	match choice:
		ShiftChoice.COMPLETE_PLAN:
			if quota_met:
				money_earned += BONUS_PAYMENT
				EventBus.money_earned.emit(BONUS_PAYMENT, money_earned)
		ShiftChoice.STOP_PRODUCTION:
			HorrorSystem.add_threat(-15.0, &"production_stopped")
			money_earned = maxi(0, money_earned - 50)
		ShiftChoice.EXPLORE:
			explore_nights += 1
			if randf() < 0.3 + explore_nights * 0.05:
				_discover_random_document()


func on_shift_completed(night: int, quota_met: bool) -> void:
	if quota_met:
		money_earned += SHIFT_PAYMENT
		EventBus.money_earned.emit(SHIFT_PAYMENT, money_earned)
	_evaluate_goal_transition(night)


func find_document(doc_id: StringName) -> void:
	if doc_id in documents_found:
		return
	if not DOCUMENTS.has(doc_id):
		return

	documents_found.append(doc_id)
	var info: Dictionary = DOCUMENTS[doc_id]
	EventBus.document_found.emit(doc_id, info.get("title", str(doc_id)))

	if current_goal == PlayerGoal.EARN_MONEY and documents_found.size() >= 1:
		_set_goal(PlayerGoal.DISCOVER_TRUTH)
	if documents_found.size() >= DOCUMENTS_FOR_SECRET:
		try_secret_ending()


func mark_production_complete() -> void:
	production_completed = true
	_check_bad_ending()


func mark_reactor_destroyed() -> void:
	reactor_destroyed = true
	_trigger_ending(Ending.GOOD)


func mark_workers_saved(count: int) -> void:
	workers_saved = count
	if workers_saved >= 3:
		_trigger_ending(Ending.SAVE_WORKERS)


func mark_secrets_sold() -> void:
	secrets_sold = true
	_trigger_ending(Ending.SELL_SECRETS)


func mark_escape() -> void:
	if money_earned >= SHIFT_PAYMENT * 20:
		_trigger_ending(Ending.ESCAPE)


func mark_became_subject() -> void:
	_trigger_ending(Ending.BECOME_SUBJECT)


func try_secret_ending() -> void:
	if documents_found.size() >= DOCUMENTS_FOR_SECRET:
		_trigger_ending(Ending.SECRET)


func get_goal_description() -> String:
	return GOAL_DESCRIPTIONS.get(current_goal, "")


func get_shifts_remaining(current_night: int) -> int:
	return maxi(0, TOTAL_SHIFTS_GOAL - current_night + 1)


func get_document_title(doc_id: StringName) -> String:
	return DOCUMENTS.get(doc_id, {}).get("title", str(doc_id))


func _discover_random_document() -> void:
	var undiscovered: Array[StringName] = []
	for doc_id: StringName in DOCUMENTS:
		if doc_id not in documents_found:
			undiscovered.append(doc_id)
	if not undiscovered.is_empty():
		find_document(undiscovered[randi() % undiscovered.size()])


func _evaluate_goal_transition(night: int) -> void:
	if current_goal == PlayerGoal.EARN_MONEY and night >= 11:
		_set_goal(PlayerGoal.DISCOVER_TRUTH)
	elif current_goal == PlayerGoal.DISCOVER_TRUTH and (night >= 21 or documents_found.size() >= 3):
		_set_goal(PlayerGoal.STOP_PRODUCTION)


func _set_goal(goal: PlayerGoal) -> void:
	if goal == current_goal:
		return
	current_goal = goal
	EventBus.goal_changed.emit(current_goal, get_goal_description())


func _check_bad_ending() -> void:
	if production_completed:
		_trigger_ending(Ending.BAD)


func get_choice_id(choice: ShiftChoice) -> StringName:
	match choice:
		ShiftChoice.COMPLETE_PLAN: return &"complete_plan"
		ShiftChoice.STOP_PRODUCTION: return &"stop_production"
		ShiftChoice.EXPLORE: return &"explore"
	return &""


func _trigger_ending(ending_id: Ending) -> void:
	ending = ending_id
	var id_map: Dictionary = {
		Ending.BAD: &"bad",
		Ending.GOOD: &"good",
		Ending.SECRET: &"secret",
		Ending.ESCAPE: &"escape",
		Ending.SAVE_WORKERS: &"save_workers",
		Ending.SELL_SECRETS: &"sell_secrets",
		Ending.BECOME_SUBJECT: &"become_subject",
	}
	EventBus.ending_triggered.emit(id_map.get(ending_id, &"unknown"))
