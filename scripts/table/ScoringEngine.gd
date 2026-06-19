class_name ScoringEngine
extends RefCounted

func score(summary, table_def: Dictionary, potted_records: Array[Dictionary], has_witchwood: bool) -> void:
	var score_total := 0
	var cash_total := 0
	var jackpot_pocket: StringName = table_def.get("jackpot_pocket", &"")
	var cursed_pocket: StringName = table_def.get("cursed_pocket", &"")
	var modifier: StringName = table_def.get("modifier", &"")
	var cursed_pocket_hit := false

	for record in potted_records:
		var kind: StringName = record.get("kind", &"normal")
		var ball_score := int(record.get("score", 100))
		var ball_cash := int(record.get("cash", 0))
		var pocket_id: StringName = record.get("pocket_id", &"")

		if kind == &"cursed" and not has_witchwood:
			summary.health_delta -= 1
			summary.curse_damage += 1
			summary.breakdown.append("Cursed ball: -1 rep")
			continue

		if kind == &"cursed" and has_witchwood:
			ball_score += 160
			summary.breakdown.append("Witchwood redeemed curse: +160")

		if pocket_id == jackpot_pocket:
			ball_score *= 3
			ball_cash += 3
			summary.breakdown.append("Jackpot pocket x3")
		if cursed_pocket != &"" and pocket_id == cursed_pocket and not cursed_pocket_hit:
			cursed_pocket_hit = true
			summary.health_delta -= 1
			summary.curse_damage += 1
			ball_score = max(0, ball_score - 60)
			summary.breakdown.append("Cursed pocket: -60, -1 rep")

		if modifier == &"bank_bonus":
			if summary.tags.has(&"BANK"):
				ball_score = int(ball_score * 1.8)
				summary.breakdown.append("Long Way bank boost")
			else:
				ball_score = int(ball_score * 0.65)
				summary.breakdown.append("Direct pot taxed")

		if kind == &"gold":
			ball_cash += 5
			summary.breakdown.append("Gold ball: +$5")

		score_total += ball_score
		cash_total += ball_cash

	if modifier == &"collision_bonus" and summary.max_collision_speed > 260.0:
		var fight_score := int(summary.max_collision_speed * 0.35)
		score_total += fight_score
		summary.breakdown.append("Bar Fight impact: +" + str(fight_score))

	if summary.tags.has(&"MULTI_POT"):
		score_total += 150
		summary.style_delta += 1
		summary.breakdown.append("Multi-pot: +150, +1 Style")
	if summary.tags.has(&"CAROM"):
		score_total += 120
		summary.breakdown.append("Carom: +120")
	if summary.tags.has(&"KISS"):
		var kiss_bonus: int = 100 * int(summary.kiss_pots)
		score_total += kiss_bonus
		summary.breakdown.append("Kiss pot: +" + str(kiss_bonus))
	if summary.tags.has(&"LONG_POT"):
		score_total += 130
		summary.breakdown.append("Long pot: +130")
	if summary.tags.has(&"KICK"):
		score_total += 140
		summary.style_delta += 1
		summary.breakdown.append("Kick shot: +140, +1 Style")
	if summary.tags.has(&"POWER_SHOT") and summary.has_successful_pot():
		score_total += 60
		summary.breakdown.append("Power shot: +60")
	if summary.tags.has(&"SOFT_TOUCH"):
		score_total += 110
		summary.breakdown.append("Soft touch: +110")
	if summary.tags.has(&"PERFECT_POT"):
		score_total += 125 * summary.perfect_pots
		summary.breakdown.append("Perfect cut: +" + str(125 * summary.perfect_pots))
	if summary.tags.has(&"CALLED_POCKET"):
		var called_bonus: int = 140 * int(summary.called_pocket_hits)
		score_total += called_bonus
		summary.style_delta += 1
		summary.breakdown.append("Called pocket: +" + str(called_bonus) + ", +1 Style")
	if summary.scratch:
		score_total = max(0, score_total - 120)
		summary.health_delta -= 1
		summary.breakdown.append("Scratch: -120, -1 rep")
	if summary.tags.has(&"POWER_SHOT") and not summary.has_successful_pot():
		score_total = max(0, score_total - 80)
		summary.style_delta -= 1
		summary.breakdown.append("Wild power miss: -80, -1 Style")

	summary.base_score = score_total
	summary.final_score = score_total
	summary.cash_delta += cash_total
