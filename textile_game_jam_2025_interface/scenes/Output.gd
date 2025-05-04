extends RichTextLabel
signal next_message #Defines the next_message signal
signal messages_empty #Defines the messages empty signal
var messages_list = []
var current_tween: Tween = null

func set_messages(message_list):
	messages_list = message_list
	messages()

func _on_gui_input(event: InputEvent) -> void:
	if event.is_action_released("ui_accept"):
		emit_signal("next_message") #Emit signal to signify that there are no more messages to display and whatever function was going on in Main can now continue("messages_empty")
		messages()

func messages():
	if messages_list.size() > 0: #More messages left
		clear() #Clears the label
		visible_ratio = 0
		var seconds = .03 * messages_list[0].length() #Update var seconds based on how many chars are in the message
		append_text(str(messages_list.pop_front()))
		var tween = get_tree().create_tween()
		tween.tween_property(self, "visible_ratio", 1, seconds)
		if messages_list.is_empty(): #messages_list is now empty
			emit_signal("messages_empty") #Emit signal to signify that there are no more messages to display and whatever function was going on in game can now continue("messages_empty")
