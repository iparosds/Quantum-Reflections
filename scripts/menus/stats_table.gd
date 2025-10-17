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
		{"id": "Atualizado em",        "name": str(SaveManager.profile.updated_at)},
		{"id": "Score total",          "name": str(totals.score)},
		{"id": "Tempo total (HMS)",    "name": str(totals.play_time_hms)},
		{"id": "Inimigos mortos",      "name": str(totals.enemies_killed)},
		{"id": "Estágios jogados",     "name": str(totals.stages_played)},
		{"id": "Vitórias",             "name": str(totals.stages_won)},
		{"id": "Derrotas",             "name": str(totals.stages_lost)},
		{"id": "Buracos negros (tot)", "name": str(totals.black_holes_opened)},
	]
	
	for row in rows:
		set_data(row)


func set_data(stats_data: Dictionary) -> void:
	row_name += 1
	var row := stats_row.instantiate()
	row.name = str(row_name)
	stats_table.add_child(row)
	row.get_node("1").text = str(stats_data["id"])
	row.get_node("2").text = str(stats_data["name"])
