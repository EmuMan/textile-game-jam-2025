extends Node2D

var rng = RandomNumberGenerator.new()
# Each item in creature_data is: [sprite texture, height min, height max, weight min, weight max]
var creature_data = {
	"Swoot" : ["res://art/swoot.png", 0.4, 0.8, 0.12, 7.2],
	"Woof" : ["res://art/woof.png", 0.7, 1.1, 42.2, 110.0],
	"Amigup" : ["res://art/amigup.png", 0.24, 0.69, 0.03, 5.3],
	"Duobeak" : ["res://art/duobeak.png", 5, 10, 5, 10],
	"Bebble" : ["res://art/bebble.png", 5, 10, 5, 10],
	"Echogloom" : ["res://art/echogloom.png", 5, 10, 5, 10],
	"Guronk" : ["res://art/guronk.png", 5, 10, 5, 10],
	"Litone" : ["res://art/litone.png", 5, 10, 5, 10],
	"Dargon" : ["res://art/dargon.png", 5, 10, 5, 10],
	"Inicort" : ["res://art/inicort.png", 5, 10, 5, 10],
	"Filber" : ["res://art/filber.png", 5, 10, 5, 10]
}
# Each item in current_creatures is a list like this: 
#     index : [creature name, height, weight, boolean for whether creature has been seen or not]
# Example:
#         0 : ["Filber", 7, 6, false]
var current_creatures = {0 : ["Filber", 7, 6, false]}


func _ready() -> void:
	$RichTextLabel1.clear()
	$Info.visible = false
	
	caught()
	caught()


func caught():
	print("Creature caught!")
	# Pick random variabels for the new creature
	var c = creature_data.keys()[randi() % creature_data.size()] # Get creature name
	var height = snappedf(rng.randf_range(creature_data[c][1], creature_data[c][2]), 0.01)
	var weight = snappedf(rng.randf_range(creature_data[c][3], creature_data[c][4]), 0.01)
	# Add new creature to the current_creatures list
	var index = current_creatures.size()
	current_creatures[index] = [c, height, weight, false] #Add new creature entry
	$RichTextLabel1.push_meta(index)
	$RichTextLabel1.append_text(c + "\n")
	print("current_creatures: ", current_creatures)


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
	# Back button
	$Info/RichTextLabel2.append_text("[url]Back[/url]\n")


func _on_rich_text_label_2_meta_clicked(_meta: Variant) -> void:
	$Info.visible = false
