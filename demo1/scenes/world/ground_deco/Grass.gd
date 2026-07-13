#Area2D 通过信号来发出区域碰撞
extends Node2D
@onready var area_2d: Area2D = $Area2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#区域进入
	area_2d.area_entered.connect(_on_area_2d_area_entered)
	return


func _physics_process(_delta: float) -> void:
	return


## 有东西打击时，直接销毁他
func _on_area_2d_area_entered(_other: Area2D) -> void:
	#播放销毁动画
	queue_free()
