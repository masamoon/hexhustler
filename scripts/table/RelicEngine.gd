class_name RelicEngine
extends RefCounted

const RELICS: Dictionary = {
	&"money_ball": {
		"name": "Midas Eye",
		"rarity": &"common",
		"family": [&"Offering", &"Economy"],
		"text": "Each table starts with one extra gold ball, a bright tithe for the house."
	},
	&"sniper": {
		"name": "Dead Man's Sight",
		"rarity": &"common",
		"family": [&"Omen", &"Aim"],
		"text": "For your first 3 shots each table, the preview line reaches maximum length."
	},
	&"entropy_scanner": {
		"name": "Oracle Prism",
		"rarity": &"rare",
		"family": [&"Omen", &"Ricochet"],
		"text": "For your first 3 shots each table, previews show extra ricochet continuations."
	},
	&"center_cut": {
		"name": "Saint's Needle",
		"rarity": &"common",
		"family": [&"Rite", &"Precision"],
		"text": "Perfect pots add Reputation and $1 Bankroll."
	},
	&"rail_coupon": {
		"name": "Rail Tithe",
		"rarity": &"common",
		"family": [&"Oath", &"Bank"],
		"text": "Bank or kick pots pay Bankroll."
	},
	&"combo_receipt": {
		"name": "Twin-Tongue Ledger",
		"rarity": &"uncommon",
		"family": [&"Offering", &"Multi-pot"],
		"text": "Multi-pot shots add Reputation and Bankroll."
	},
	&"spare_ball": {
		"name": "Bone Insurance",
		"rarity": &"uncommon",
		"family": [&"Ward", &"Safety"],
		"text": "Clearing a table with 3+ balls left restores 1 ball."
	},
	&"chalk_credit": {
		"name": "Pale Chalk",
		"rarity": &"uncommon",
		"family": [&"Ward", &"Control"],
		"text": "Soft-touch shots that earn Reputation also pay Bankroll."
	},
	&"long_glass": {
		"name": "Mourner's Glass",
		"rarity": &"uncommon",
		"family": [&"Omen", &"Distance"],
		"text": "Long pots add Reputation and Bankroll."
	},
	&"hot_hand": {
		"name": "Ember Palm",
		"rarity": &"rare",
		"family": [&"Flame", &"Chain"],
		"text": "Chain Heat pots earn more Reputation."
	},
	&"split_lens": {
		"name": "Mirror Hex",
		"rarity": &"rare",
		"family": [&"Hex", &"Ricochet"],
		"text": "Ricochet pots add extra Bankroll."
	},
	&"called_tab": {
		"name": "Spoken Debt",
		"rarity": &"common",
		"family": [&"Oath", &"Called"],
		"text": "Called-pocket pots add Bankroll."
	},
	&"bumper_policy": {
		"name": "Riot Charm",
		"rarity": &"rare",
		"family": [&"Hex", &"Chaos"],
		"text": "Cluster-break shots add Reputation and $1 Bankroll."
	},
	&"quiet_hands": {
		"name": "Velvet Prayer",
		"rarity": &"rare",
		"family": [&"Ward", &"Control"],
		"text": "Soft Touch also grants +1 Style."
	},
	&"witching_well": {
		"name": "Witching Well",
		"rarity": &"uncommon",
		"family": [&"Field", &"Control"],
		"text": "A center sigil gently pulls moving object balls inward. Long or carom pots through the well add Reputation."
	},
	&"salt_circle": {
		"name": "Salt Circle",
		"rarity": &"common",
		"family": [&"Field", &"Ward"],
		"text": "A pale ward steadies balls near center. Soft-touch shots gain Reputation and Style."
	},
	&"blood_moon": {
		"name": "Blood Moon",
		"rarity": &"rare",
		"family": [&"Field", &"Risk"],
		"text": "A red moon field wakes risk balls. Risk-ball pots add Reputation and Bankroll."
	},
	&"grave_lantern": {
		"name": "Grave Lantern",
		"rarity": &"uncommon",
		"family": [&"Field", &"Called"],
		"text": "The called pocket burns with a grave light. Called-pocket pots add Reputation and Bankroll."
	}
}

func apply_on_shot_resolve(summary, relic_ids: Array[StringName], context: Dictionary) -> void:
	if relic_ids.has(&"center_cut") and summary.tags.has(&"PERFECT_POT"):
		var bonus: int = 180 * int(summary.perfect_pots)
		summary.final_score += bonus
		summary.cash_delta += int(summary.perfect_pots)
		summary.breakdown.append("Saint's Needle: +" + str(bonus) + " Rep, +$" + str(int(summary.perfect_pots)) + " Bankroll")

	if relic_ids.has(&"rail_coupon") and (summary.tags.has(&"BANK") or summary.tags.has(&"KICK")):
		summary.cash_delta += 3
		summary.breakdown.append("Rail Tithe: +$3 Bankroll")

	if relic_ids.has(&"combo_receipt") and summary.tags.has(&"MULTI_POT"):
		summary.final_score += 220
		summary.cash_delta += 3
		summary.breakdown.append("Twin-Tongue Ledger: +220 Rep, +$3 Bankroll")

	if relic_ids.has(&"chalk_credit") and summary.tags.has(&"SOFT_TOUCH"):
		summary.cash_delta += 2
		summary.breakdown.append("Pale Chalk: +$2 Bankroll")

	if relic_ids.has(&"long_glass") and summary.tags.has(&"LONG_POT"):
		summary.final_score += 150
		summary.cash_delta += 2
		summary.breakdown.append("Mourner's Glass: +150 Rep, +$2 Bankroll")

	if relic_ids.has(&"hot_hand") and summary.tags.has(&"CHAIN_POT"):
		var hot_bonus := 130 * int(summary.chain_pot_count)
		summary.final_score += hot_bonus
		summary.breakdown.append("Ember Palm: +" + str(hot_bonus) + " Rep")

	if relic_ids.has(&"split_lens") and summary.tags.has(&"RICOCHET_POT"):
		var cash := 3 * int(summary.ricochet_pot_count)
		summary.cash_delta += cash
		summary.breakdown.append("Mirror Hex: +$" + str(cash) + " Bankroll")

	if relic_ids.has(&"called_tab") and summary.tags.has(&"CALLED_POCKET"):
		var called_cash := 2 * int(summary.called_pocket_hits)
		summary.cash_delta += called_cash
		summary.breakdown.append("Spoken Debt: +$" + str(called_cash) + " Bankroll")

	if relic_ids.has(&"bumper_policy") and summary.tags.has(&"CLUSTER_BREAK"):
		summary.final_score += 140
		summary.cash_delta += 1
		summary.breakdown.append("Riot Charm: +140 Rep, +$1 Bankroll")

	if relic_ids.has(&"quiet_hands") and summary.tags.has(&"SOFT_TOUCH"):
		summary.style_delta += 1
		summary.breakdown.append("Velvet Prayer: +1 Style")

	if relic_ids.has(&"witching_well") and (summary.tags.has(&"LONG_POT") or summary.tags.has(&"CAROM") or summary.tags.has(&"KISS")):
		var well_bonus := 120
		if summary.tags.has(&"LONG_POT"):
			well_bonus += 40
		summary.final_score += well_bonus
		summary.breakdown.append("Witching Well: +" + str(well_bonus) + " Rep")

	if relic_ids.has(&"salt_circle") and summary.tags.has(&"SOFT_TOUCH") and summary.has_successful_pot():
		summary.final_score += 90
		summary.style_delta += 1
		summary.breakdown.append("Salt Circle: +90 Rep, +1 Style")

	if relic_ids.has(&"blood_moon") and _summary_has_kind(summary, &"risk"):
		var risk_count := _summary_kind_count(summary, &"risk")
		var moon_score := 180 * risk_count
		var moon_cash := 2 * risk_count
		summary.final_score += moon_score
		summary.cash_delta += moon_cash
		summary.breakdown.append("Blood Moon: +" + str(moon_score) + " Rep, +$" + str(moon_cash) + " Bankroll")

	if relic_ids.has(&"grave_lantern") and summary.tags.has(&"CALLED_POCKET"):
		var lantern_score := 110 * int(summary.called_pocket_hits)
		var lantern_cash := int(summary.called_pocket_hits)
		summary.final_score += lantern_score
		summary.cash_delta += lantern_cash
		summary.breakdown.append("Grave Lantern: +" + str(lantern_score) + " Rep, +$" + str(lantern_cash) + " Bankroll")

func apply_on_table_complete(summary, relic_ids: Array[StringName], balls_left: int, run_style: int) -> Dictionary:
	var result := {"score": 0, "cash": 0, "style": 0, "notes": []}
	var notes: Array[String] = []
	if relic_ids.has(&"spare_ball") and balls_left >= 3:
		result["health"] = 1
		notes.append("Bone Insurance: +1 soul marker")
	result["notes"] = notes
	return result

func _summary_has_kind(summary, kind: StringName) -> bool:
	for potted_kind in summary.potted_kinds:
		if potted_kind == kind:
			return true
	return false

func _summary_kind_count(summary, kind: StringName) -> int:
	var count := 0
	for potted_kind in summary.potted_kinds:
		if potted_kind == kind:
			count += 1
	return count

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
