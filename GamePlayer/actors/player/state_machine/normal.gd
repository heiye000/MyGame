## 探索模式：只处理八方向移动，动画只写 Normal 子图。
class_name PlayerNormal
extends LimboState

## 本态拔剑时派发的事件名，用来切到战斗。
const EVENT_DRAW_SWORD: StringName = &"draw_sword"
## 顶层动画状态机回放（Normal / Battle）。
const _TOP_PLAYBACK := "parameters/StateMachine/playback"
## 探索态自己的朝向参数，不碰战斗子图。
const _BLEND_IDLE := "parameters/StateMachine/Normal/idle/blend_position"
const _BLEND_RUN_START := "parameters/StateMachine/Normal/run_start/blend_position"
const _BLEND_RUN := "parameters/StateMachine/Normal/run/blend_position"


## 初始化时登记「探索 → 战斗」，输入监听仍等进态再绑。
func _setup() -> void:
	var hsm := get_parent() as LimboHSM
	var battle_state := hsm.get_node("Battle") as LimboState
	hsm.add_transition(self, battle_state, EVENT_DRAW_SWORD)


## 切进来时把动画树拉到 Normal 子图，并按当前朝向改探索移动动画。
func _enter() -> void:
	var player := agent as Player
	if player == null:
		return
	var top: AnimationNodeStateMachinePlayback = player.animation_tree.get(_TOP_PLAYBACK)
	if top and top.get_current_node() != &"Normal":
		top.travel(&"Normal")
	player.input_buffer.clear(PlayerActionType.Type.ATTACK_L)
	player.input_buffer.clear(PlayerActionType.Type.ROLL)
	_set_move_blend(player, player.last_direction)
	_bind_draw_sword()


## 离态时解开拔剑监听，避免战斗态再收到探索这边的回调。
func _exit() -> void:
	_unbind_draw_sword()


func _update(_delta: float) -> void:
	var player := agent as Player
	# 探索里按到攻击/翻滚也不留预输入，避免拔剑后立刻出招。
	player.input_buffer.clear(PlayerActionType.Type.ATTACK_L)
	player.input_buffer.clear(PlayerActionType.Type.ROLL)

	var move_direction := player.animation_tree.get_move_direction()
	if move_direction != Vector2.ZERO:
		player.last_direction = move_direction

	_set_move_blend(player, player.last_direction)
	player.velocity = move_direction * player.move_speed
	player.move_and_slide()


## 探索态按下拔剑，切到战斗。
func _on_draw_sword() -> void:
	dispatch(EVENT_DRAW_SWORD)


## 只在本态活跃时听拔剑。
func _bind_draw_sword() -> void:
	var action := PlayerActionType.get_action(PlayerActionType.Type.DRAW_SWORD)
	if action == null:
		push_error("PlayerNormal: 未找到 DRAW_SWORD 的 GUIDE 行动资源。")
		return
	if not action.just_triggered.is_connected(_on_draw_sword):
		action.just_triggered.connect(_on_draw_sword)


## 离态后不再听拔剑。
func _unbind_draw_sword() -> void:
	var action := PlayerActionType.get_action(PlayerActionType.Type.DRAW_SWORD)
	if action and action.just_triggered.is_connected(_on_draw_sword):
		action.just_triggered.disconnect(_on_draw_sword)


## 探索态移动 BlendSpace：完整八向。
func _move_blend_from_direction(direction: Vector2) -> Vector2:
	var d8: Direction8.Dir = Direction8.from_vector(direction, Direction8.Dir.LEFT)
	return Direction8.to_blend_position(d8)


## 只写 Normal 子图的 idle / 起步 / 跑步朝向。
func _set_move_blend(player: Player, direction: Vector2) -> void:
	var d := _move_blend_from_direction(direction)
	player.animation_tree.set(_BLEND_IDLE, d)
	player.animation_tree.set(_BLEND_RUN_START, d)
	player.animation_tree.set(_BLEND_RUN, d)
