class_name ScoringEngine
extends RefCounted

func travel_score_for_distance(distance: float) -> int:
	return maxi(0, int(round((distance - 110.0) * 0.34)))

func score(summary, table_def: Dictionary, potted_records: Array[Dictionary], has_witchwood: bool) -> void:
	var score_total := 0
	var cash_total := 0
	var jackpot_pocket: StringName = table_def.get("jackpot_pocket", &"")
	var risk_pocket: StringName = table_def.get("risk_pocket", table_def.get("cursed_pocket", &""))
	var modifier: StringName = table_def.get("modifier", &"")
	var risk_pocket_hit := false

	for record in potted_records:
		var kind: StringName = record.get("kind", &"normal")
		var ball_score := int(record.get("score", 100))
		var ball_cash := int(record.get("cash", 0))
		var pocket_id: StringName = record.get("pocket_id", &"")
		var travel_score := travel_score_for_distance(float(record.get("travel", 0.0)))
		if travel_score > 0:
			ball_score += travel_score
			summary.travel_score_total += travel_score
			summary.breakdown.append("Travel run: +" + str(travel_score) + " Rep")

		if _is_risk_kind(kind):
			ball_score += 120
			ball_cash += 1
			summary.breakdown.append("Risk ball cashed: +120 Rep, +$1 Bankroll")

		if pocket_id == jackpot_pocket:
			ball_score *= 3
			ball_cash += 3
			summary.breakdown.append("Jackpot pocket x3")
		if risk_pocket != &"" and pocket_id == risk_pocket and not risk_pocket_hit:
			risk_pocket_hit = true
			ball_score = max(0, ball_score - 60)
			summary.breakdown.append("Risk pocket tax: -60 Rep")

		if modifier == &"bank_bonus":
			if summary.tags.has(&"BANK"):
				ball_score = int(ball_score * 1.8)
				summary.breakdown.append("Long Way bank boost")
			else:
				ball_score = int(ball_score * 0.65)
				summary.breakdown.append("Direct pot taxed")

		if kind == &"gold":
			ball_cash += 5
			summary.breakdown.append("Gold ball: +$5 Bankroll")

		if bool(record.get("ricochet", false)):
			ball_score += 260
			summary.breakdown.append("Ricochet pot: +260 Rep")
		if bool(record.get("chain", false)):
			ball_score += 110
			summary.breakdown.append("Chain heat: +110 Rep")

		score_total += ball_score
		cash_total += ball_cash

	if modifier == &"collision_bonus" and summary.max_collision_speed > 260.0:
		var fight_score := int(summary.max_collision_speed * 0.35)
		score_total += fight_score
		summary.breakdown.append("Bar Fight impact: +" + str(fight_score) + " Rep")

	if summary.tags.has(&"MULTI_POT"):
		score_total += 150
		summary.style_delta += 1
		summary.breakdown.append("Multi-pot: +150 Rep, +1 Style")
	if summary.tags.has(&"CAROM"):
		score_total += 120
		summary.breakdown.append("Carom: +120 Rep")
	if summary.tags.has(&"KISS"):
		var kiss_bonus: int = 100 * int(summary.kiss_pots)
		score_total += kiss_bonus
		summary.breakdown.append("Kiss pot: +" + str(kiss_bonus) + " Rep")
	if summary.tags.has(&"LONG_POT"):
		score_total += 130
		summary.breakdown.append("Long pot: +130 Rep")
	if summary.tags.has(&"KICK"):
		score_total += 140
		summary.style_delta += 1
		summary.breakdown.append("Kick shot: +140 Rep, +1 Style")
	if summary.tags.has(&"POWER_SHOT") and summary.has_successful_pot():
		score_total += 60
		summary.breakdown.append("Power shot: +60 Rep")
	if summary.tags.has(&"SOFT_TOUCH"):
		score_total += 110
		summary.breakdown.append("Soft touch: +110 Rep")
	if summary.tags.has(&"PERFECT_POT"):
		score_total += 125 * summary.perfect_pots
		summary.breakdown.append("Perfect cut: +" + str(125 * summary.perfect_pots) + " Rep")
	if summary.tags.has(&"CALLED_POCKET"):
		var called_bonus: int = 140 * int(summary.called_pocket_hits)
		score_total += called_bonus
		summary.style_delta += 1
		summary.breakdown.append("Called pocket: +" + str(called_bonus) + " Rep, +1 Style")
	if summary.scratch:
		score_total = max(0, score_total - 120)
		summary.breakdown.append("Scratch: -120 Rep")
	if summary.tags.has(&"POWER_SHOT") and not summary.has_successful_pot():
		score_total = max(0, score_total - 80)
		summary.style_delta -= 1
		summary.breakdown.append("Wild power miss: -80 Rep, -1 Style")

	summary.base_score = score_total
	summary.final_score = score_total
	summary.cash_delta += cash_total

func _is_risk_kind(kind: StringName) -> bool:
	return kind == &"risk" or kind == &"cursed"
