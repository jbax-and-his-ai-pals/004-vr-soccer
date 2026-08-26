extends Area3D

signal goal_scored(team_name: String)

@export_enum("blue", "red") var team_name := "blue"
var cooldown := false


func _ready() -> void:
	monitoring = true
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if cooldown:
		return
	if body is SoccerBall:
		cooldown = true
		goal_scored.emit(team_name)
		await get_tree().create_timer(0.5).timeout
		cooldown = false
