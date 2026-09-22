## 可锁定目标契约。挂在敌人身体（CharacterBody2D）下，进 lockable 组。
## 锁定系统只问这个组件：点在哪、还活不活，不认具体敌人类型。
class_name LockableTarget
extends Node

## 进这个组的才算可锁目标。
const GROUP := &"lockable"

## 用来算距离的身体；空则用父节点。
@export var host: Node2D
## 用来取视觉中心的精灵；空则在 host 下找第一个非影子 Sprite2D。
@export var visual: Node2D
## 生命；空则视为永远可锁。死后由锁定系统丢掉目标。
@export var health: HealthComponent
## 相对视觉中心的微调（像素，正 Y 向下）。
@export var lock_offset: Vector2 = Vector2.ZERO


func _enter_tree() -> void:
	add_to_group(GROUP)


func _exit_tree() -> void:
	remove_from_group(GROUP)


func _ready() -> void:
	if host == null:
		host = get_parent() as Node2D
	if visual == null and host != null:
		visual = EffectComm.find_visual(host)
	if health == null:
		health = get_parent().get_node_or_null("HealthComponent") as HealthComponent


## 身体节点，给距离/范围用。
func get_host() -> Node2D:
	if host != null:
		return host
	return get_parent() as Node2D


## 锁图标要贴的世界坐标：精灵显示中心 + 微调。
func get_lock_point() -> Vector2:
	var vis := visual
	if vis == null:
		var h := get_host()
		return (h.global_position if h else Vector2.ZERO) + lock_offset
	var sprite := vis as Sprite2D
	if sprite != null:
		return sprite.to_global(sprite.get_rect().get_center()) + lock_offset
	var animated := vis as AnimatedSprite2D
	if animated != null:
		return animated.global_position + lock_offset
	return vis.global_position + lock_offset


## 死了就不能再锁。
func is_alive() -> bool:
	if health == null:
		return true
	return not health.is_dead
