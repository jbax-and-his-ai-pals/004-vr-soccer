class_name SoccerPlayer
extends CharacterBody3D

@export var move_speed := 6.4
@export var dribble_speed := 5.3
@export var turn_speed := 2.8
@export var acceleration := 18.0
@export var steal_range := 1.4
@export var pickup_range := 1.35
@export var mouse_sensitivity := 0.0038
@export var min_pitch := -0.6
@export var max_pitch := 0.35

@onready var body_visual: MeshInstance3D = $BodyVisual
@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/Camera3D
@onready var ball_anchor: Node3D = $BallAnchor
@onready var left_foot: FootKicker = $LeftFootPivot/LeftFoot
@onready var right_foot: FootKicker = $RightFootPivot/RightFoot
@onready var body_material: StandardMaterial3D = body_visual.get_active_material(0).duplicate()

var team_name := "blue"
var display_name := "Player"
var role_name := "midfielder"
var team_color := Color(0.2, 0.45, 0.95, 1.0)
var home_position := Vector3.ZERO
var attack_direction := Vector3.FORWARD
var is_user_controlled := false
var teammates: Array[SoccerPlayer] = []
var opponents: Array[SoccerPlayer] = []
var ball: SoccerBall
var match_controller: Node

var ai_kick_cooldown := 0.0
var ai_decision_timer := 0.0
var steal_commit_timer := 0.0
var steal_target: SoccerPlayer
var look_pitch := -0.26
var selected_highlight := 0.0


func _ready() -> void:
	left_foot.set_player_context(self)
	right_foot.set_player_context(self)
	camera.current = is_user_controlled
	if is_user_controlled:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	body_material.albedo_color = team_color
	body_visual.set_surface_override_material(0, body_material)
	refresh_visual_state()


func _physics_process(delta: float) -> void:
	ai_kick_cooldown = max(0.0, ai_kick_cooldown - delta)
	ai_decision_timer = max(0.0, ai_decision_timer - delta)
	steal_commit_timer = max(0.0, steal_commit_timer - delta)

	if is_user_controlled:
		handle_user_input(delta)
	else:
		handle_ai(delta)

	handle_ball_interactions()
	move_and_slide()
	if is_user_controlled:
		update_camera(delta)
	update_selection_feedback(delta)


func handle_user_input(delta: float) -> void:
	if is_debug_ui_active():
		velocity.x = move_toward(velocity.x, 0.0, acceleration * delta)
		velocity.z = move_toward(velocity.z, 0.0, acceleration * delta)
		velocity.y = 0.0
		return

	var move_input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var local_direction := Vector3(move_input.x, 0.0, move_input.y)
	var world_direction := (transform.basis * local_direction).normalized()
	var target_speed := dribble_speed if has_ball() else move_speed
	var target_velocity := world_direction * target_speed

	velocity.x = move_toward(velocity.x, target_velocity.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, target_velocity.z, acceleration * delta)
	velocity.y = 0.0


func handle_ai(delta: float) -> void:
	var desired_target := home_position
	var cpu_speed_scale := get_tuning("cpu_speed_scale", 0.7)
	var desired_speed := move_speed * cpu_speed_scale

	if has_ball():
		desired_target = match_controller.get_attack_goal_position(team_name)
		desired_speed = dribble_speed * cpu_speed_scale
		consider_ai_kick()
	elif ball.carrier == null:
		desired_target = ball.global_position if match_controller.is_closest_on_team_to_ball(self) else match_controller.get_support_spot(self)
	elif ball.carrier.team_name == team_name:
		desired_target = match_controller.get_support_spot(self)
	else:
		if role_name == "goalkeeper":
			desired_target = get_goalkeeper_guard_spot()
		elif match_controller.is_closest_on_team_to_ball(self):
			desired_target = ball.carrier.global_position
		else:
			desired_target = get_marking_position()

	move_toward_position(desired_target, desired_speed, delta)


func move_toward_position(target: Vector3, target_speed: float, delta: float) -> void:
	var to_target := target - global_position
	to_target.y = 0.0
	var direction := to_target.normalized() if to_target.length() > 0.1 else Vector3.ZERO
	var target_velocity := direction * target_speed
	velocity.x = move_toward(velocity.x, target_velocity.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, target_velocity.z, acceleration * delta)
	velocity.y = 0.0

	if direction.length() > 0.01:
		var desired_yaw := atan2(-direction.x, -direction.z)
		rotation.y = rotate_toward(rotation.y, desired_yaw, turn_speed * delta)


func consider_ai_kick() -> void:
	if ai_kick_cooldown > 0.0 or ai_decision_timer > 0.0:
		return

	var goal_position: Vector3 = match_controller.get_attack_goal_position(team_name)
	var goal_distance := global_position.distance_to(goal_position)
	var pressure: float = match_controller.get_closest_opponent_distance(self)
	if goal_distance < get_tuning("shot_distance", 24.0) or pressure < get_tuning("pressure_shot_distance", 3.0):
		right_foot.start_automated_swing(goal_position, get_tuning("shot_speed", 18.5), get_tuning("shot_lift", 3.4))
		ai_kick_cooldown = 1.4
		ai_decision_timer = get_tuning("cpu_decision_interval", 1.4)
		return

	var pass_target: SoccerPlayer = match_controller.get_best_pass_target(self)
	if pass_target:
		left_foot.start_automated_swing(pass_target.get_receive_point(), get_tuning("pass_speed", 11.0), get_tuning("pass_lift", 1.7))
		ai_kick_cooldown = 0.9
		ai_decision_timer = get_tuning("cpu_decision_interval", 1.4)


func handle_ball_interactions() -> void:
	if ball == null:
		return

	if not has_ball() and ball.carrier == null and global_position.distance_to(ball.global_position) <= pickup_range:
		ball.claim_possession(self)
	elif ball.carrier and ball.carrier != self and ball.carrier.team_name != team_name:
		handle_steal_pressure()
	else:
		cancel_steal_attempt()


func handle_steal_pressure() -> void:
	if ball.carrier == null or ball.carrier == self or ball.carrier.team_name == team_name:
		cancel_steal_attempt()
		return

	var distance_to_carrier := global_position.distance_to(ball.carrier.global_position)
	if distance_to_carrier > steal_range:
		cancel_steal_attempt()
		return

	if steal_target != ball.carrier:
		steal_target = ball.carrier
		steal_commit_timer = get_tuning("cpu_steal_delay", 1.2)
		return

	if steal_commit_timer > 0.0:
		return

	if ball.attempt_steal(self):
		ai_decision_timer = get_tuning("cpu_post_steal_delay", 0.8)
	cancel_steal_attempt()


func cancel_steal_attempt() -> void:
	steal_target = null
	steal_commit_timer = 0.0


func update_camera(delta: float) -> void:
	var target_position := Vector3(0.0, 2.8, 4.6)
	camera_pivot.position = camera_pivot.position.lerp(target_position, min(1.0, 7.5 * delta))
	camera_pivot.rotation.x = lerp(camera_pivot.rotation.x, look_pitch, min(1.0, 10.0 * delta))
	camera_pivot.rotation.y = 0.0


func has_ball() -> bool:
	return ball != null and ball.carrier == self


func get_forward_vector() -> Vector3:
	return -transform.basis.z


func get_ball_anchor_position() -> Vector3:
	return ball_anchor.global_position


func release_ball_toward(target_position: Vector3, speed: float, lift: float, side: String, swing_vector: Vector3) -> void:
	if not has_ball():
		return

	var toward_target := (target_position - global_position).normalized()
	var release_direction := (toward_target * 0.65 + get_forward_vector() * 0.35 + swing_vector.normalized() * 0.2).normalized()
	var release_velocity := release_direction * speed
	release_velocity.y = lift
	ball.release_from_carrier(release_velocity, self)


func get_receive_point() -> Vector3:
	return global_position + get_forward_vector() * 1.6


func get_goalkeeper_guard_spot() -> Vector3:
	var defend_goal: Vector3 = match_controller.get_defend_goal_position(team_name)
	var spot: Vector3 = defend_goal + Vector3(clamp(ball.global_position.x * 0.45, -4.0, 4.0), 0.0, get_tuning("goalkeeper_depth", 1.8) * -sign(attack_direction.z))
	return match_controller.clamp_to_field(spot)


func get_marking_position() -> Vector3:
	var threat: SoccerPlayer = opponents[0]
	var best_progress := -INF
	for opponent in opponents:
		var progress := opponent.global_position.z * attack_direction.z
		if opponent.has_ball():
			progress += 20.0
		if progress > best_progress:
			best_progress = progress
			threat = opponent
	var threat_to_goal: Vector3 = (match_controller.get_defend_goal_position(team_name) - threat.global_position).normalized()
	var offset: Vector3 = threat_to_goal * get_tuning("mark_distance", 2.0)
	return match_controller.clamp_to_field(threat.global_position + offset)


func reset_to_home() -> void:
	global_position = home_position
	velocity = Vector3.ZERO
	rotation.y = PI if team_name == "blue" else 0.0
	cancel_steal_attempt()
	ai_decision_timer = 0.0


func get_tuning(key: String, default_value: float) -> float:
	if match_controller and match_controller.has_method("get_tuning_value"):
		return match_controller.get_tuning_value(key, default_value)
	return default_value


func is_debug_ui_active() -> bool:
	return match_controller and match_controller.has_method("is_debug_panel_open") and match_controller.is_debug_panel_open()


func set_mouse_capture(enabled: bool) -> void:
	if is_user_controlled:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if enabled else Input.MOUSE_MODE_VISIBLE


func set_user_controlled(enabled: bool) -> void:
	is_user_controlled = enabled
	camera.current = enabled
	if enabled:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	refresh_visual_state()


func refresh_visual_state() -> void:
	if body_material == null:
		return
	body_material.albedo_color = team_color.lerp(Color(1.0, 1.0, 1.0, 1.0), 0.22) if is_user_controlled else team_color
	body_material.emission_enabled = is_user_controlled
	body_material.emission = team_color.lerp(Color.WHITE, 0.35)
	body_material.emission_energy_multiplier = 0.35 if is_user_controlled else 0.0


func update_selection_feedback(delta: float) -> void:
	selected_highlight = move_toward(selected_highlight, 1.0 if is_user_controlled else 0.0, delta * 4.0)
	if body_material:
		body_material.emission_enabled = selected_highlight > 0.01
		body_material.emission_energy_multiplier = 0.5 * selected_highlight


func _unhandled_input(event: InputEvent) -> void:
	if not is_user_controlled:
		return

	if is_debug_ui_active():
		return

	if event is InputEventMouseButton and event.pressed and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotation.y -= event.relative.x * mouse_sensitivity
		look_pitch = clamp(look_pitch - event.relative.y * mouse_sensitivity, min_pitch, max_pitch)
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
