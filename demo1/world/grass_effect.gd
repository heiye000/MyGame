extends Node2D
@onready var area_2d: Area2D = $Area2D

const GRASS_DEATH_EFFECT := preload("res://world/GlassEffect.tscn")

var _triggered := false


func _ready() -> void:
	area_2d.area_entered.connect(_on_area_2d_area_entered)


func _on_area_2d_area_entered(_area: Area2D) -> void:
	if _triggered:
		return
	_triggered = true
	call_deferred("_spawn_death_effect")


func _spawn_death_effect() -> void:
	var effect := GRASS_DEATH_EFFECT.instantiate()
	effect.global_position = global_position
	get_tree().current_scene.add_child(effect)
	queue_free()
