# Calendar.gd
extends Node


@onready var date_label: Label = $DateLabel


var day: int = 1
var month: int = 1
# --- Set Game start Year
var year: int = 2027


# ---Showing correct amount of days in the months
# ---Showing the correct order of months
var month_lengths = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
var month_names = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"]


# Add days properly accounting for month lengths and leap years
func add_days(days_to_add: int):
	while days_to_add > 0:
		var days_in_current_month = month_lengths[month - 1]
		if month == 2 and is_leap_year(year):
			days_in_current_month = 29


		var remaining_days_in_month = days_in_current_month - day + 1
		if days_to_add >= remaining_days_in_month:
			days_to_add -= remaining_days_in_month
			day = 1
			month += 1
			if month > 12:
				month = 1
				year += 1
		else:
			day += days_to_add
			days_to_add = 0


	update_label()


# -- Leap Year Calculator
func is_leap_year(y: int) -> bool:
	return (y % 4 == 0 and y % 100 != 0) or (y % 400 == 0)


func update_label():
	date_label.text = "%02d %s %d" % [day, month_names[month - 1], year]
