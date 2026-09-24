# === godot-slash-swing / 把描边 JSON 写成刀光场景 ===
# 不是可挂载脚本。填好 CFG 后，整段交给 execute_editor_script。
# 先写好 extends SlashSwing 的子类脚本，再跑本段。
# polygons_json 用 trace_slash_polygons.py 的 --out，不要放进 assets。

var CFG := {
	"mode": "create", # create | update
	"scene_path": "res://core/components/combat/attack/attack_left_1.tscn",
	"script_path": "res://core/components/combat/attack/attack_left_1.gd",
	"texture_path": "res://assets/sprites/effects/attach_left.png",
	"polygons_json": "",
	"fps": 8.0,
	"root_name": "AttackLeft1",
	"can_be_blocked": true,
	"can_be_perfect_parried": true,
	"swing_sound": "res://assets/audio/swipe.wav",
	# 先问用户。shared = 有效帧共用第一张有效多边形；per_frame = 每帧各用各的。
	"polygon_mode": "",
}

var DRAW_ORDER: Array[String] = ["left", "down_left", "down", "up", "up_left"]

var json_path := str(CFG["polygons_json"])
if json_path == "":
	_custom_print("ERROR: polygons_json 为空")
	return
var parsed = JSON.parse_string(FileAccess.get_file_as_string(json_path))
if typeof(parsed) != TYPE_DICTIONARY or not bool(parsed.get("ok", false)):
	_custom_print("ERROR: 描边 JSON 未通过自检")
	return

var polygon_mode := str(CFG["polygon_mode"])
if polygon_mode != "shared" and polygon_mode != "per_frame":
	_custom_print("ERROR: polygon_mode 必须是 shared 或 per_frame，先问用户")
	return

var fps := float(CFG["fps"])
var step := 1.0 / fps
var dirs: Dictionary = parsed["directions"]
for dir_name in DRAW_ORDER:
	if not dirs.has(dir_name):
		_custom_print("ERROR: JSON 缺少朝向 " + dir_name)
		return

var mode := str(CFG["mode"])
var scene_path := str(CFG["scene_path"])
var root: Node2D
if mode == "update":
	EditorInterface.open_scene_from_path(scene_path)
	root = EditorInterface.get_edited_scene_root() as Node2D
	if root == null:
		_custom_print("ERROR: 打不开场景 " + scene_path)
		return
elif mode == "create":
	root = Node2D.new()
	root.name = str(CFG["root_name"])
else:
	_custom_print("ERROR: mode 只能是 create 或 update")
	return

root.scale = Vector2.ONE
root.set_script(load(str(CFG["script_path"])))

var body := root.get_node_or_null("Body") as Node2D
if body == null:
	body = Node2D.new()
	body.name = "Body"
	root.add_child(body)
body.scale = Vector2.ONE

var sprite := body.get_node_or_null("Sprite2D") as Sprite2D
if sprite == null:
	sprite = Sprite2D.new()
	sprite.name = "Sprite2D"
	body.add_child(sprite)
sprite.centered = true
sprite.texture = load(str(CFG["texture_path"]))
sprite.hframes = int(parsed["hframes"])
sprite.vframes = int(parsed["vframes"])
sprite.frame = 0

var hitbox := body.get_node_or_null("Hitbox") as Hitbox
if hitbox == null:
	hitbox = Hitbox.new()
	hitbox.name = "Hitbox"
	body.add_child(hitbox)
hitbox.collision_layer = 16
hitbox.collision_mask = 8
hitbox.monitoring = false
hitbox.monitorable = false
hitbox.can_be_blocked = bool(CFG["can_be_blocked"])
hitbox.can_be_perfect_parried = bool(CFG["can_be_perfect_parried"])
var sound_path := str(CFG["swing_sound"])
hitbox.swing_sound = load(sound_path) if sound_path != "" else null

var poly_node := hitbox.get_node_or_null("CollisionPolygon2D") as CollisionPolygon2D
if poly_node == null:
	poly_node = CollisionPolygon2D.new()
	poly_node.name = "CollisionPolygon2D"
	hitbox.add_child(poly_node)
# 静止时不带伤害形。判定只写在动画键上。
poly_node.polygon = PackedVector2Array()

var player := root.get_node_or_null("AnimationPlayer") as AnimationPlayer
if player == null:
	player = AnimationPlayer.new()
	player.name = "AnimationPlayer"
	root.add_child(player)
for lib_name in player.get_animation_library_list():
	player.remove_animation_library(lib_name)

var lib := AnimationLibrary.new()
var reset := Animation.new()
reset.length = 0.001
reset.step = step
var reset_track := reset.add_track(Animation.TYPE_VALUE)
reset.track_set_path(reset_track, NodePath("Body/Sprite2D:frame"))
reset.value_track_set_update_mode(reset_track, Animation.UPDATE_DISCRETE)
reset.track_insert_key(reset_track, 0.0, 0)
lib.add_animation(&"RESET", reset)

var build_failed := false
for dir_name in DRAW_ORDER:
	if build_failed:
		break
	var spec: Dictionary = dirs[dir_name]
	var frames: Array = spec["frames"]
	var polygons: Array = spec["polygons"]
	if frames.size() != polygons.size() or frames.size() < 2:
		_custom_print("ERROR: " + dir_name + " 的帧和多边形数量对不上")
		build_failed = true
		break
	var use_polygons: Array = polygons
	if polygon_mode == "shared":
		var shared_poly: Array = []
		for j in polygons.size() - 1:
			if (polygons[j] as Array).size() >= 3:
				shared_poly = polygons[j]
				break
		if shared_poly.is_empty():
			_custom_print("ERROR: " + dir_name + " 没有可共用的多边形")
			build_failed = true
			break
		use_polygons = []
		for j in polygons.size():
			if j == polygons.size() - 1:
				use_polygons.append([])
			else:
				use_polygons.append(shared_poly)
	var anim := Animation.new()
	anim.length = frames.size() * step
	anim.step = step
	anim.loop_mode = Animation.LOOP_NONE
	var frame_track := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(frame_track, NodePath("Body/Sprite2D:frame"))
	anim.value_track_set_update_mode(frame_track, Animation.UPDATE_DISCRETE)
	var poly_track := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(poly_track, NodePath("Body/Hitbox/CollisionPolygon2D:polygon"))
	anim.value_track_set_update_mode(poly_track, Animation.UPDATE_DISCRETE)
	for i in frames.size():
		var t := i * step
		anim.track_insert_key(frame_track, t, int(frames[i]))
		var pts := PackedVector2Array()
		for p in use_polygons[i]:
			pts.append(Vector2(float(p[0]), float(p[1])))
		anim.track_insert_key(poly_track, t, pts)
		if i == frames.size() - 1 and pts.size() != 0:
			_custom_print("ERROR: " + dir_name + " 末帧多边形不是空的")
			build_failed = true
			break
		if i < frames.size() - 1 and pts.size() < 3:
			_custom_print("ERROR: " + dir_name + " 有效帧多边形少于 3 点")
			build_failed = true
			break
	if not build_failed:
		lib.add_animation(StringName(dir_name), anim)

if build_failed:
	if mode == "create":
		root.free()
	return

player.add_animation_library(&"", lib)

if mode == "create":
	for child in root.find_children("*", "", true, false):
		child.owner = root
	var packed := PackedScene.new()
	var pack_err := packed.pack(root)
	if pack_err != OK:
		_custom_print("ERROR: pack 失败 " + str(pack_err))
		root.free()
		return
	var save_err := ResourceSaver.save(packed, scene_path)
	if save_err != OK:
		_custom_print("ERROR: 保存失败 " + str(save_err))
		root.free()
		return
	root.free()
else:
	EditorInterface.save_scene()

_custom_print("OK scene=" + scene_path + " anims=RESET," + ",".join(DRAW_ORDER))
