## Engine adapter: keeps the clock, passes keys to the Session, and draws what it holds.
## It never decides rules: those live in core/session.gd.
extends Node3D

const GRID := Vector2i(48, 48)  # your call: bigger grids make the dragon feel finer
const TICK_SECONDS := 0.1
const FONT_PATH := "res://assets/PressStart2P-Regular.ttf"  # pixel font, SIL OFL
const WAVE := "[wave amp=40.0 freq=4.0 connected=2]%s[/wave]"  # every word in the game waves
const CAMERA_OFFSET := Vector3(0, 11, 7.5)  # above and behind the head
const DIRECTIONS := {
	"ui_up": Vector2i.UP,
	"ui_down": Vector2i.DOWN,
	"ui_left": Vector2i.LEFT,
	"ui_right": Vector2i.RIGHT,
}

var session := Session.new(GRID)
var meshes := {}  # kit piece name -> Mesh, shared by everything that shows it (Flyweight)
var segments: Array[MeshInstance3D] = []
var camera := Camera3D.new()
var food_node := MeshInstance3D.new()
var score_label := RichTextLabel.new()
var message_label := RichTextLabel.new()  # BBCode, so words can wave
var font: Font
var zzz := Label3D.new()
var _clock := 0.0


func _ready() -> void:
	meshes = Stage.load_kit()
	font = load(FONT_PATH)
	_build_stage()
	_build_hud()
	_draw_dragon()
	_draw_food()
	_draw_status()


## Input arrives as events, so even a tap shorter than one frame is never missed.
func _unhandled_input(event: InputEvent) -> void:
	# Enter wakes a dormant dragon: a fresh scene means a fresh Session.
	if session.state == Session.State.DORMANT and event.is_action_pressed("ui_accept"):
		get_tree().reload_current_scene()
		return
	for action in DIRECTIONS:
		if event.is_action_pressed(action):
			session.steer(DIRECTIONS[action])


func _process(delta: float) -> void:
	_clock += delta
	while _clock >= TICK_SECONDS:
		_clock -= TICK_SECONDS
		session.tick()
		_draw_dragon()
		_draw_food()
	_draw_status()
	_follow(delta)


## Sky, light, and tiles live in app/stage.gd; the camera follows the head.
func _build_stage() -> void:
	add_child(Stage.new(session.board.tiles, meshes))
	add_child(camera)
	food_node.mesh = meshes["food"]
	add_child(food_node)
	camera.position = _center(session.dragon.body[0]) + CAMERA_OFFSET


## Ease toward the head each frame, so the camera glides while the dragon steps.
func _follow(delta: float) -> void:
	var target := _center(session.dragon.body[0]) + CAMERA_OFFSET
	camera.position = camera.position.lerp(target, 1 - exp(-3 * delta))
	camera.look_at(camera.position - CAMERA_OFFSET)


## The score sits in a corner of the screen, on a layer above the 3D world.
func _build_hud() -> void:
	var layer := CanvasLayer.new()
	_style_label(score_label, 24)
	score_label.position = Vector2(16, 12)
	score_label.custom_minimum_size.x = 500  # a fit_content label needs a width to wrap in
	layer.add_child(score_label)
	_style_label(message_label, 20)
	message_label.set_anchors_preset(Control.PRESET_TOP_WIDE)  # a strip across the top
	message_label.offset_top = 90  # below the score, clear of the sleeping dragon
	layer.add_child(message_label)
	add_child(layer)
	zzz.text = "Z z z"
	zzz.font = font
	zzz.font_size = 96
	zzz.pixel_size = 0.01
	zzz.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(zzz)


## One look for all text: the pixel font, BBCode on, and as tall as its text.
func _style_label(label: RichTextLabel, font_size: int) -> void:
	label.bbcode_enabled = true
	label.fit_content = true
	label.scroll_active = false
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("normal_font", font)
	label.add_theme_font_size_override("normal_font_size", font_size)


## Setting text re-parses it, and the draw functions run often, so only on a change.
func _set_text(label: RichTextLabel, text: String) -> void:
	if label.text != text:
		label.text = text


func _draw_food() -> void:
	food_node.visible = session.food != Session.NO_FOOD
	food_node.position = _center(session.food)
	_set_text(score_label, WAVE % ("Eaten: %d" % session.score))


## What the player should read right now: how to start, or why the dragon is asleep.
func _draw_status() -> void:
	var dormant := session.state == Session.State.DORMANT
	zzz.visible = dormant
	zzz.position = _center(session.dragon.body[0]) + Vector3(0, 1.4, 0)
	var message := ""
	match session.state:
		Session.State.WAITING:
			message = "[center]%s[/center]" % (WAVE % "Press an arrow key to start")
		Session.State.DORMANT:
			var lines := PackedStringArray(
				[
					"Dormant",
					"The dragon sleeps to save its energy.",
					"Glowberries eaten: %d" % session.score,
					"Press Enter to wake up",
				]
			)
			message = "[center]%s[/center]" % (WAVE % "\n".join(lines))
	_set_text(message_label, message)


func _draw_dragon() -> void:
	var body := session.dragon.body
	while segments.size() < body.size():
		var segment := MeshInstance3D.new()
		add_child(segment)
		segments.append(segment)
	var placed := Kit.layout(body)
	for i in segments.size():
		var segment := segments[i]
		segment.visible = i < body.size()
		if not segment.visible:
			continue
		var cell := body[i]
		segment.mesh = meshes[Kit.Piece.keys()[placed[i][0]].to_lower()]
		segment.position = _center(cell)
		segment.scale.y = 0.5 if session.state == Session.State.DORMANT else 1.0  # sagging
		segment.rotation.y = placed[i][1] * PI / 2


func _center(cell: Vector2i) -> Vector3:
	return Vector3(cell.x + 0.5, 0, cell.y + 0.5)
