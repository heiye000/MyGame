extends Node2D
## 可破坏静物：受击 Area2D 被其他 Area 进入后，播销毁特效并移除自身。

@onready var area_2d: Area2D = $Area2D

## 销毁时生成的特效场景；为空则只销毁本体。
@export var die_effect: PackedScene


func _ready() -> void:
	# 绑定受击区域进入信号（Signal）。
	area_2d.area_entered.connect(_on_area_2d_area_entered)


## 攻击判定进入受击区时，播放销毁特效并移除本节点。
func _on_area_2d_area_entered(_other: Area2D) -> void:
	if die_effect:
		var fx := die_effect.instantiate()
		get_tree().current_scene.add_child(fx)
		fx.global_position = global_position
	queue_free()
