class_name SoccerBall
extends RigidBody3D

signal possession_changed(previous_owner: SoccerPlayer, new_owner: SoccerPlayer)

const CENTER_POSITION := Vector3(0.0, 0.9, 0.0)
const BALL_RADIUS := 0.42

@onready var mesh_instance: MeshInstance3D = get_node_or_null("MeshInstance3D")

var carrier: SoccerPlayer
var match_controller: Node
var recent_owner: SoccerPlayer
var owner_lock_timer := 0.0
var steal_cooldown := 0.0
var dribble_time := 0.0


func _ready() -> void:
	contact_monitor = true
	max_contacts_reported = 8
	if mesh_instance == null:
		var mesh := MeshInstance3D.new()
		mesh.name = "MeshInstance3D"
		var sphere := SphereMesh.new()
		sphere.radius = 0.42
		sphere.height = 0.84
		mesh.mesh = sphere
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(0.98, 0.98, 0.95, 1.0)
		mesh.set_surface_override_material(0, material)
		add_child(mesh)
		mesh_instance = mesh
	reset_to_center()


func _physics_process(delta: float) -> void:
	owner_lock_timer = max(0.0, owner_lock_timer - delta)
	steal_cooldown = max(0.0, steal_cooldown - delta)
	dribble_time += delta

	if carrier:
		freeze = true
		global_position = get_carried_ball_position(delta)
		linear_velocity = Vector3.ZERO
		angular_velocity = get_carried_ball_spin()
	elif global_position.y < -4.0:
		reset_to_center()
	else:
		freeze = false
		apply_ground_friction(delta)


func claim_possession(player: SoccerPlayer, force: bool = false) -> bool:
	if player == null:
		return false
	if carrier == player:
		return true
	if recent_owner == player and owner_lock_timer > 0.0 and not force:
		return false

	var previous_owner := carrier
	carrier = player
	dribble_time = 0.0
	freeze = true
	sleeping = false
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	possession_changed.emit(previous_owner, carrier)
	return true


func attempt_steal(player: SoccerPlayer) -> bool:
	if carrier == null:
		return claim_possession(player)
	if carrier.team_name == player.team_name or steal_cooldown > 0.0:
		return false
	if player.velocity.length() < 2.0 and not player.is_user_controlled:
		return false

	var previous_owner := carrier
	recent_owner = previous_owner
	owner_lock_timer = 0.5
	steal_cooldown = 0.85
	carrier = player
	freeze = true
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	possession_changed.emit(previous_owner, carrier)
	return true


func release_from_carrier(release_velocity: Vector3, previous_owner: SoccerPlayer) -> void:
	if carrier == null:
		return
	recent_owner = previous_owner
	owner_lock_timer = 0.32
	steal_cooldown = 0.2
	carrier = null
	freeze = false
	global_position += previous_owner.get_forward_vector() * 0.75
	linear_velocity = release_velocity
	angular_velocity = Vector3(6.0, 3.0, 1.5)
	possession_changed.emit(previous_owner, null)


func reset_to_center() -> void:
	carrier = null
	recent_owner = null
	owner_lock_timer = 0.0
	steal_cooldown = 0.0
	dribble_time = 0.0
	freeze = false
	global_position = CENTER_POSITION
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO


func get_carried_ball_position(delta: float) -> Vector3:
	var anchor: Vector3 = carrier.get_ball_anchor_position()
	var move_speed: float = carrier.velocity.length()
	var speed_factor: float = clamp(move_speed / max(carrier.move_speed, 0.01), 0.0, 1.3)
	var forward: Vector3 = carrier.get_forward_vector()
	var right: Vector3 = carrier.transform.basis.x.normalized()
	var side_sway: float = sin(dribble_time * lerp(3.5, 8.5, speed_factor)) * get_tuning_value("ball_dribble_sway", 0.17) * speed_factor
	var forward_pulse: float = 0.15 + get_tuning_value("ball_dribble_forward", 0.32) * speed_factor
	var bounce_height: float = abs(sin(dribble_time * lerp(4.5, 10.0, speed_factor))) * get_tuning_value("ball_dribble_bounce", 0.2) * (0.25 + speed_factor)
	var target: Vector3 = anchor + forward * forward_pulse + right * side_sway
	target.y = max(BALL_RADIUS + 0.02, target.y + bounce_height)
	return global_position.lerp(target, min(1.0, delta * get_tuning_value("ball_carry_follow", 18.0)))


func get_carried_ball_spin() -> Vector3:
	var speed_factor: float = clamp(carrier.velocity.length() / max(carrier.move_speed, 0.01), 0.0, 1.5)
	return Vector3(0.0, lerp(1.2, 7.5, speed_factor), 0.0)


func apply_ground_friction(delta: float) -> void:
	var horizontal_velocity := Vector3(linear_velocity.x, 0.0, linear_velocity.z)
	var is_grounded := get_contact_count() > 0 or global_position.y <= BALL_RADIUS + 0.08
	if is_grounded:
		var friction_strength := get_tuning_value("ball_ground_friction", 6.0)
		horizontal_velocity = horizontal_velocity.move_toward(Vector3.ZERO, friction_strength * delta)
		angular_velocity = angular_velocity.move_toward(Vector3.ZERO, get_tuning_value("ball_roll_damping", 4.2) * delta)
	else:
		horizontal_velocity = horizontal_velocity.move_toward(Vector3.ZERO, get_tuning_value("ball_air_drag", 0.45) * delta)

	linear_velocity.x = horizontal_velocity.x
	linear_velocity.z = horizontal_velocity.z
	linear_velocity.y = move_toward(linear_velocity.y, linear_velocity.y, 0.0)


func get_tuning_value(key: String, default_value: float) -> float:
	if match_controller and match_controller.has_method("get_tuning_value"):
		return match_controller.get_tuning_value(key, default_value)
	return default_value
