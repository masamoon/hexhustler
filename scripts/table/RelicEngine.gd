class_name RelicEngine
extends RefCounted

const RELICS: Dictionary = {
	&"money_ball": {
		"name": "Money Ball",
		"rarity": &"common",
		"family": [&"Economy"],
		"text": "Each table starts with one extra gold ball."
	},
	&"sniper": {
		"name": "Sniper",
		"rarity": &"common",
		"family": [&"Aim"],
		"text": "For your first 3 shots each table, the preview line reaches maximum length."
	},
	&"entropy_scanner": {
		"name": "Entropy Scanner",
		"rarity": &"rare",
		"family": [&"Aim", &"Ricochet"],
		"text": "For your first 3 shots each table, previews show extra ricochet continuations."
	},
	&"center_cut": {
		"name": "Center Cut",
		"rarity": &"common",
		"family": [&"Precision"],
		"text": "Perfect pots add score and $1."
	},
	&"rail_coupon": {
		"name": "Rail Coupon",
		"rarity": &"common",
		"family": [&"Bank", &"Economy"],
		"text": "Bank or kick pots pay cash."
	},
	&"combo_receipt": {
		"name": "Combo Receipt",
		"rarity": &"uncommon",
		"family": [&"Multi-pot"],
		"text": "Multi-pot shots add score and cash."
	},
	&"spare_ball": {
		"name": "Spare Ball",
		"rarity": &"uncommon",
		"family": [&"Safety"],
		"text": "Clearing a table with 3+ balls left restores 1 ball."
	},
	&"chalk_credit": {
		"name": "Chalk Credit",
		"rarity": &"uncommon",
		"family": [&"Economy", &"Control"],
		"text": "Soft-touch scoring shots pay cash."
	},
	&"long_glass": {
		"name": "Long Glass",
		"rarity": &"uncommon",
		"family": [&"Distance"],
		"text": "Long pots add score and cash."
	},
	&"hot_hand": {
		"name": "Hot Hand",
		"rarity": &"rare",
		"family": [&"Chain"],
		"text": "Chain Heat pots score more."
	},
	&"split_lens": {
		"name": "Split Lens",
		"rarity": &"rare",
		"family": [&"Ricochet"],
		"text": "Ricochet pots add extra cash."
	},
	&"called_tab": {
		"name": "Called Tab",
		"rarity": &"common",
		"family": [&"Called"],
		"text": "Called-pocket pots add cash."
	},
	&"bumper_policy": {
		"name": "Bumper Policy",
		"rarity": &"rare",
		"family": [&"Chaos", &"Safety"],
		"text": "Cluster-break shots add score and $1."
	},
	&"quiet_hands": {
		"name": "Quiet Hands",
		"rarity": &"rare",
		"family": [&"Control"],
		"text": "Soft Touch also grants +1 Style."
	}
}

func apply_on_shot_resolve(summary, relic_ids: Array[StringName], context: Dictionary) -> void:
	if relic_ids.has(&"center_cut") and summary.tags.has(&"PERFECT_POT"):
		var bonus: int = 180 * int(summary.perfect_pots)
		summary.final_score += bonus
		summary.cash_delta += int(summary.perfect_pots)
		summary.breakdown.append("Center Cut: +" + str(bonus) + ", +$" + str(int(summary.perfect_pots)))

	if relic_ids.has(&"rail_coupon") and (summary.tags.has(&"BANK") or summary.tags.has(&"KICK")):
		summary.cash_delta += 3
		summary.breakdown.append("Rail Coupon: +$3")

	if relic_ids.has(&"combo_receipt") and summary.tags.has(&"MULTI_POT"):
		summary.final_score += 220
		summary.cash_delta += 3
		summary.breakdown.append("Combo Receipt: +220, +$3")

	if relic_ids.has(&"chalk_credit") and summary.tags.has(&"SOFT_TOUCH"):
		summary.cash_delta += 2
		summary.breakdown.append("Chalk Credit: +$2")

	if relic_ids.has(&"long_glass") and summary.tags.has(&"LONG_POT"):
		summary.final_score += 150
		summary.cash_delta += 2
		summary.breakdown.append("Long Glass: +150, +$2")

	if relic_ids.has(&"hot_hand") and summary.tags.has(&"CHAIN_POT"):
		var hot_bonus := 130 * int(summary.chain_pot_count)
		summary.final_score += hot_bonus
		summary.breakdown.append("Hot Hand: +" + str(hot_bonus))

	if relic_ids.has(&"split_lens") and summary.tags.has(&"RICOCHET_POT"):
		var cash := 3 * int(summary.ricochet_pot_count)
		summary.cash_delta += cash
		summary.breakdown.append("Split Lens: +$" + str(cash))

	if relic_ids.has(&"called_tab") and summary.tags.has(&"CALLED_POCKET"):
		var called_cash := 2 * int(summary.called_pocket_hits)
		summary.cash_delta += called_cash
		summary.breakdown.append("Called Tab: +$" + str(called_cash))

	if relic_ids.has(&"bumper_policy") and summary.tags.has(&"CLUSTER_BREAK"):
		summary.final_score += 140
		summary.cash_delta += 1
		summary.breakdown.append("Bumper Policy: +140, +$1")

	if relic_ids.has(&"quiet_hands") and summary.tags.has(&"SOFT_TOUCH"):
		summary.style_delta += 1
		summary.breakdown.append("Quiet Hands: +1 Style")

func apply_on_table_complete(summary, relic_ids: Array[StringName], balls_left: int, run_style: int) -> Dictionary:
	var result := {"score": 0, "cash": 0, "style": 0, "notes": []}
	var notes: Array[String] = []
	if relic_ids.has(&"spare_ball") and balls_left >= 3:
		result["health"] = 1
		notes.append("Spare Ball: +1 ball")
	result["notes"] = notes
	return result

func apply_on_table_fail(relic_ids: Array[StringName]) -> Dictionary:
	var result := {"health": 0, "notes": []}
	result["notes"] = []
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
