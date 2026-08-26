extends Node3D

const FIELD_HALF_WIDTH := 34.0
const FIELD_HALF_LENGTH := 50.0
const PLAYER_SCENE := preload("res://scenes/player.tscn")

@onready var arena = $Arena
@onready var players_root: Node3D = $Players
@onready var ball: SoccerBall = $Ball
@onready var hud: CanvasLayer = $HUD
@onready var score_label: Label = $HUD/ScoreLabel
@onready var status_label: Label = $HUD/StatusLabel
@onready var clock_label: Label = $HUD/ClockLabel
@onready var phase_label: Label = $HUD/PhaseLabel

var score := {
	"blue": 0,
	"red": 0,
}

var players: Array[SoccerPlayer] = []
var blue_team: Array[SoccerPlayer] = []
var red_team: Array[SoccerPlayer] = []
var debug_panel: PanelContainer
var debug_value_labels := {}
var debug_sliders := {}
var debug_panel_open := false
var controlled_player: SoccerPlayer
var match_time_left := 180.0
var restart_timer := 1.5
var match_phase := "kickoff"
var clock_running := false
var winning_team_name := ""

var tuning := {
	"move_speed": 6.4,
	"dribble_speed": 5.3,
	"pass_speed": 11.0,
	"pass_lift": 1.7,
	"shot_speed": 18.5,
	"shot_lift": 3.4,
	"steal_range": 1.4,
	"pickup_range": 1.35,
	"support_attack_offset": 5.0,
	"support_defend_offset": 3.0,
	"shot_distance": 24.0,
	"pressure_shot_distance": 2.4,
	"goalkeeper_depth": 1.8,
	"mouse_sensitivity": 0.0038,
	"mark_distance": 2.0,
	"cpu_speed_scale": 0.68,
	"cpu_decision_interval": 1.35,
	"cpu_steal_delay": 1.1,
	"cpu_post_steal_delay": 0.85,
	"ball_dribble_sway": 0.17,
	"ball_dribble_bounce": 0.2,
	"ball_dribble_forward": 0.32,
	"ball_carry_follow": 18.0,
	"ball_ground_friction": 6.0,
	"ball_roll_damping": 4.2,
	"ball_air_drag": 0.45,
}

const DEFAULT_TUNING := {
	"move_speed": 6.4,
	"dribble_speed": 5.3,
	"pass_speed": 11.0,
	"pass_lift": 1.7,
	"shot_speed": 18.5,
	"shot_lift": 3.4,
	"steal_range": 1.4,
	"pickup_range": 1.35,
	"support_attack_offset": 5.0,
	"support_defend_offset": 3.0,
	"shot_distance": 24.0,
	"pressure_shot_distance": 2.4,
	"goalkeeper_depth": 1.8,
	"mouse_sensitivity": 0.0038,
	"mark_distance": 2.0,
	"cpu_speed_scale": 0.68,
	"cpu_decision_interval": 1.35,
	"cpu_steal_delay": 1.1,
	"cpu_post_steal_delay": 0.85,
	"ball_dribble_sway": 0.17,
	"ball_dribble_bounce": 0.2,
	"ball_dribble_forward": 0.32,
	"ball_carry_follow": 18.0,
	"ball_ground_friction": 6.0,
	"ball_roll_damping": 4.2,
	"ball_air_drag": 0.45,
}

const TUNING_DEFS := [
	{"key": "move_speed", "label": "Move Speed", "min": 3.0, "max": 12.0, "step": 0.1},
	{"key": "dribble_speed", "label": "Dribble Speed", "min": 2.0, "max": 10.0, "step": 0.1},
	{"key": "pass_speed", "label": "Pass Speed", "min": 4.0, "max": 20.0, "step": 0.1},
	{"key": "pass_lift", "label": "Pass Lift", "min": 0.0, "max": 4.0, "step": 0.1},
	{"key": "shot_speed", "label": "Shot Speed", "min": 8.0, "max": 30.0, "step": 0.1},
	{"key": "shot_lift", "label": "Shot Lift", "min": 0.0, "max": 6.0, "step": 0.1},
	{"key": "steal_range", "label": "Steal Range", "min": 0.5, "max": 3.0, "step": 0.05},
	{"key": "pickup_range", "label": "Pickup Range", "min": 0.5, "max": 3.0, "step": 0.05},
	{"key": "support_attack_offset", "label": "Attack Support", "min": 1.0, "max": 14.0, "step": 0.1},
	{"key": "support_defend_offset", "label": "Defend Support", "min": 1.0, "max": 10.0, "step": 0.1},
	{"key": "shot_distance", "label": "Shot Distance", "min": 6.0, "max": 40.0, "step": 0.2},
	{"key": "pressure_shot_distance", "label": "Pressure Shot", "min": 0.5, "max": 6.0, "step": 0.1},
	{"key": "goalkeeper_depth", "label": "Keeper Depth", "min": 0.5, "max": 5.0, "step": 0.1},
	{"key": "mouse_sensitivity", "label": "Mouse Sense", "min": 0.001, "max": 0.01, "step": 0.0005},
	{"key": "mark_distance", "label": "Mark Distance", "min": 0.8, "max": 4.0, "step": 0.1},
	{"key": "cpu_speed_scale", "label": "CPU Speed", "min": 0.3, "max": 1.1, "step": 0.05},
	{"key": "cpu_decision_interval", "label": "CPU Decision", "min": 0.2, "max": 3.0, "step": 0.05},
	{"key": "cpu_steal_delay", "label": "CPU Steal Delay", "min": 0.2, "max": 3.0, "step": 0.05},
	{"key": "cpu_post_steal_delay", "label": "CPU Recover Delay", "min": 0.1, "max": 2.5, "step": 0.05},
	{"key": "ball_dribble_sway", "label": "Dribble Sway", "min": 0.0, "max": 0.45, "step": 0.01},
	{"key": "ball_dribble_bounce", "label": "Dribble Bounce", "min": 0.0, "max": 0.5, "step": 0.01},
	{"key": "ball_dribble_forward", "label": "Dribble Lead", "min": 0.0, "max": 0.8, "step": 0.01},
	{"key": "ball_carry_follow", "label": "Carry Follow", "min": 4.0, "max": 28.0, "step": 0.5},
	{"key": "ball_ground_friction", "label": "Ball Friction", "min": 0.5, "max": 14.0, "step": 0.1},
	{"key": "ball_roll_damping", "label": "Ball Roll Damp", "min": 0.5, "max": 12.0, "step": 0.1},
	{"key": "ball_air_drag", "label": "Ball Air Drag", "min": 0.0, "max": 3.0, "step": 0.05},
]

const BLUE_SPAWNS := [
	{"position": Vector3(0.0, 1.0, -43.0), "role": "goalkeeper"},
	{"position": Vector3(-14.0, 1.0, -26.0), "role": "defender"},
	{"position": Vector3(14.0, 1.0, -26.0), "role": "defender"},
	{"position": Vector3(-10.0, 1.0, -8.0), "role": "midfielder"},
	{"position": Vector3(10.0, 1.0, -4.0), "role": "striker"},
]

const RED_SPAWNS := [
	{"position": Vector3(0.0, 1.0, 43.0), "role": "goalkeeper"},
	{"position": Vector3(-14.0, 1.0, 26.0), "role": "defender"},
	{"position": Vector3(14.0, 1.0, 26.0), "role": "defender"},
	{"position": Vector3(-10.0, 1.0, 8.0), "role": "midfielder"},
	{"position": Vector3(10.0, 1.0, 4.0), "role": "striker"},
]


func _ready() -> void:
	ball.match_controller = self
	arena.field_half_width = FIELD_HALF_WIDTH
	arena.field_half_length = FIELD_HALF_LENGTH
	arena.build_arena()
	spawn_teams()
	update_team_links()
	assign_controlled_player(blue_team[4])
	apply_tuning()
	build_debug_panel()
	update_score_label()
	update_clock_label()
	update_phase_label()
	for goal in [$BlueScoreZone, $RedScoreZone]:
		goal.goal_scored.connect(_on_goal_scored)
	ball.reset_to_center()
	ball.claim_possession(blue_team[4], true)
	status_label.text = "Blue starts in possession. Mouse aims, left click passes, right click shoots."


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("toggle_debug_panel"):
		toggle_debug_panel()
	if Input.is_action_just_pressed("switch_player") and not debug_panel_open:
		switch_to_best_teammate()
	if Input.is_action_just_pressed("reset_ball"):
		restart_match()
	update_match_clock(delta)
	if match_phase == "kickoff":
		status_label.text = "Kickoff setup. Match resumes when the countdown hits zero."
	elif ball.carrier:
		status_label.text = "%s controls the ball" % [ball.carrier.display_name]
	else:
		status_label.text = "Loose ball - close it down or offer support."
	if match_phase == "finished":
		status_label.text = "%s. Press R to restart the match." % [winning_team_name]


func spawn_teams() -> void:
	players.clear()
	blue_team.clear()
	red_team.clear()

	for i in BLUE_SPAWNS.size():
		var player := spawn_player("blue", i, BLUE_SPAWNS[i], i == 4)
		blue_team.append(player)
		players.append(player)

	for i in RED_SPAWNS.size():
		var player := spawn_player("red", i, RED_SPAWNS[i], false)
		red_team.append(player)
		players.append(player)


func spawn_player(team_name: String, index: int, config: Dictionary, is_user: bool) -> SoccerPlayer:
	var player := PLAYER_SCENE.instantiate() as SoccerPlayer
	player.name = "%sPlayer%d" % [team_name.capitalize(), index + 1]
	player.team_name = team_name
	player.display_name = "%s %s" % [team_name.capitalize(), config["role"].capitalize()]
	player.role_name = config["role"]
	player.home_position = config["position"]
	player.is_user_controlled = false
	player.attack_direction = Vector3.BACK if team_name == "blue" else Vector3.FORWARD
	player.team_color = Color(0.23, 0.48, 0.95, 1.0) if team_name == "blue" else Color(0.96, 0.35, 0.31, 1.0)
	player.ball = ball
	player.match_controller = self
	players_root.add_child(player)
	player.global_position = config["position"]
	player.rotation.y = PI if team_name == "blue" else 0.0
	if is_user:
		controlled_player = player
	return player


func update_team_links() -> void:
	for player in blue_team:
		player.teammates = blue_team
		player.opponents = red_team
	for player in red_team:
		player.teammates = red_team
		player.opponents = blue_team


func _on_goal_scored(team_name: String) -> void:
	if match_phase == "finished":
		return
	if not score.has(team_name):
		return
	score[team_name] += 1
	update_score_label()
	reset_after_goal(team_name)


func update_score_label() -> void:
	score_label.text = "Blue %d - %d Red" % [score["blue"], score["red"]]


func reset_after_goal(last_scoring_team: String) -> void:
	ball.reset_to_center()
	for player in players:
		player.reset_to_home()
	var kickoff_team := red_team if last_scoring_team == "blue" else blue_team
	var kickoff_player: SoccerPlayer = kickoff_team[4]
	assign_controlled_player(get_best_control_candidate())
	ball.claim_possession(kickoff_player, true)
	restart_timer = 1.5
	match_phase = "kickoff"
	clock_running = false
	update_phase_label()


func get_attack_goal_position(team_name: String) -> Vector3:
	return Vector3(0.0, 1.0, FIELD_HALF_LENGTH + 0.3) if team_name == "blue" else Vector3(0.0, 1.0, -FIELD_HALF_LENGTH - 0.3)


func get_defend_goal_position(team_name: String) -> Vector3:
	return Vector3(0.0, 1.0, -FIELD_HALF_LENGTH - 0.3) if team_name == "blue" else Vector3(0.0, 1.0, FIELD_HALF_LENGTH + 0.3)


func get_support_spot(player: SoccerPlayer) -> Vector3:
	var attack_sign := 1.0 if player.team_name == "blue" else -1.0
	var ball_pos := ball.global_position
	var support := player.home_position
	if ball.carrier and ball.carrier.team_name == player.team_name:
		support.z = lerp(player.home_position.z, ball_pos.z + attack_sign * get_tuning_value("support_attack_offset", 5.0), 0.45)
		support.x = lerp(player.home_position.x, ball_pos.x * 0.6, 0.35)
	else:
		support.z = lerp(player.home_position.z, ball_pos.z - attack_sign * get_tuning_value("support_defend_offset", 3.0), 0.4)
	if player.role_name == "goalkeeper":
		support = player.home_position
	return clamp_to_field(support)


func clamp_to_field(point: Vector3) -> Vector3:
	point.x = clamp(point.x, -FIELD_HALF_WIDTH + 1.2, FIELD_HALF_WIDTH - 1.2)
	point.z = clamp(point.z, -FIELD_HALF_LENGTH + 1.2, FIELD_HALF_LENGTH - 1.2)
	point.y = 1.0
	return point


func get_best_pass_target(from_player: SoccerPlayer) -> SoccerPlayer:
	var candidates := from_player.teammates
	var attack_sign := 1.0 if from_player.team_name == "blue" else -1.0
	var best_target: SoccerPlayer
	var best_score := -INF
	for teammate in candidates:
		if teammate == from_player:
			continue
		var progress_score := (teammate.global_position.z - from_player.global_position.z) * attack_sign
		var spacing_score := teammate.global_position.distance_to(from_player.global_position) * 0.15
		var defender_penalty := get_closest_opponent_distance(teammate) * -0.05
		var total_score := progress_score + spacing_score - defender_penalty
		if total_score > best_score:
			best_score = total_score
			best_target = teammate
	return best_target


func get_closest_opponent_distance(player: SoccerPlayer) -> float:
	var best_distance := INF
	for opponent in player.opponents:
		best_distance = min(best_distance, opponent.global_position.distance_to(player.global_position))
	return best_distance


func is_closest_on_team_to_ball(player: SoccerPlayer) -> bool:
	var best_player: SoccerPlayer
	var best_distance := INF
	for teammate in player.teammates:
		var distance := teammate.global_position.distance_to(ball.global_position)
		if distance < best_distance:
			best_distance = distance
			best_player = teammate
	return best_player == player


func get_tuning_value(key: String, default_value: float) -> float:
	if tuning.has(key):
		return tuning[key]
	return default_value


func is_debug_panel_open() -> bool:
	return debug_panel_open


func apply_tuning() -> void:
	for player in players:
		player.move_speed = get_tuning_value("move_speed", player.move_speed)
		player.dribble_speed = get_tuning_value("dribble_speed", player.dribble_speed)
		player.steal_range = get_tuning_value("steal_range", player.steal_range)
		player.pickup_range = get_tuning_value("pickup_range", player.pickup_range)
		player.mouse_sensitivity = get_tuning_value("mouse_sensitivity", player.mouse_sensitivity)


func build_debug_panel() -> void:
	debug_panel = PanelContainer.new()
	debug_panel.name = "DebugPanel"
	debug_panel.visible = false
	debug_panel.offset_left = 1030.0
	debug_panel.offset_top = 20.0
	debug_panel.offset_right = 1560.0
	debug_panel.offset_bottom = 860.0
	hud.add_child(debug_panel)

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.05, 0.08, 0.12, 0.9)
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = Color(0.25, 0.66, 0.95, 0.9)
	panel_style.corner_radius_top_left = 12
	panel_style.corner_radius_top_right = 12
	panel_style.corner_radius_bottom_right = 12
	panel_style.corner_radius_bottom_left = 12
	debug_panel.add_theme_stylebox_override("panel", panel_style)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 14)
	debug_panel.add_child(margin)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(vbox)

	var title := Label.new()
	title.text = "Debug Tuning"
	title.add_theme_font_size_override("font_size", 24)
	vbox.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "F3 toggles this panel. Sliders update gameplay live."
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_font_size_override("font_size", 15)
	vbox.add_child(subtitle)

	for definition in TUNING_DEFS:
		var section := VBoxContainer.new()
		section.custom_minimum_size = Vector2(0, 68)
		vbox.add_child(section)

		var header := HBoxContainer.new()
		section.add_child(header)

		var label := Label.new()
		label.text = definition["label"]
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		header.add_child(label)

		var value_label := Label.new()
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		value_label.custom_minimum_size = Vector2(72, 0)
		header.add_child(value_label)
		debug_value_labels[definition["key"]] = value_label

		var slider := HSlider.new()
		slider.min_value = definition["min"]
		slider.max_value = definition["max"]
		slider.step = definition["step"]
		slider.value = get_tuning_value(definition["key"], definition["min"])
		slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slider.value_changed.connect(_on_tuning_slider_changed.bind(definition["key"]))
		section.add_child(slider)
		debug_sliders[definition["key"]] = slider
		update_debug_value_label(definition["key"], slider.value)

	var reset_button := Button.new()
	reset_button.text = "Reset Defaults"
	reset_button.pressed.connect(_on_reset_defaults_pressed)
	vbox.add_child(reset_button)


func toggle_debug_panel() -> void:
	debug_panel_open = not debug_panel_open
	if debug_panel:
		debug_panel.visible = debug_panel_open
	if controlled_player:
		controlled_player.set_mouse_capture(not debug_panel_open)


func _on_tuning_slider_changed(value: float, key: String) -> void:
	tuning[key] = value
	update_debug_value_label(key, value)
	apply_tuning()


func update_debug_value_label(key: String, value: float) -> void:
	if debug_value_labels.has(key):
		debug_value_labels[key].text = "%.3f" % value if key == "mouse_sensitivity" else "%.2f" % value


func _on_reset_defaults_pressed() -> void:
	tuning = DEFAULT_TUNING.duplicate(true)
	for definition in TUNING_DEFS:
		var slider: HSlider = debug_sliders[definition["key"]]
		slider.value = tuning[definition["key"]]
	apply_tuning()


func update_match_clock(delta: float) -> void:
	if match_phase == "finished":
		return
	if restart_timer > 0.0:
		restart_timer = max(0.0, restart_timer - delta)
		if restart_timer == 0.0:
			match_phase = "live"
			clock_running = true
			update_phase_label()
		else:
			update_phase_label()
			return
	if clock_running:
		match_time_left = max(0.0, match_time_left - delta)
		if match_time_left == 0.0:
			clock_running = false
			match_phase = "finished"
			winning_team_name = get_match_winner_name()
			update_phase_label()
	update_clock_label()


func update_clock_label() -> void:
	var total_seconds := int(ceil(match_time_left))
	var minutes := total_seconds / 60
	var seconds := total_seconds % 60
	clock_label.text = "%02d:%02d" % [minutes, seconds]


func update_phase_label() -> void:
	if match_phase == "kickoff":
		phase_label.text = "Kickoff in %.1f" % restart_timer
	elif match_phase == "finished":
		phase_label.text = winning_team_name
	else:
		phase_label.text = "Live Match"


func get_match_winner_name() -> String:
	if score["blue"] > score["red"]:
		return "Blue win the match"
	if score["red"] > score["blue"]:
		return "Red win the match"
	return "Full-time draw"


func assign_controlled_player(player: SoccerPlayer) -> void:
	if player == null:
		return
	if controlled_player and controlled_player != player:
		controlled_player.set_user_controlled(false)
	controlled_player = player
	controlled_player.set_user_controlled(true)
	controlled_player.look_pitch = -0.26
	controlled_player.refresh_visual_state()


func get_best_control_candidate() -> SoccerPlayer:
	var best_player := blue_team[0]
	var best_score := -INF
	for player in blue_team:
		var score_value := -player.global_position.distance_to(ball.global_position)
		if ball.carrier == player:
			score_value += 100.0
		elif ball.carrier and ball.carrier.team_name != "blue":
			score_value += -player.global_position.distance_to(ball.carrier.global_position) * 0.5
		if score_value > best_score:
			best_score = score_value
			best_player = player
	return best_player


func switch_to_best_teammate() -> void:
	assign_controlled_player(get_best_control_candidate())


func restart_match() -> void:
	score["blue"] = 0
	score["red"] = 0
	match_time_left = 180.0
	winning_team_name = ""
	update_score_label()
	update_clock_label()
	reset_after_goal("red")
