# NationManager.gd
extends Object   


# --- Nation Class ---
class Nation:
	var name: String
	var color: Color
	var regions: Array = []


# --- NationManager Data ---
var nations: Dictionary = {}          # nation_name -> Nation
var region_to_owner: Dictionary = {}  # region_name -> Nation


# Stores region info dictionaries keyed by region name
var region_data: Dictionary = {}




# --- Initialize Nations ---
func create_nations():
	# France
	var france = Nation.new()
	france.name = "France"
	france.color = Color(0, 0, 1)
	france.regions = ["Ankara", "Rize", "Trabzon"]
	nations[france.name] = france


	# England
	var uk = Nation.new()
	uk.name = "United Kingdom"
	uk.color = Color(1, 0, 0)
	uk.regions = ["London", "Berlin", "Paris"]
	nations[uk.name] = uk
	# Add other nations similarly...


	# Map all regions to their owners
	map_regions_to_nations()


# --- Map regions to owning nation ---
func map_regions_to_nations():
	for nation in nations.values():
		for region_name in nation.regions:
			region_to_owner[region_name] = nation


# --- Change ownership dynamically ---
func change_region_owner(region_name: String, new_owner: Nation):
	var old_owner = region_to_owner.get(region_name, null)
	if old_owner:
		old_owner.regions.erase(region_name)
	new_owner.regions.append(region_name)
	region_to_owner[region_name] = new_owner


# --- Get owner of a region ---
func get_region_owner(region_name: String) -> Nation:
	return region_to_owner.get(region_name, null)


func get_total_resources(nation_name: String) -> Dictionary:
	var totals = {"population": 0, "oil": 0.0, "gdp": 0}
	for region_name in region_to_owner.keys():
		var owner = region_to_owner[region_name]
		if owner.name == nation_name:
			var region_info = region_data.get(region_name, null)
			if region_info:
				# Use the updated 'population' key (already int)
				totals.population += region_info.get("population", 0)
				totals.oil += float(region_info.get("oil", 0))
				totals.gdp += int(float(region_info.get("GDP", region_info.get("gdp", 0))))
	return totals
