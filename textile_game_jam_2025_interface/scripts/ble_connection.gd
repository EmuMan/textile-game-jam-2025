extends BLEConnection

func _ready() -> void:
	initialize()
	connect_to_device("pleaseee")

func _process(_delta) -> void:
	process_signals()

func _on_message_received(data: String) -> void:
	var args = data.split(":")
	var command = args[0]
	if command == "captured":
		var id = int(args[1])
		print("Captured: %d" % id)
		# call catch functions!!

func _on_connected() -> void:
	print("CONNECTION HAS BEEN ESTABLISHED!!!!!")
