extends Node

signal cutscene_finished

func _ready():
	EventManager.cutscene_requested.connect(_on_cutscene_requested)
func _on_cutscene_requested(events: Array) -> void:
	await play_events(events)
	cutscene_finished.emit()
func play_events(events: Array) -> void:
	for e in events:
		match e.event_type:
			"talk":
				await EventManager.show_dialog_by_id(e.dialog_id)

			"battle":
				await EventManager.start_battle(e.battle_enemy_ids)

			"cutscene":
				await _run_cutscene_key(e.event_key)

			"join":
				PartyManager.add_member(e.member_id)

			"flag":
				_set_flag(e.flag_key, e.flag_value)

func _run_cutscene_key(event_key: String) -> void:
	match event_key:
		"opening_done":
			EventManager.opening_done = true
			print("opening_done set true")

		"moeko_join":
			PartyManager.add_member("girl")
			print("モエ子が加入した！")

		_:
			print("unknown cutscene:", event_key)

func _set_flag(flag_key: String, flag_value: bool) -> void:
	match flag_key:
		"opening_done":
			EventManager.opening_done = flag_value
			print("opening_done =", flag_value)
		_:
			print("unknown flag:", flag_key, flag_value)
