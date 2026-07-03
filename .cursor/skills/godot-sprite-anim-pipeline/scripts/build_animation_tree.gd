# === godot-sprite-anim-pipeline / Step 2: 生成 AnimationTree 状态机 ===
# 这不是可挂载脚本，而是给 execute_editor_script 用的代码片段。
# 用法：把下方 CFG 用用户清单填好，整段作为 execute_editor_script 的 code 执行。
# 前置：Step1 已生成动画；场景含 AnimationTree 与 AnimationPlayer 节点（均为根直属子节点）。
# 拓扑固定：BlendTree -> StateMachine -> { MoveMachine{idle,run}, AttackMachine{attack_L} }。
# 扩展（8 方向 / 多攻击态）见 reference.md。

var CFG := {
	"anim_player": "AnimationPlayer",
	"anim_tree": "AnimationTree",
	"directions": ["up", "down", "left", "right"],
	"direction_blend_positions": {
		"up": Vector2(0, 1), "down": Vector2(0, -1),
		"left": Vector2(-0.8, 0), "right": Vector2(0.8, 0),
	},
	"run_blend_positions": {
		"up": Vector2(0, 0.8), "down": Vector2(0, -0.8),
		"left": Vector2(-1, 0), "right": Vector2(1, 0),
	},
	# MoveMachine 的两个 BlendSpace 状态: 状态名 -> 动画前缀
	"move_states": {"idle": "idle", "run": "walk"},
	# AttackMachine 的状态: 状态名 -> 动画前缀
	"attack_states": {"attack_L": "attack_L"},
	"expr_idle_to_run": "current_move_direction.length() > 0.0",
	"expr_run_to_idle": "current_move_direction.length() == 0.0",
	"expr_move_to_attack": "is_attacking() == true",
}

var root = EditorInterface.get_edited_scene_root()
if root == null:
	_custom_print("ERROR: 没有已打开的场景")
	return

var dirs = CFG["directions"]
var move_pos = CFG["direction_blend_positions"]
var run_pos = CFG.get("run_blend_positions", move_pos)
var AUTO = AnimationNodeStateMachineTransition.ADVANCE_MODE_AUTO
var AT_END = AnimationNodeStateMachineTransition.SWITCH_MODE_AT_END
var DISCRETE = AnimationNodeBlendSpace2D.BLEND_MODE_DISCRETE

# ---- MoveMachine ----
var move_sm = AnimationNodeStateMachine.new()
var move_node_pos = {"idle": Vector2(465, 46), "run": Vector2(444, 238)}
for state_name in CFG["move_states"]:
	var prefix = str(CFG["move_states"][state_name])
	var positions = run_pos if state_name == "run" else move_pos
	var bs = AnimationNodeBlendSpace2D.new()
	bs.blend_mode = DISCRETE
	for d in dirs:
		var a = AnimationNodeAnimation.new()
		a.animation = StringName(prefix + "_" + str(d))
		bs.add_blend_point(a, positions[d])
	move_sm.add_node(state_name, bs, move_node_pos.get(state_name, Vector2(450, 100)))

var tr_s_idle = AnimationNodeStateMachineTransition.new()
tr_s_idle.advance_mode = AUTO
move_sm.add_transition("Start", "idle", tr_s_idle)

var tr_i2r = AnimationNodeStateMachineTransition.new()
tr_i2r.advance_mode = AUTO
tr_i2r.advance_expression = str(CFG["expr_idle_to_run"])
move_sm.add_transition("idle", "run", tr_i2r)

var tr_r2i = AnimationNodeStateMachineTransition.new()
tr_r2i.advance_mode = AUTO
tr_r2i.advance_expression = str(CFG["expr_run_to_idle"])
move_sm.add_transition("run", "idle", tr_r2i)

# ---- AttackMachine ----
var attack_sm = AnimationNodeStateMachine.new()
var first_attack = ""
for state_name in CFG["attack_states"]:
	if first_attack == "":
		first_attack = state_name
	var prefix = str(CFG["attack_states"][state_name])
	var bs = AnimationNodeBlendSpace2D.new()
	bs.blend_mode = DISCRETE
	for d in dirs:
		var a = AnimationNodeAnimation.new()
		a.animation = StringName(prefix + "_" + str(d))
		bs.add_blend_point(a, move_pos[d])
	attack_sm.add_node(state_name, bs, Vector2(509, 100))

var tr_s_atk = AnimationNodeStateMachineTransition.new()
tr_s_atk.advance_mode = AUTO
attack_sm.add_transition("Start", first_attack, tr_s_atk)

var tr_atk_end = AnimationNodeStateMachineTransition.new()
tr_atk_end.advance_mode = AUTO
tr_atk_end.switch_mode = AT_END
attack_sm.add_transition(first_attack, "End", tr_atk_end)

# ---- 顶层 StateMachine ----
var top = AnimationNodeStateMachine.new()
top.add_node("MoveMachine", move_sm, Vector2(438, 89))
top.add_node("AttackMachine", attack_sm, Vector2(438, 186))

var tr_s_move = AnimationNodeStateMachineTransition.new()
tr_s_move.advance_mode = AUTO
top.add_transition("Start", "MoveMachine", tr_s_move)

var tr_m2a = AnimationNodeStateMachineTransition.new()
tr_m2a.advance_mode = AUTO
tr_m2a.advance_expression = str(CFG["expr_move_to_attack"])
top.add_transition("MoveMachine", "AttackMachine", tr_m2a)

var tr_a2m = AnimationNodeStateMachineTransition.new()
tr_a2m.advance_mode = AUTO
tr_a2m.switch_mode = AT_END
top.add_transition("AttackMachine", "MoveMachine", tr_a2m)

# ---- BlendTree 根 ----
var bt = AnimationNodeBlendTree.new()
bt.add_node("StateMachine", top, Vector2(340, 180))
bt.connect_node("output", 0, "StateMachine")

# ---- 挂到 AnimationTree ----
var tree = root.get_node(str(CFG["anim_tree"]))
tree.anim_player = NodePath("../" + str(CFG["anim_player"]))
tree.advance_expression_base_node = NodePath("..")
tree.tree_root = bt
tree.active = true

# ---- 初始化 blend_position 参数 ----
for state_name in CFG["move_states"]:
	tree.set("parameters/StateMachine/MoveMachine/" + state_name + "/blend_position", Vector2.ZERO)
for state_name in CFG["attack_states"]:
	tree.set("parameters/StateMachine/AttackMachine/" + state_name + "/blend_position", Vector2.ZERO)

EditorInterface.save_scene()
_custom_print("OK tree built: MoveMachine(" + str(CFG["move_states"].size()) + ") AttackMachine(" + str(CFG["attack_states"].size()) + ")")
