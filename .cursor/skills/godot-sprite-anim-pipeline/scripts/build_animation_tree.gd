# === godot-sprite-anim-pipeline / Step 2: 生成 AnimationTree 状态机 ===
# 这不是可挂载脚本，而是给 execute_editor_script 用的代码片段。
# 用法：把下方 CFG 用用户清单填好，整段作为 execute_editor_script 的 code 执行。
# 前置：Step1 已生成动画；场景含 AnimationTree 与 AnimationPlayer（均为 Player 根直属）。
# 拓扑：BlendTree -> StateMachine -> CFG.machines（Move + 若干 oneshot）。
# 表达式基准：AnimationTree 自身（PlayerAnimationTree），不是 Player。
# 注意：本片段必须是线性语句，不可定义 func（execute_editor_script 限制）。

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
	"machines": {
		"MoveMachine": {
			"kind": "move",
			"states": {"idle": "player_idle", "run": "player_run"},
		},
		"AttackMachine": {
			"kind": "oneshot",
			"states": {"attack_L": "player_attack"},
			"from_move_expr": "is_attacking() == true",
		},
		"RollMachine": {
			"kind": "oneshot",
			"states": {"roll": "player_roll"},
			"from_move_expr": "is_rolling() == true",
		},
	},
	"expr_idle_to_run": "get_move_direction().length() > 0.0",
	"expr_run_to_idle": "get_move_direction().length() == 0.0",
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
var machines: Dictionary = CFG["machines"]
var built: Dictionary = {}
var move_machine_name := "MoveMachine"

for machine_name in machines:
	var mcfg: Dictionary = machines[machine_name]
	var kind = str(mcfg.get("kind", "oneshot"))
	var states: Dictionary = mcfg["states"]
	var sm = AnimationNodeStateMachine.new()

	if kind == "move":
		move_machine_name = machine_name
		var node_pos = {"idle": Vector2(465, 46), "run": Vector2(444, 238)}
		for state_name in states:
			var prefix = str(states[state_name])
			var positions = run_pos if state_name == "run" else move_pos
			var bs = AnimationNodeBlendSpace2D.new()
			bs.blend_mode = DISCRETE
			for d in dirs:
				var a = AnimationNodeAnimation.new()
				a.animation = StringName(prefix + "_" + str(d))
				bs.add_blend_point(a, positions[d])
			sm.add_node(state_name, bs, node_pos.get(state_name, Vector2(450, 100)))
		var tr_s_idle = AnimationNodeStateMachineTransition.new()
		tr_s_idle.advance_mode = AUTO
		sm.add_transition("Start", "idle", tr_s_idle)
		var tr_i2r = AnimationNodeStateMachineTransition.new()
		tr_i2r.advance_mode = AUTO
		tr_i2r.advance_expression = str(CFG["expr_idle_to_run"])
		sm.add_transition("idle", "run", tr_i2r)
		var tr_r2i = AnimationNodeStateMachineTransition.new()
		tr_r2i.advance_mode = AUTO
		tr_r2i.advance_expression = str(CFG["expr_run_to_idle"])
		sm.add_transition("run", "idle", tr_r2i)
	else:
		var first_state := ""
		var y := 100.0
		for state_name in states:
			if first_state == "":
				first_state = state_name
			var prefix = str(states[state_name])
			var bs = AnimationNodeBlendSpace2D.new()
			bs.blend_mode = DISCRETE
			for d in dirs:
				var a = AnimationNodeAnimation.new()
				a.animation = StringName(prefix + "_" + str(d))
				bs.add_blend_point(a, move_pos[d])
			sm.add_node(state_name, bs, Vector2(509, y))
			y += 100.0
		var tr_s_one = AnimationNodeStateMachineTransition.new()
		tr_s_one.advance_mode = AUTO
		sm.add_transition("Start", first_state, tr_s_one)
		var tr_end = AnimationNodeStateMachineTransition.new()
		tr_end.advance_mode = AUTO
		tr_end.switch_mode = AT_END
		sm.add_transition(first_state, "End", tr_end)

	built[machine_name] = sm

# ---- 顶层 StateMachine ----
var top = AnimationNodeStateMachine.new()
var layout = {
	"MoveMachine": Vector2(438, 89),
	"AttackMachine": Vector2(705, 210),
	"RollMachine": Vector2(286, 284),
}
var layout_i := 0
for machine_name in built:
	var pos = layout.get(machine_name, Vector2(400.0 + layout_i * 40.0, 120.0 + layout_i * 80.0))
	top.add_node(machine_name, built[machine_name], pos)
	layout_i += 1

var tr_s_move = AnimationNodeStateMachineTransition.new()
tr_s_move.advance_mode = AUTO
top.add_transition("Start", move_machine_name, tr_s_move)

for machine_name in built:
	if machine_name == move_machine_name:
		continue
	var mcfg2: Dictionary = machines[machine_name]
	var expr = str(mcfg2.get("from_move_expr", ""))
	if expr == "":
		_custom_print("WARN: " + machine_name + " 缺少 from_move_expr，跳过顶层过渡")
		continue
	var tr_in = AnimationNodeStateMachineTransition.new()
	tr_in.advance_mode = AUTO
	tr_in.advance_expression = expr
	top.add_transition(move_machine_name, machine_name, tr_in)
	var tr_back = AnimationNodeStateMachineTransition.new()
	tr_back.advance_mode = AUTO
	tr_back.switch_mode = AT_END
	top.add_transition(machine_name, move_machine_name, tr_back)

# ---- BlendTree 根 ----
var bt = AnimationNodeBlendTree.new()
bt.add_node("StateMachine", top, Vector2(340, 180))
bt.connect_node("output", 0, "StateMachine")

# ---- 挂到 AnimationTree ----
var tree = root.get_node(str(CFG["anim_tree"]))
tree.anim_player = NodePath("../" + str(CFG["anim_player"]))
# 表达式在 AnimationTree（PlayerAnimationTree）上求值
tree.advance_expression_base_node = NodePath(".")
tree.tree_root = bt
tree.active = true

# ---- 初始化 blend_position 参数 ----
for machine_name in machines:
	var mcfg3: Dictionary = machines[machine_name]
	var states3: Dictionary = mcfg3["states"]
	for state_name in states3:
		tree.set("parameters/StateMachine/" + machine_name + "/" + state_name + "/blend_position", Vector2.ZERO)

EditorInterface.save_scene()
var summary: PackedStringArray = PackedStringArray()
for machine_name in machines:
	summary.append(machine_name + "(" + str(machines[machine_name]["states"].size()) + ")")
_custom_print("OK tree built: " + ", ".join(summary))
