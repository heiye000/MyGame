class_name DamageInfo
extends RefCounted

## 发出方当时的整份属性；结算时按需取 attack / 以后的防御等。
var stats: StatsComponent
## 谁打出来的。
var source: Node2D
## 哪一口判定盒打中的。
var hitbox: Area2D

## 防守方能否格挡这刀。
var can_be_blocked: bool = true
## 防守方能否精确弹反这刀。
var can_be_perfect_parried: bool = true


static func make(stats: StatsComponent, source: Node2D, hitbox: Area2D) -> DamageInfo:
	var info := DamageInfo.new()
	info.stats = stats
	info.source = source
	info.hitbox = hitbox
	var attack := hitbox as Hitbox
	if attack != null:
		info.can_be_blocked = attack.can_be_blocked
		info.can_be_perfect_parried = attack.can_be_perfect_parried
	return info
