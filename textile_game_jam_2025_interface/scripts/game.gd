extends Node2D

var rng = RandomNumberGenerator.new()
# Each item in creature_data is: [sprite texture, height min, height max, weight min, weight max]
var colors = [Color(0.69, 0.043, 0.204), Color(1.0, 0.433, 0.0), Color(0.09, 0.639, 0.392), Color(0.189, 0.608, 0.63), Color(0.21, 0.539, 0.942), Color(0.59, 0.074, 0.615), Color(0.911, 0.174, 0.644)]
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
#         0 : ["Filber", 7, 6, color, false]
var current_creatures = {0 : ["Filber", 7, 6, Color(0.09, 0.639, 0.392), false]}


func _ready() -> void:
	$RichTextLabel1.clear()
	$Info.visible = false
	
	for i in range(50):
		caught()


func caught():
	# Pick random variabels for the new creature
	var c = creature_data.keys()[randi() % creature_data.size()] # Get creature name
	var height = snappedf(rng.randf_range(creature_data[c][1], creature_data[c][2]), 0.01)
	var weight = snappedf(rng.randf_range(creature_data[c][3], creature_data[c][4]), 0.01)
	var color = colors[randi() % colors.size()]
	# Add new creature to the current_creatures list
	var index = current_creatures.size()
	current_creatures[index] = [c, height, weight, color, false] #Add new creature entry
	$RichTextLabel1.push_meta(index)
	$RichTextLabel1.push_color(color)
	$RichTextLabel1.append_text(c + "\n")


# Display the clicked creature
func _on_rich_text_label_1_meta_clicked(meta: Variant) -> void:
	# meta = index of clicked creature
	$Info.visible = true
	$Info/RichTextLabel2.clear()
	$Info/RichTextLabel2.append_text(current_creatures[meta][0] + "\n")
	$Info/RichTextLabel2.append_text("Height: " + str(current_creatures[meta][1]) + " m\n")
	$Info/RichTextLabel2.append_text("Weight: " + str(current_creatures[meta][2]) + " kg\n")
	
	# Set creature texture
	$Info/Creature.texture = load(creature_data[current_creatures[meta][0]][0])
	$Info/Creature.modulate = current_creatures[meta][3]
	# Back button
	$Info/RichTextLabel2.append_text("[url]Back[/url]\n")


func _on_rich_text_label_2_meta_clicked(_meta: Variant) -> void:
	$Info.visible = false
