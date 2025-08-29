extends CharacterBody2D

@export var speed : float = 100

var input_vector
var playback : AnimationNodeStateMachinePlayback

func _ready() -> void:
	playback = $AnimationTree["parameters/playback"]

func _physics_process(delta: float) -> void:
	input_vector = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = input_vector * speed
	move_and_slide()
	select_animation()
	update_animation_params()

func select_animation():
	if velocity == Vector2.ZERO:
		playback.travel("Idle")
	else:
		playback.travel("Walk")

func update_animation_params():
	if input_vector == Vector2.ZERO:
		return
	$AnimationTree["parameters/Idle/blend_position"] = input_vector
	$AnimationTree["parameters/Walk/blend_position"] = input_vector
