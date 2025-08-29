extends Node2D

var rng = RandomNumberGenerator.new()
var gamemode = "external" # Can be either "virtual" or "external"
var colors = [Color(0.69, 0.043, 0.204), Color(1.0, 0.433, 0.0), Color(0.09, 0.639, 0.392), Color(0.189, 0.608, 0.63), Color(0.21, 0.539, 0.942), Color(0.59, 0.074, 0.615), Color(0.911, 0.174, 0.644)]
# Each item in creature_data is: [sprite texture, height min, height max, weight min, weight max]
var creature_data = {
	"Swoot" : ["res://art/swoot.png", 0.4, 0.8, 0.12, 7.2],
	"Woof" : ["res://art/woof.png", 0.7, 1.1, 42.2, 110.0],
	"Amigup" : ["res://art/amigup.png", 0.24, 0.69, 0.03, 5.3],
	"Duobeak" : ["res://art/duobeak.png", 1.29, 1.89, 3.2, 4.5],
	"Bebble" : ["res://art/bebble.png", 0.07, 0.5, 0.03, 0.05],
	"Echogloom" : ["res://art/echogloom.png", 3.3, 4.1, 3.7, 5.5],
	"Guronk" : ["res://art/guronk.png", 1.7, 2.5, 150.0, 250.0],
	"Litone" : ["res://art/litone.png", 0.2, 0.3, 4.0, 5.0],
	"Dargon" : ["res://art/dargon.png", 3.96, 4.0, 16.9, 18.5],
	"Inicort" : ["res://art/inicort.png", 1.2, 1.6, 180.0, 200.0],
	"Filber" : ["res://art/filber.png", 1.6, 1.9, 1.7, 2.0]
}
# Each item in current_creatures is a list like this: 
#     index : [creature name, height, weight, boolean for whether creature has been seen or not]
# Example:
#         0 : ["Filber", 7, 6, Color(0.09, 0.639, 0.392), false]
var current_creatures = {}
# Virtual Game Variables
var player_class = preload("res://scenes/player.tscn")
var creature_class = preload("res://scenes/creature.tscn")
var player_instance = null
var creature = null

func _ready() -> void:
	# Set up virtual device game
	if has_node("VirtualDevice/CatchButton"):
		gamemode = "virtual"
		$UI.visible = false
		get_node("VirtualDevice").captured.connect(caught)
		get_node("VirtualDevice").add_creature.connect(add_creature)
		# Add player and creature
		player_instance = player_class.instantiate()
		player_instance.global_position = Vector2(320, 180)
		add_child(player_instance)
		get_node("VirtualDevice").player = player_instance
		add_creature()
	# Set up external device game
	if has_node("BLEConnection"):
		gamemode = "external"
		get_node("BLEConnection").captured.connect(caught)
	$UI/RichTextLabel1.clear()
	$UI/Info.visible = false

func rerender_creature_list():
	$UI/RichTextLabel1.clear()
	for i in range(current_creatures.size()):
		$UI/RichTextLabel1.push_meta(i)
		$UI/RichTextLabel1.push_color(current_creatures[i][3])
		if current_creatures[i][4]: # Creature has been seen
			$UI/RichTextLabel1.append_text(current_creatures[i][0] + "\n")
		else: # Creature has not been seen
			$UI/RichTextLabel1.append_text(current_creatures[i][0])
			$UI/RichTextLabel1.pop_all()
			$UI/RichTextLabel1.push_color(Color(1.0, 1.0, 1.0))
			$UI/RichTextLabel1.append_text("[bounce] - New![/bounce]\n")

func caught():
	# Pick random variabels for the new creature
	var c = creature_data.keys()[randi() % creature_data.size()] # Get creature name
	var height = snappedf(rng.randf_range(creature_data[c][1], creature_data[c][2]), 0.01)
	var weight = snappedf(rng.randf_range(creature_data[c][3], creature_data[c][4]), 0.01)
	var color = colors[randi() % colors.size()]
	# Add new creature to the current_creatures list
	var index = current_creatures.size()
	current_creatures[index] = [c, height, weight, color, false] # Add new creature entry
	rerender_creature_list()

# Display the clicked creature
func _on_rich_text_label_1_meta_clicked(meta: Variant) -> void:
	if $UI/Info.visible == true:
		return
	# meta = index of clicked creature
	current_creatures[meta][4] = true # Mark this creature as seen
	$UI/Info.visible = true
	$UI/Info/RichTextLabel2.clear()
	$UI/Info/RichTextLabel2.append_text(current_creatures[meta][0] + "\n")
	$UI/Info/RichTextLabel2.append_text("Height: " + str(current_creatures[meta][1]) + " m\n")
	$UI/Info/RichTextLabel2.append_text("Weight: " + str(current_creatures[meta][2]) + " kg\n")
	
	# Set creature texture
	$UI/Info/Creature.texture = load(creature_data[current_creatures[meta][0]][0])
	$UI/Info/Creature.modulate = current_creatures[meta][3]
	# Back button
	$UI/Info/RichTextLabel2.append_text("[url]Back[/url]\n")

func _on_rich_text_label_2_meta_clicked(_meta: Variant) -> void:
	rerender_creature_list()
	# Hide info
	$UI/Info.visible = false

# Virtual Game Functions
func _input(e):
	if gamemode == "external": return
	if e.is_action_pressed("toggle_creaturedex"):
		$UI.visible = !$UI.visible

func add_creature():
	var creature_instance = creature_class.instantiate()
	creature_instance.global_position.x = player_instance.global_position.x + randi_range(-1450, 1450)
	creature_instance.global_position.y = player_instance.global_position.y + randi_range(-1450, 1450)
	add_child(creature_instance)
	get_node("VirtualDevice").creature = creature_instance
