## 行走状态：读取四方向输入移动，并播放 walk 动画。
class_name StateWalk extends State

var _idle_state: State



func _ready() -> void:
	_idle_state = get_parent().get_node("Idle")


func PhysicsProcess(_delta: float) -> State:
	var direction: Vector2 = player.get_move_direction()
	if direction == Vector2.ZERO:
		return _idle_state

	direction = direction.normalized()
	player.last_direction = direction
	player.velocity = direction * player.move_speed
	player.move_and_slide()
	player.update_animation(direction)
	
	return null
