extends Control

var stats_row = preload("res://scenes/menus/stats_row.tscn")
@onready var stats_table: VBoxContainer = $VBoxContainer/PanelContainer2/ScrollContainer/VBoxContainer

var row_name := 0

func _ready() -> void:
	if SaveManager == null:
		push_warning("StatsTable: SaveManager não encontrado")
		return
	
	SaveManager.load_from_disk()
	var totals = SaveManager.profile.user.totals
	
	var rows : Array = [
		{"id": "Updated at", "name": str(SaveManager.profile.updated_at)},
		{"id": "Total score", "name": str(totals.score)},
		{"id": "Total time played", "name": str(totals.play_time_hms)},
		{"id": "Enemies killed", "name": str(totals.enemies_killed)},
		{"id": "Stages played", "name": str(totals.stages_played)},
		{"id": "Wins", "name": str(totals.stages_won)},
		{"id": "Losses", "name": str(totals.stages_lost)},
		{"id": "Black holes opened", "name": str(totals.black_holes_opened)},
	]
	
	for row in rows:
		set_data(row)


func set_data(stats_data: Dictionary) -> void:
	row_name += 1
	var row := stats_row.instantiate()
	row.name = str(row_name)
	stats_table.add_child(row)
	row.get_node("StatNameLabel").text = str(stats_data["id"])
	row.get_node("StatValueLabel").text = str(stats_data["name"])
