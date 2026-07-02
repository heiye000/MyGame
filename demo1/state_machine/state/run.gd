# extends LimboState


# # Called when the node enters the scene tree for the first time.
# func _ready() -> void:
# 	pass # Replace with function body.


# #进入状态
# func Enter() -> void:
# 	return

# #退出状态
# func Exit() -> void:
# 	return

# #更新状态
# func _update(_delta: float) -> void:
# 	# 获取当前玩家的移动方向
# 	var direction: Vector2 = agent.get_move_direction()
# 	if direction == Vector2.ZERO:
# 		#发出切换到待机状态事件
# 		get_parent().dispatch("run_to_idle")
# 		return

# 	#设置移动方向
# 	direction = direction.normalized()
# 	#设置移动速度
# 	agent.velocity = direction * agent.move_speed
# 	#移动
# 	agent.move_and_slide()
# 	#更新动画
# 	agent.update_animation(direction)
# 	#更新停止移动后仍保持的朝向
# 	agent.last_direction = direction
# 	return
