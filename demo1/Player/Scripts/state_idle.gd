## 待机状态：无输入时保持静止并播放 idle 动画。
class_name StateIdle extends State

var _walk_state: State


func _ready() -> void:
	_walk_state = get_parent().get_node("Walk")


func Enter() -> void:
	player.velocity = Vector2.ZERO
	player.update_animation(Vector2.ZERO)


func PhysicsProcess(_delta: float) -> State:
	#获取移动方向
	var direction: Vector2 = player.get_move_direction()
	#如果移动方向不为空，则切换到行走状态
	if direction != Vector2.ZERO:
		return _walk_state

	#如果移动方向为空，则保持静止
	player.velocity = Vector2.ZERO
	player.move_and_slide()
	player.update_animation(Vector2.ZERO)
	return null
