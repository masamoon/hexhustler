class_name ShotEventLog
extends RefCounted

var shot_id: int = 0
var events: Array = []

func begin_shot(new_shot_id: int) -> void:
	shot_id = new_shot_id
	events.clear()

func add_event(event) -> void:
	events.append(event)

func count_type(event_type: int) -> int:
	var count := 0
	for event in events:
		if event.type == event_type:
			count += 1
	return count

func events_of_type(event_type: int) -> Array:
	var matching: Array = []
	for event in events:
		if event.type == event_type:
			matching.append(event)
	return matching
