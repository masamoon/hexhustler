class_name RelicEngine
extends RefCounted

const RELICS: Dictionary = {
	&"bankers_ring": {
		"name": "Banker's Ring",
		"rarity": &"common",
		"family": [&"Bank", &"Style"],
		"text": "Bank pots score +25% and grant +1 Style."
	},
	&"rail_tax": {
		"name": "Rail Tax",
		"rarity": &"common",
		"family": [&"Bank", &"Economy"],
		"text": "Successful pots pay $1 per rail hit."
	},
	&"center_cut": {
		"name": "Center Cut",
		"rarity": &"common",
		"family": [&"Precision"],
		"text": "Perfect pots add +250 score."
	},
	&"cluster_breaker": {
		"name": "Cluster Breaker",
		"rarity": &"uncommon",
		"family": [&"Chaos", &"Style"],
		"text": "Moving 4+ balls grants $3 and +1 Style."
	},
	&"thunder_break": {
		"name": "Thunder Break",
		"rarity": &"uncommon",
		"family": [&"Power", &"Break"],
		"text": "First shot of a table moving 5+ balls adds +300 and $3."
	},
	&"gold_leaf": {
		"name": "Gold Leaf",
		"rarity": &"uncommon",
		"family": [&"Economy"],
		"text": "Each table starts with an extra gold ball."
	},
	&"witchwood_triangle": {
		"name": "Witchwood Triangle",
		"rarity": &"uncommon",
		"family": [&"Curse", &"Safety"],
		"text": "Cursed balls score instead of hurting you."
	},
	&"pocket_monopoly": {
		"name": "Pocket Monopoly",
		"rarity": &"rare",
		"family": [&"Pocket", &"Economy"],
		"text": "Repeated use of one pocket grows its score bonus."
	},
	&"dead_eye_lens": {
		"name": "Dead-Eye Lens",
		"rarity": &"rare",
		"family": [&"Precision", &"Called"],
		"text": "Called-pocket aim preview is longer, and called pots score extra."
	},
	&"high_roller_chip": {
		"name": "High Roller Chip",
		"rarity": &"rare",
		"family": [&"Risk", &"Economy"],
		"text": "Clear with shots spare to gain $6 and +250 score. Failed tables cost +1 reputation."
	},
	&"firecracker_ball": {
		"name": "Firecracker Ball",
		"rarity": &"rare",
		"family": [&"Chaos", &"Power"],
		"text": "The first potted ball each table detonates."
	},
	&"tip_jar": {
		"name": "Tip Jar",
		"rarity": &"uncommon",
		"family": [&"Style", &"Economy"],
		"text": "Completing a table converts Style into cash."
	},
	&"white_gloves": {
		"name": "White Gloves",
		"rarity": &"rare",
		"family": [&"Precision", &"Reward"],
		"text": "No-scratch table clears offer a fourth reward choice."
	},
	&"velvet_rails": {
		"name": "Velvet Rails",
		"rarity": &"uncommon",
		"family": [&"Bank", &"Control"],
		"text": "Rail bounces preserve extra speed."
	},
	&"no_loose_ends": {
		"name": "No Loose Ends",
		"rarity": &"rare",
		"family": [&"Finisher", &"Score"],
		"text": "Potting the last required ball adds a big score bonus."
	},
	&"side_bet_slip": {
		"name": "Side-Bet Slip",
		"rarity": &"common",
		"family": [&"Called", &"Economy"],
		"text": "Called-pocket pots add score and $2 per called hit."
	},
	&"chapel_candle": {
		"name": "Chapel Candle",
		"rarity": &"uncommon",
		"family": [&"Carom", &"Style"],
		"text": "Carom or kiss pots add score and +1 Style."
	},
	&"rain_check": {
		"name": "Rain Check",
		"rarity": &"uncommon",
		"family": [&"Bank", &"Distance"],
		"text": "Long pots pay cash; long bank pots pay even more."
	},
	&"mirror_hex": {
		"name": "Mirror Hex",
		"rarity": &"rare",
		"family": [&"Safety", &"Risk"],
		"text": "A scratch on a scoring shot refunds the reputation loss and adds score."
	}
}

func apply_on_shot_resolve(summary, relic_ids: Array[StringName], context: Dictionary) -> void:
	if relic_ids.has(&"bankers_ring") and summary.tags.has(&"BANK"):
		summary.final_score = int(summary.final_score * 1.25)
		summary.style_delta += 1
		summary.breakdown.append("Banker's Ring: x1.25, +1 Style")

	if relic_ids.has(&"rail_tax") and summary.has_successful_pot():
		var cash: int = int(summary.rail_hits)
		summary.cash_delta += cash
		summary.breakdown.append("Rail Tax: +$" + str(cash))

	if relic_ids.has(&"center_cut") and summary.tags.has(&"PERFECT_POT"):
		var bonus: int = 250 * int(summary.perfect_pots)
		summary.final_score += bonus
		summary.breakdown.append("Center Cut: +" + str(bonus))

	if relic_ids.has(&"cluster_breaker") and summary.tags.has(&"CLUSTER_BREAK"):
		summary.cash_delta += 3
		summary.style_delta += 1
		summary.breakdown.append("Cluster Breaker: +$3, +1 Style")

	if relic_ids.has(&"thunder_break") and int(context.get("table_shot_number", 0)) == 1 and summary.moved_ball_count >= 5:
		summary.final_score += 300
		summary.cash_delta += 3
		summary.breakdown.append("Thunder Break: +300, +$3")

	if relic_ids.has(&"pocket_monopoly") and summary.has_successful_pot():
		var pocket_use: Dictionary = context.get("pocket_use", {})
		var best_bonus := 0
		for pocket_id in summary.pocket_ids:
			var uses := int(pocket_use.get(pocket_id, 0))
			best_bonus = max(best_bonus, uses * 60)
		if best_bonus > 0:
			summary.final_score += best_bonus
			summary.breakdown.append("Pocket Monopoly: +" + str(best_bonus))

	if relic_ids.has(&"dead_eye_lens") and summary.tags.has(&"CALLED_POCKET"):
		var called_bonus: int = 120 * int(summary.called_pocket_hits)
		summary.final_score += called_bonus
		summary.breakdown.append("Dead-Eye Lens called shot: +" + str(called_bonus))

	if relic_ids.has(&"no_loose_ends") and summary.has_successful_pot() and int(context.get("remaining_required_balls", 1)) == 0:
		var end_bonus := maxi(240, int(summary.base_score * 0.75))
		summary.final_score += end_bonus
		summary.breakdown.append("No Loose Ends: +" + str(end_bonus))

	if relic_ids.has(&"side_bet_slip") and summary.tags.has(&"CALLED_POCKET"):
		var called_hits := int(summary.called_pocket_hits)
		var side_score := 80 * called_hits
		var side_cash := 2 * called_hits
		summary.final_score += side_score
		summary.cash_delta += side_cash
		summary.breakdown.append("Side-Bet Slip: +" + str(side_score) + ", +$" + str(side_cash))

	if relic_ids.has(&"chapel_candle") and (summary.tags.has(&"CAROM") or summary.tags.has(&"KISS")):
		summary.final_score += 140
		summary.style_delta += 1
		summary.breakdown.append("Chapel Candle: +140, +1 Style")

	if relic_ids.has(&"rain_check") and summary.tags.has(&"LONG_POT"):
		if summary.tags.has(&"BANK"):
			summary.final_score += 240
			summary.cash_delta += 4
			summary.breakdown.append("Rain Check long bank: +240, +$4")
		else:
			summary.cash_delta += 2
			summary.breakdown.append("Rain Check long pot: +$2")

	if relic_ids.has(&"mirror_hex") and summary.scratch and summary.has_successful_pot():
		summary.health_delta += 1
		summary.final_score += 160
		summary.breakdown.append("Mirror Hex forgave scoring scratch: +160")

func apply_on_table_complete(summary, relic_ids: Array[StringName], shots_remaining: int, run_style: int) -> Dictionary:
	var result := {"score": 0, "cash": 0, "style": 0, "notes": []}
	var notes: Array[String] = []
	if relic_ids.has(&"high_roller_chip") and shots_remaining >= 2:
		result["score"] = int(result["score"]) + 250
		result["cash"] = int(result["cash"]) + 6
		notes.append("High Roller Chip: +250, +$6")
	if relic_ids.has(&"tip_jar") and run_style > 0:
		result["cash"] = int(result["cash"]) + run_style
		notes.append("Tip Jar: +$" + str(run_style))
	result["notes"] = notes
	return result

func apply_on_table_fail(relic_ids: Array[StringName]) -> Dictionary:
	var result := {"health": 0, "notes": []}
	var notes: Array[String] = []
	if relic_ids.has(&"high_roller_chip"):
		result["health"] = int(result["health"]) - 1
		notes.append("High Roller Chip marker called: -1 reputation")
	result["notes"] = notes
	return result

func get_display_name(id: StringName) -> String:
	return String(RELICS.get(id, {}).get("name", id))

func get_description(id: StringName) -> String:
	return String(RELICS.get(id, {}).get("text", ""))

func get_rarity(id: StringName) -> StringName:
	return RELICS.get(id, {}).get("rarity", &"common")

func get_rarity_display(id: StringName) -> String:
	return String(get_rarity(id)).capitalize()

func get_family_text(id: StringName) -> String:
	var families: Array = RELICS.get(id, {}).get("family", [])
	var names: Array[String] = []
	for family in families:
		names.append(String(family))
	return ", ".join(names)

func get_metadata_line(id: StringName) -> String:
	var family_text := get_family_text(id)
	if family_text == "":
		return get_rarity_display(id)
	return get_rarity_display(id) + " | " + family_text

func all_relic_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for id in RELICS.keys():
		ids.append(id)
	return ids
