## 伤害信息组件
class_name DamageInfo
extends RefCounted

## 这一击要扣多少血。
var amount: int = 1

## 攻击者是谁。
var source: Node2D

## 命中的判定盒， 同一刀不能判定多次
var hitbox: Area2D


## 打中时现拼一份伤害数据
static func make(amount: int, source: Node2D, hitbox: Area2D) -> DamageInfo:
	var info := DamageInfo.new()
	info.amount = amount
	info.source = source
	info.hitbox = hitbox
	return info
