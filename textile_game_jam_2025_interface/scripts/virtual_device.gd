extends CanvasLayer

@export var creature = null
@export var player = null
signal captured
signal add_creature
var bulbs : int = 0 # Index of highest bulb that should be lit
var catchable : bool = false
var catch_timer = null

func _process(delta: float) -> void:
	if creature and player:
		var distance = player.global_position.distance_to(creature.global_position)
		var new_bulbs = 10 - min(int(distance/150), 10)
		if new_bulbs != bulbs:
			bulbs = new_bulbs
			for bulb in $Bulbs.get_children(): # Color bulbs white
				bulb.modulate = Color(1.0, 1.0, 1.0)
			for i in range(new_bulbs): # Color bulbs red
				$Bulbs.get_child(i).modulate = Color(1.0, 0.0, 0.0)
			if new_bulbs == 10:
				catchable = true
				$CatchTimer.start(1.5)
				# Animate all bulbs flashing
				for bulb in $Bulbs.get_children(): # Color bulbs green
					bulb.modulate = Color(0.0, 1.0, 0.0)
				$AnimationPlayer.play("flash")

func _on_respawn_button_pressed() -> void:
	# Check if RespawnCooldownBar is full
	if $RespawnCooldownBar.try_respawn():
		$CatchTimer.stop()
		$AnimationPlayer.play("RESET")
		bulbs = 0
		if creature:
			creature.queue_free()
			add_creature.emit()

# Player caught the creature in time
func _on_catch_button_pressed() -> void:
	if catchable:
		$CatchTimer.stop()
		catchable = false
		captured.emit()
		$AnimationPlayer.play("RESET")
		bulbs = 0
		if creature:
			creature.queue_free()
			add_creature.emit()

# Player didn't catch the creature in time
func _on_catch_timer_timeout() -> void:
	catchable = false
	$AnimationPlayer.play("RESET")
	bulbs = 0
	if creature:
		creature.queue_free()
		add_creature.emit()

# Toggle tutorial
func _on_info_button_pressed() -> void:
	$Tutorial.visible = !$Tutorial.visible

# Hide tutorial
func _unhandled_input(e):
	if e is InputEventMouseButton and e.is_released():
		if $Tutorial.visible:
			$Tutorial.visible = false
