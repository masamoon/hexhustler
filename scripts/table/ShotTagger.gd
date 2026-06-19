class_name ShotTagger
extends RefCounted

func derive_tags(summary) -> Array[StringName]:
	var tags: Array[StringName] = []
	if summary.has_successful_pot():
		tags.append(&"POT")
	if summary.potted_ball_ids.size() >= 2:
		tags.append(&"MULTI_POT")
	if summary.has_successful_pot() and summary.rail_hits > 0:
		tags.append(&"BANK")
	if summary.has_successful_pot() and summary.longest_pot_distance >= 430.0:
		tags.append(&"LONG_POT")
	if summary.has_successful_pot() and summary.cue_rail_before_object_contact:
		tags.append(&"KICK")
	if summary.has_successful_pot() and summary.cue_object_contacts >= 2:
		tags.append(&"CAROM")
	if summary.has_successful_pot() and summary.kiss_pots > 0:
		tags.append(&"KISS")
	if summary.scratch:
		tags.append(&"SCRATCH")
	if summary.has_successful_pot() and summary.power_normalized >= 0.74:
		tags.append(&"POWER_SHOT")
	if summary.has_successful_pot() and summary.power_normalized <= 0.28:
		tags.append(&"SOFT_TOUCH")
	if summary.moved_ball_count >= 4:
		tags.append(&"CLUSTER_BREAK")
	if summary.perfect_pots > 0:
		tags.append(&"PERFECT_POT")
	if summary.called_pocket_hits > 0:
		tags.append(&"CALLED_POCKET")
	if summary.boss_damage > 0:
		tags.append(&"BOSS_HIT")
	return tags
