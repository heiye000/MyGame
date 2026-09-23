@tool
class_name SlashSwing
extends Node2D

## 挥出后，刀光图和伤害多边形一起平移的方向。为零则停在原地。
@export var advance_direction: Vector2 = Vector2.ZERO
## 平移速度，像素/秒。方向为零时这个数不会生效。
@export var advance_speed: float = 24.0


## 按八向名播放。具体播哪条、要不要翻转，由子类决定。
func play_direction(_direction_name: StringName) -> void:
	push_warning("SlashSwing.play_direction 还没实现：%s" % get_path())


## 这把刀的伤害盒。子类节点不一样时重写这个函数。
func get_hitbox() -> Hitbox:
	return get_node_or_null("Body/Hitbox") as Hitbox


## 播完用来把自己删掉。
func get_animation_player() -> AnimationPlayer:
	return get_node_or_null("AnimationPlayer") as AnimationPlayer


func _process(_delta: float) -> void:
	var body := get_node_or_null("Body") as Node2D
	var player := get_animation_player()
	if body == null or player == null:
		return
	if advance_direction == Vector2.ZERO:
		body.position = Vector2.ZERO
		return
	var elapsed := player.current_animation_position
	body.position = advance_direction.normalized() * advance_speed * elapsed
