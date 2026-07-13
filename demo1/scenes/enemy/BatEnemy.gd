class_name BatEnemy
extends Node2D

@onready var character: CharacterBody2D = $CharacterBody2D
@onready var animation_tree: BatAnimationTree = $AnimationTree

## 当前水平朝向，用于左右 idle 镜像切换。
var facing_direction: Vector2 = Vector2.RIGHT


func _ready() -> void:
	animation_tree.active = true
	animation_tree.advance_expression_base_node = NodePath(".")
	animation_tree.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_PHYSICS
	animation_tree.set_facing(facing_direction)


## 更新蝙蝠水平朝向并同步到动画树 blend。
func set_facing(direction: Vector2) -> void:
	if direction.x != 0.0:
		facing_direction = Vector2(signf(direction.x), 0.0)
	animation_tree.set_facing(facing_direction)
