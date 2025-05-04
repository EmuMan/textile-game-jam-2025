extends Node2D

func _ready() -> void:
	$Output.call_deferred("set_messages", ["Welcome to Creature Capture!", "Wacky Creatures will appear around the room for you to catch!", "So go out there and start catching some Creatures!"])
