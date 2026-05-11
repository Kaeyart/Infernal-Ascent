extends Node
class_name PatronRunManager

signal patron_added(patron_id: String)
signal patron_lock_changed(is_locked: bool, patrons: Array)
signal boon_claimed(patron_id: String, boon: Dictionary)
signal relationship_changed(patron_id: String, value: int)
signal gate_choice_committed(choice_data: Dictionary)

const MAX_RUN_PATRONS: int = 2

var selected_patrons: Array[String] = []
var patron_locked: bool = false
var pending_reward_patron_id: String = ""
var claimed_boons: Array[Dictionary] = []
var relationships: Dictionary = {}
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()

func reset_run() -> void:
	selected_patrons.clear()
	patron_locked = false
	pending_reward_patron_id = ""
	claimed_boons.clear()
	print("[PatronRun] Reset. Pool unlocked.")
	emit_signal("patron_lock_changed", patron_locked, selected_patrons.duplicate())

func get_selected_patrons() -> Array[String]:
	return selected_patrons.duplicate()

func is_locked() -> bool:
	return patron_locked

func get_pending_reward_patron() -> String:
	return pending_reward_patron_id

func choose_reward_patron_after_clear() -> String:
	# A gate can reserve the next reward patron. Once the run is locked, this
	# reservation must never introduce a third patron.
	if pending_reward_patron_id != "":
		if _is_patron_allowed_for_reward(pending_reward_patron_id):
			return pending_reward_patron_id
		print("[PatronRun] Invalid pending patron '%s' discarded." % pending_reward_patron_id)
		pending_reward_patron_id = ""

	if patron_locked:
		return _get_random_selected_patron()

	if selected_patrons.is_empty():
		return _get_random_unselected_patron("")

	# Before lock, normal clear rewards upgrade the current first patron unless a
	# physical gate has reserved a second patron.
	var index: int = rng.randi_range(0, selected_patrons.size() - 1)
	return selected_patrons[index]

func create_current_boon_offer() -> Dictionary:
	var patron_id: String = choose_reward_patron_after_clear()
	return PatronRegistry.make_boon_offer(patron_id, rng)

func claim_boon(patron_id: String, boon: Dictionary) -> void:
	var resolved_patron_id: String = _resolve_reward_patron_id(patron_id)
	if resolved_patron_id != "" and not selected_patrons.has(resolved_patron_id):
		_add_patron_to_run(resolved_patron_id)

	var stored_boon: Dictionary = boon.duplicate(true)
	stored_boon["patron_id"] = resolved_patron_id
	claimed_boons.append(stored_boon)
	pending_reward_patron_id = ""
	_increase_relationship(resolved_patron_id, 1)
	print("[PatronRun] Boon claimed from %s. %s" % [PatronRegistry.get_patron_name(resolved_patron_id), describe_run_lock()])
	emit_signal("boon_claimed", resolved_patron_id, stored_boon.duplicate(true))

func commit_gate_choice(choice_data: Dictionary) -> void:
	var committed_choice: Dictionary = choice_data.duplicate(true)
	var choice_type: String = str(committed_choice.get("type", "patron"))

	if choice_type == "patron":
		var requested_patron_id: String = str(committed_choice.get("patron_id", ""))
		var resolved_patron_id: String = _resolve_gate_patron_id(requested_patron_id)
		if resolved_patron_id == "":
			pending_reward_patron_id = ""
			committed_choice["type"] = "utility"
			committed_choice["id"] = "invalid_patron_choice"
			committed_choice["display_name"] = "No Patron"
		else:
			pending_reward_patron_id = resolved_patron_id
			committed_choice["patron_id"] = resolved_patron_id
			committed_choice["id"] = resolved_patron_id
			committed_choice["display_name"] = PatronRegistry.get_patron_name(resolved_patron_id)
			committed_choice["subtitle"] = str(PatronRegistry.get_patron(resolved_patron_id).get("subtitle", "Patron boon"))
			committed_choice["color"] = PatronRegistry.get_patron_color(resolved_patron_id)
			if not selected_patrons.has(resolved_patron_id):
				_add_patron_to_run(resolved_patron_id)
	else:
		pending_reward_patron_id = ""

	print("[PatronRun] Gate committed: %s. Pending: %s. %s" % [str(committed_choice.get("display_name", "Choice")), pending_reward_patron_id, describe_run_lock()])
	emit_signal("gate_choice_committed", committed_choice.duplicate(true))

func build_exit_choices() -> Array[Dictionary]:
	if patron_locked:
		return _build_locked_exit_choices()
	return _build_unlocked_exit_choices()

func describe_run_lock() -> String:
	if selected_patrons.is_empty():
		return "No patrons selected. First clear will call a random witness."
	if patron_locked and selected_patrons.size() >= 2:
		return "LOCKED: %s + %s." % [PatronRegistry.get_patron_name(selected_patrons[0]), PatronRegistry.get_patron_name(selected_patrons[1])]
	return "First patron: %s. Choose one more patron to lock the run." % PatronRegistry.get_patron_name(selected_patrons[0])

func _build_unlocked_exit_choices() -> Array[Dictionary]:
	var choices: Array[Dictionary] = []
	var patrons: Dictionary = PatronRegistry.get_patrons()
	var candidate_ids: Array[String] = []
	for key: Variant in patrons.keys():
		var patron_id: String = str(key)
		if not selected_patrons.has(patron_id):
			candidate_ids.append(patron_id)
	_shuffle_strings(candidate_ids)

	for patron_id: String in candidate_ids:
		if choices.size() >= 3:
			break
		choices.append(_make_patron_gate_data(patron_id, true))

	if choices.size() < 3 and not selected_patrons.is_empty():
		for patron_id: String in selected_patrons:
			if choices.size() >= 3:
				break
			choices.append(_make_patron_gate_data(patron_id, false))

	while choices.size() < 3:
		choices.append(_get_random_utility_choice())
	return choices

func _build_locked_exit_choices() -> Array[Dictionary]:
	var choices: Array[Dictionary] = []
	for patron_id: String in selected_patrons:
		choices.append(_make_patron_gate_data(patron_id, false))
	while choices.size() < 3:
		choices.append(_get_random_utility_choice())
	return choices

func _make_patron_gate_data(patron_id: String, is_new: bool) -> Dictionary:
	var patron: Dictionary = PatronRegistry.get_patron(patron_id)
	return {
		"id": patron_id,
		"type": "patron",
		"patron_id": patron_id,
		"display_name": str(patron.get("display_name", patron_id.capitalize())),
		"subtitle": str(patron.get("subtitle", "Patron boon")),
		"is_new_patron": is_new,
		"color": PatronRegistry.get_patron_color(patron_id)
	}

func _add_patron_to_run(patron_id: String) -> void:
	if patron_id == "":
		return
	if selected_patrons.has(patron_id):
		return
	if selected_patrons.size() >= MAX_RUN_PATRONS:
		return
	selected_patrons.append(patron_id)
	emit_signal("patron_added", patron_id)
	if selected_patrons.size() >= MAX_RUN_PATRONS:
		patron_locked = true
		print("[PatronRun] RUN LOCKED to: %s" % _selected_patron_names())
	else:
		print("[PatronRun] Patron added: %s" % PatronRegistry.get_patron_name(patron_id))
	emit_signal("patron_lock_changed", patron_locked, selected_patrons.duplicate())

func _resolve_reward_patron_id(patron_id: String) -> String:
	if patron_id == "":
		return choose_reward_patron_after_clear()
	if _is_patron_allowed_for_reward(patron_id):
		return patron_id
	return choose_reward_patron_after_clear()

func _resolve_gate_patron_id(patron_id: String) -> String:
	if patron_id == "":
		return ""
	if selected_patrons.has(patron_id):
		return patron_id
	if patron_locked:
		# A locked run cannot accept a third patron.
		return _get_random_selected_patron()
	if selected_patrons.size() < MAX_RUN_PATRONS:
		return patron_id
	return _get_random_selected_patron()

func _is_patron_allowed_for_reward(patron_id: String) -> bool:
	if patron_id == "":
		return false
	if patron_locked:
		return selected_patrons.has(patron_id)
	if selected_patrons.size() >= MAX_RUN_PATRONS:
		return selected_patrons.has(patron_id)
	return true

func _increase_relationship(patron_id: String, amount: int) -> void:
	if patron_id == "":
		return
	var current_value: int = int(relationships.get(patron_id, 0))
	var new_value: int = current_value + amount
	relationships[patron_id] = new_value
	emit_signal("relationship_changed", patron_id, new_value)

func _get_random_unselected_patron(fallback_patron_id: String) -> String:
	var patrons: Dictionary = PatronRegistry.get_patrons()
	var candidate_ids: Array[String] = []
	for key: Variant in patrons.keys():
		var patron_id: String = str(key)
		if not selected_patrons.has(patron_id):
			candidate_ids.append(patron_id)
	if candidate_ids.is_empty():
		if selected_patrons.is_empty():
			return fallback_patron_id
		return _get_random_selected_patron()
	var candidate_index: int = rng.randi_range(0, candidate_ids.size() - 1)
	return candidate_ids[candidate_index]

func _get_random_selected_patron() -> String:
	if selected_patrons.is_empty():
		return _get_random_unselected_patron("")
	var index: int = rng.randi_range(0, selected_patrons.size() - 1)
	return selected_patrons[index]

func _get_random_utility_choice() -> Dictionary:
	var utilities: Array[Dictionary] = PatronRegistry.get_utility_choices()
	var index: int = rng.randi_range(0, utilities.size() - 1)
	return utilities[index].duplicate(true)

func _selected_patron_names() -> String:
	var names: Array[String] = []
	for patron_id: String in selected_patrons:
		names.append(PatronRegistry.get_patron_name(patron_id))
	return " + ".join(names)

func _shuffle_strings(items: Array[String]) -> void:
	for i: int in range(items.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var temp: String = items[i]
		items[i] = items[j]
		items[j] = temp
