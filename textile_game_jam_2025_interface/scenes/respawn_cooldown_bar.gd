extends TextureProgressBar

var original_x = global_position.x

func _on_timer_timeout() -> void:
	if value == 95:
		#var flash_tween = create_tween()
		#flash_tween.tween_property(self, "tint_progress", Color(1.0, 1.0, 1.0), 0.15)
		#flash_tween.chain().tween_property(self, "tint_progress", Color(0.682, 0.137, 0.204), 0.15)
		var flash_tween = create_tween()
		flash_tween.tween_property(self, "tint_under:a", 255, 0.15)
		flash_tween.tween_property(self, "tint_under:a", 0, 0.15)
	value += 5

# Check if player can respawn a creature, return true if it can and false if it can't
func try_respawn() -> bool:
	if value == 100:
		value = 0
		return true
	else:
		var shake_tween = create_tween()
		shake_tween.tween_property(self, "global_position:x", original_x-3, 0.06)
		shake_tween.tween_property(self, "global_position:x", original_x, 0.06)
		shake_tween.tween_property(self, "global_position:x", original_x-3, 0.06)
		shake_tween.tween_property(self, "global_position:x", original_x, 0.06)
		global_position.x = original_x
		return false
