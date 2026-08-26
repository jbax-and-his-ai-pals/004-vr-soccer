class_name FootKicker
extends Area3D

@export_enum("left", "right") var side := "left"
@export var swing_duration := 0.18
@export var return_duration := 0.14
@export var kick_force := 12.0
@export var lift_force := 2.1
@export var forward_bias := 0.45

var player: SoccerPlayer
var pivot: Node3D
var rest_rotation := Vector3.ZERO
var swing_rotation := Vector3.ZERO
var swing_timer := 0.0
var is_swinging := false
var active_bodies: Array[RigidBody3D] = []
var already_hit := {}
var last_global_position := Vector3.ZERO
var foot_velocity := Vector3.ZERO
var release_triggered := false
var queued_target := Vector3.ZERO
var queued_speed := 0.0
var queued_lift := 0.0
var queued_has_release := false


func _ready() -> void:
	pivot = get_parent() as Node3D
	rest_rotation = pivot.rotation
	var horizontal_sign := -1.0 if side == "left" else 1.0
	swing_rotation = rest_rotation + Vector3(-0.95, 0.35 * horizontal_sign, 0.8 * horizontal_sign)
	last_global_position = global_position
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func set_player_context(controller: SoccerPlayer) -> void:
	player = controller


func _physics_process(delta: float) -> void:
	var swing_action := "kick_left" if side == "left" else "kick_right"
	if player and player.is_user_controlled and not player.is_debug_ui_active() and Input.is_action_just_pressed(swing_action) and not is_swinging:
		var speed := player.get_tuning("pass_speed", 11.0) if side == "left" else player.get_tuning("shot_speed", 18.0)
		var lift := player.get_tuning("pass_lift", 1.7) if side == "left" else player.get_tuning("shot_lift", 3.2)
		var pass_target: SoccerPlayer = player.match_controller.get_best_pass_target(player)
		var target := pass_target.get_receive_point() if side == "left" and pass_target else player.global_position + player.get_forward_vector() * 12.0
		start_swing(target, speed, lift, player.has_ball())

	update_swing(delta)
	foot_velocity = (global_position - last_global_position) / max(delta, 0.001)
	last_global_position = global_position

	if is_swinging:
		if queued_has_release and not release_triggered and swing_timer >= swing_duration * 0.55:
			player.release_ball_toward(queued_target, queued_speed, queued_lift, side, foot_velocity)
			release_triggered = true
		for body in active_bodies:
			try_kick(body)


func start_automated_swing(target_position: Vector3, speed: float, lift: float) -> void:
	if is_swinging:
		return
	start_swing(target_position, speed, lift, true)


func start_swing(target_position: Vector3, speed: float, lift: float, release_ball: bool) -> void:
	is_swinging = true
	swing_timer = 0.0
	release_triggered = false
	already_hit.clear()
	queued_target = target_position
	queued_speed = speed
	queued_lift = lift
	queued_has_release = release_ball


func update_swing(delta: float) -> void:
	if not is_swinging:
		pivot.rotation = pivot.rotation.lerp(rest_rotation, min(1.0, delta / return_duration))
		return

	swing_timer += delta
	var total_duration := swing_duration + return_duration
	if swing_timer <= swing_duration:
		var t := ease(swing_timer / swing_duration, -1.75)
		pivot.rotation = rest_rotation.lerp(swing_rotation, t)
	else:
		var return_t := ease((swing_timer - swing_duration) / return_duration, 0.8)
		pivot.rotation = swing_rotation.lerp(rest_rotation, clamp(return_t, 0.0, 1.0))

	if swing_timer >= total_duration:
		is_swinging = false
		queued_has_release = false
		pivot.rotation = rest_rotation


func try_kick(body: RigidBody3D) -> void:
	if already_hit.has(body):
		return
	if body is SoccerBall and player and player.has_ball():
		return

	var toward_ball := (body.global_position - global_position).normalized()
	var kick_direction: Vector3 = (foot_velocity.normalized() + toward_ball * 0.4 + player.get_forward_vector() * forward_bias).normalized()
	var impulse: Vector3 = kick_direction * kick_force
	impulse.y += lift_force
	body.apply_central_impulse(impulse)
	already_hit[body] = true


func _on_body_entered(body: Node) -> void:
	if body is RigidBody3D:
		active_bodies.append(body)
		if is_swinging:
			try_kick(body)


func _on_body_exited(body: Node) -> void:
	if body is RigidBody3D:
		active_bodies.erase(body)
		already_hit.erase(body)
