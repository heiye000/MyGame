# === godot-sprite-anim-pipeline / Step 1: 生成 AnimationPlayer 动画 ===
# 这不是可挂载脚本，而是给 execute_editor_script 用的代码片段。
# 用法：把下方 MANIFEST 用用户清单填好，整段作为 execute_editor_script 的 code 执行。
# 前置：目标场景已在编辑器打开，含 Sprite2D 与 AnimationPlayer 节点。
# 说明：build_animations 只关心切帧，方向 blend 坐标/状态机在 Step2 处理，故此处不需要 blend_positions。

var MANIFEST := {
	"sprite_node": "Sprite2D",
	"anim_player": "AnimationPlayer",
	"fps": 10.0,
	"mirror": {"left": "right"},
	"actions": [
		{"name": "idle", "loop": false, "frames": {"up": [6], "down": [18], "right": [0]}},
		{"name": "walk", "loop": true, "frames": {"up": [6, 7, 8, 9, 10, 11], "down": [18, 19, 20, 21, 22, 23], "right": [0, 1, 2, 3, 4, 5]}},
		{"name": "attack_L", "loop": false, "frames": {"up": [28, 29, 30, 31], "down": [36, 37, 38, 39], "left": [32, 33, 34, 35], "right": [24, 25, 26, 27]}},
	],
}

var root = EditorInterface.get_edited_scene_root()
if root == null:
	_custom_print("ERROR: 没有已打开的场景")
	return

var sprite_path = str(MANIFEST["sprite_node"])
var fps = float(MANIFEST["fps"])
var step = 1.0 / fps
var mirror = MANIFEST.get("mirror", {})

var lib = AnimationLibrary.new()

# RESET 动画：把精灵复位到第 0 帧
var reset = Animation.new()
reset.length = 0.001
var rt = reset.add_track(Animation.TYPE_VALUE)
reset.track_set_path(rt, sprite_path + ":frame")
reset.value_track_set_update_mode(rt, Animation.UPDATE_DISCRETE)
reset.track_insert_key(rt, 0.0, 0)
lib.add_animation(&"RESET", reset)

var total = 1
for action in MANIFEST["actions"]:
	var frames_map = action["frames"]
	var loop = bool(action.get("loop", false))

	# 本动作靠 mirror 派生的方向，及其被引用的源方向
	var derived = []
	var sources_used = []
	for md in mirror.keys():
		if not frames_map.has(md):
			derived.append(md)
			sources_used.append(mirror[md])

	# 需要生成的方向 = 显式帧方向 + 派生方向
	var dirs = []
	for d in frames_map.keys():
		dirs.append(d)
	for d in derived:
		if not dirs.has(d):
			dirs.append(d)

	for dir in dirs:
		var src_dir = dir
		var flip = false
		if not frames_map.has(dir):
			src_dir = mirror[dir]
			flip = true
		var frames = frames_map[src_dir]

		var anim = Animation.new()
		anim.length = max(frames.size() * step, 0.001)
		anim.step = step
		anim.loop_mode = Animation.LOOP_LINEAR if loop else Animation.LOOP_NONE

		var t = anim.add_track(Animation.TYPE_VALUE)
		anim.track_set_path(t, sprite_path + ":frame")
		anim.value_track_set_update_mode(t, Animation.UPDATE_DISCRETE)
		for i in frames.size():
			anim.track_insert_key(t, i * step, frames[i])

		# 仅当本方向是派生方向，或被本动作某派生方向引用为源时，才写 flip_h 轨
		if flip or sources_used.has(dir):
			var ft = anim.add_track(Animation.TYPE_VALUE)
			anim.track_set_path(ft, sprite_path + ":flip_h")
			anim.value_track_set_update_mode(ft, Animation.UPDATE_DISCRETE)
			anim.track_insert_key(ft, 0.0, flip)

		lib.add_animation(StringName(str(action["name"]) + "_" + str(dir)), anim)
		total += 1

var ap = root.get_node(str(MANIFEST["anim_player"]))
if ap.has_animation_library(""):
	ap.remove_animation_library("")
ap.add_animation_library("", lib)

EditorInterface.save_scene()
_custom_print("OK 动画数=" + str(total))
