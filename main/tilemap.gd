extends TileMapLayer

@onready var gen_timer: Timer = $"../gen_timer"
@onready var start_button: Button = $"../StartButton"
@onready var pause_label: Label = $"../PauseLabel"
@onready var speed_input: LineEdit = $"../speedInput"
@onready var restart_button: Button = $"../restartButton"
@onready var gen_label: Label = $"../GenLabel"
@onready var reset_sound: AudioStreamPlayer = $"../resetSound"
@onready var tile_sound: AudioStreamPlayer = $"../tileSound"

const ATLAS_COORD_DEAD_CELL: Vector2i = Vector2i(0,0)
const ATLAS_COORD_ALIVE_CELL: Vector2i = Vector2i(1,0)

var size: Vector2i
var is_running: bool = false
var alive_cells: Dictionary = {}
var generation_count: int = 0

func _ready() -> void:
	size = get_used_rect().size
	for cell_pos in get_used_cells():
		if get_cell_atlas_coords(cell_pos) == ATLAS_COORD_ALIVE_CELL:
			alive_cells[cell_pos] = true
	gen_timer.wait_time = 1.0 / 1

func update_the_grid():
	var next_gen_alive: Dictionary = {}
	var potential_cells: Dictionary = {}
	
	for cell in alive_cells:
		potential_cells[cell] = true
		for x_offset in range(-1, 2):
			for y_offset in range(-1, 2):
				var neighbor: Vector2i = cell + Vector2i(x_offset, y_offset)
				if neighbor.x in range(size.x) and neighbor.y in range(size.y):
					potential_cells[neighbor] = true
					
	for cell in potential_cells:
		var neighbors_count: int = 0
		for x_offset in range(-1, 2):
			for y_offset in range(-1, 2):
				if x_offset == 0 and y_offset == 0:
					continue
				var neighbor: Vector2i = cell + Vector2i(x_offset, y_offset)
				if alive_cells.has(neighbor):
					neighbors_count += 1
					
		var is_alive = alive_cells.has(cell)
		if is_alive and (neighbors_count == 2 or neighbors_count == 3):
			next_gen_alive[cell] = true
		elif not is_alive and neighbors_count == 3:
			next_gen_alive[cell] = true
	
	for cell in alive_cells.keys() + next_gen_alive.keys():
		var was_alive = alive_cells.has(cell)
		var is_alive = next_gen_alive.has(cell)
		if was_alive != is_alive:
			set_cell(cell, 0, ATLAS_COORD_ALIVE_CELL if is_alive else ATLAS_COORD_DEAD_CELL)
				
	alive_cells = next_gen_alive

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and not event.is_echo():
		var cell_pos: Vector2i = local_to_map(get_local_mouse_position())
		if cell_pos.x in range(size.x) and cell_pos.y in range(size.y):
			tile_sound.play()
			if alive_cells.has(cell_pos):
				set_cell(cell_pos, 0,  ATLAS_COORD_DEAD_CELL)
				alive_cells.erase(cell_pos)
			else:
				set_cell(cell_pos, 0,  ATLAS_COORD_ALIVE_CELL)
				alive_cells[cell_pos] = true
			if is_running:
				gen_timer.start()

func _on_gen_timer_timeout() -> void:
	update_the_grid()
	generation_count += 1
	gen_label.text = "Generation: " + str(generation_count)

func _on_button_toggled(toggled_on: bool) -> void:
	is_running = toggled_on
	pause_label.visible = !toggled_on
	restart_button.visible = !toggled_on
	if toggled_on:
		start_button.text = "stop"
		gen_timer.start()
	else:
		start_button.text = "start"
		gen_timer.stop()

func _on_speed_input_text_submitted(new_text: String) -> void:
	var new_speed: int = int(new_text)
	if new_speed > 0:
		gen_timer.wait_time = 1.0 / new_speed
		if new_speed > 60:
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		else:
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	speed_input.text = str(int(1.0 / gen_timer.wait_time))


func _on_restart_button_pressed() -> void:
	for cell in alive_cells:
		set_cell(cell, 0,  ATLAS_COORD_DEAD_CELL)
	alive_cells.clear()
	generation_count = 0
	gen_label.text = "Generation: " + str(generation_count)
	reset_sound.play()
