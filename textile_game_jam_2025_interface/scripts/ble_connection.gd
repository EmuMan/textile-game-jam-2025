extends GodotBLE

signal uart_write(data)

func _ready() -> void:
	print(init_adapter_list())
	set_adapter(0)
	start_scan()

func _process(delta: float) -> void:
	pass

func _on_device_found(identifier: String, address: String) -> void:
	print(identifier, '\t', address)
	if identifier == 'pleaseee':
		print("Found device!")
		stop_scan()
		var device = get_device_index_from_identifier('pleaseee')
		print(device)
		if connect_to_device(device) == 0:
			print("Connected successfully!")
		#print(show_all_services())
		#print(get_current_device_index())
		#uart_write.emit("track:0:The Creature:over there")

func _on_uart_write(data: String) -> void:
	print("Starting write...")
	print(write_data_to_service(0, data))
