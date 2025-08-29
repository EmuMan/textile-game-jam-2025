@tool
extends RichTextEffect
class_name RichTextBounce

# Syntax: [bounce freq=5.0 amp=10.0]{text}[/ghost]

var bbcode = "bounce"

func _process_custom_fx(char_fx):
	var freq = char_fx.env.get("freq", 7.0)
	
	# Sine wave oscillation: goes from -1 to 1
	char_fx.offset.y = sin(char_fx.elapsed_time * freq)
	
	return true
