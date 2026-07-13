#Area2D 通过信号来发出区域碰撞
extends Node2D
@onready var area_2d: Area2D = $Area2D
#草死亡效
const GRASS_EFFECT = preload("res://scenes/world/ground_deco/effects/GrassDie.tscn")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#绑定区域进入
	area_2d.area_entered.connect(_on_area_2d_area_entered)
	return


## 有东西打击时，播放亡动画
func _on_area_2d_area_entered(_other: Area2D) -> void:
	# 特效添加当前场景
	var grass_effect = GRASS_EFFECT.instantiate()
	get_tree().current_scene.add_child(grass_effect)
	# 设置播放动画的位置是当前节点的全局位置
	grass_effect.global_position = global_position 
	
	#销毁草节点
	queue_free()
	return
	
