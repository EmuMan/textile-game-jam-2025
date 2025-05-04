extends BLEConnection

func _ready() -> void:
	initialize()
	connect_to_device("pleaseee")

func _process(_delta) -> void:
	process_signals()

func _on_message_received(data: String) -> void:
	print("A MESSAGE HAS BEEN RECEIVED!!!! " + data)

func _on_connected() -> void:
	print("CONNECTION HAS BEEN ESTABLISHED!!!!!")
