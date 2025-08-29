extends Node2D
var ble_node = preload("res://scenes/ble_test.tscn")
var ble_instance = null
var game_scene = load("res://scenes/game.tscn")
var virtual_device = preload("res://scenes/virtual_device.tscn")
var external_device_found = false

func _ready() -> void:
	# Title Screen start animations
	$ExternalStartButton.disabled = true
	$VirtualStartButton.disabled = true
	$ConnectingDeviceScreen.visible = false
	$Title.global_position.y = 170
	$Title.modulate.a = 0
	$ExternalStartButton.modulate.a = 0
	$VirtualStartButton.modulate.a = 0
	var lift_tween = create_tween()
	lift_tween.tween_property($Title, "global_position:y", 115, 1)
	var title_opacity_tween = create_tween()
	title_opacity_tween.tween_property($Title, "modulate:a", 1, 1.4)
	await title_opacity_tween.finished
	var e_start_opacity_tween = create_tween()
	e_start_opacity_tween.tween_property($ExternalStartButton, "modulate:a", 1, 0.4)
	await e_start_opacity_tween.finished
	var v_start_opacity_tween = create_tween()
	v_start_opacity_tween.tween_property($VirtualStartButton, "modulate:a", 1, 0.4)
	$ExternalStartButton.disabled = false
	$VirtualStartButton.disabled = false

func _on_external_start_button_pressed() -> void:
	# Change screen to device connection screen
	$ConnectingDeviceScreen/BackButton.global_position.y = 272
	$ExternalStartButton.disabled = true
	$VirtualStartButton.disabled = true
	$ExternalStartButton.visible = false
	$VirtualStartButton.visible = false
	$ConnectingDeviceScreen/StartButton.visible = false
	$ConnectingDeviceScreen.visible = true
	if external_device_found: 
		_on_ble_connected()
	if !ble_instance:
		ble_instance = ble_node.instantiate()
		ble_instance.connected.connect(_on_ble_connected)
		add_child(ble_instance)
	await get_tree().create_timer(5).timeout
	_on_ble_connected()

func _on_back_button_pressed() -> void:
	$ExternalStartButton.disabled = false
	$VirtualStartButton.disabled = false
	$ExternalStartButton.visible = true
	$VirtualStartButton.visible = true
	$ConnectingDeviceScreen.visible = false

func _on_ble_connected() -> void:
	external_device_found = true
	$ConnectingDeviceScreen/StartButton.global_position.y = 272
	$ConnectingDeviceScreen/BackButton.global_position.y = 304
	$ConnectingDeviceScreen/StartButton.visible = true
	$ConnectingDeviceScreen/LoadingText.clear()
	$ConnectingDeviceScreen/LoadingText.append_text("External device found!")

func _on_virtual_start_button_pressed() -> void:
	var game_instance = game_scene.instantiate()
	var device_instance = virtual_device.instantiate()
	game_instance.add_child(device_instance)
	get_tree().get_root().add_child(game_instance)
	queue_free()

func _on_start_button_pressed() -> void:
	var game_instance = game_scene.instantiate()
	ble_instance.reparent(game_instance)
	get_tree().get_root().add_child(game_instance)
	queue_free()
