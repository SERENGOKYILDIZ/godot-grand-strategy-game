class_name TopBar extends Panel

@onready var player_nation_label: Label = $HBoxContainer/PlayerNationLabel
@onready var population_label: Label = $HBoxContainer/PopulationLabel
@onready var oil_label: Label = $HBoxContainer/OilLabel
@onready var gdp_label: Label = $HBoxContainer/GDPLabel

func update_top_bar(nation_name: String, population: int, oil: float, gdp: float):
	player_nation_label.text = "🏳 " + nation_name
	population_label.text = "🚶" + str(population)
	oil_label.text = "🛢 " + str(oil)
	gdp_label.text = "＄ " + str(gdp)
