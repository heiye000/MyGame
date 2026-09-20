class_name DamageInfo
extends RefCounted

## 发出方当时的整份属性；结算时按需取 attack / 以后的防御等。
var stats: StatsComponent
## 谁打出来的。
var source: Node2D
## 哪一口判定盒打中的。
var hitbox: Area2D


## 命中时只传发出方 Stats，避免每加一个战斗数字就改 make 签名。
static func make(stats: StatsComponent, source: Node2D, hitbox: Area2D) -> DamageInfo:
	var info := DamageInfo.new()
	info.stats = stats
	info.source = source
	info.hitbox = hitbox
	return info
