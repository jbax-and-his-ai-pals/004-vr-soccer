class_name ArenaBuilder
extends Node3D

var field_half_width := 17.0
var field_half_length := 25.0


func _ready() -> void:
	if get_child_count() == 0:
		build_arena()


func build_arena() -> void:
	for child in get_children():
		child.queue_free()

	var grass := create_static_box("Field", Vector3(field_half_width * 2.0, 0.4, field_half_length * 2.0), Vector3(0, -0.2, 0), Color(0.2, 0.68, 0.32))
	add_child(grass)

	build_field_markings()
	build_boundaries()
	build_goals()
	build_stands()
	build_crowd()


func build_field_markings() -> void:
	var line_color := Color(0.94, 0.97, 0.95, 1.0)
	add_child(create_visual_box("MidLine", Vector3(field_half_width * 2.0, 0.03, 0.14), Vector3(0, 0.02, 0), line_color))
	add_child(create_visual_box("LeftSideLine", Vector3(0.14, 0.03, field_half_length * 2.0), Vector3(-field_half_width, 0.02, 0), line_color))
	add_child(create_visual_box("RightSideLine", Vector3(0.14, 0.03, field_half_length * 2.0), Vector3(field_half_width, 0.02, 0), line_color))
	add_child(create_visual_box("TopLine", Vector3(field_half_width * 2.0, 0.03, 0.14), Vector3(0, 0.02, field_half_length), line_color))
	add_child(create_visual_box("BottomLine", Vector3(field_half_width * 2.0, 0.03, 0.14), Vector3(0, 0.02, -field_half_length), line_color))

	var center_ring := MeshInstance3D.new()
	center_ring.name = "CenterCircle"
	var torus := TorusMesh.new()
	torus.inner_radius = 2.7
	torus.outer_radius = 3.0
	torus.rings = 32
	torus.ring_segments = 8
	center_ring.mesh = torus
	center_ring.position.y = 0.05
	var circle_material := StandardMaterial3D.new()
	circle_material.albedo_color = line_color
	circle_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	center_ring.set_surface_override_material(0, circle_material)
	add_child(center_ring)

	build_box_markings("BlueBox", -1.0)
	build_box_markings("RedBox", 1.0)


func build_box_markings(prefix: String, sign_z: float) -> void:
	var line_color := Color(0.94, 0.97, 0.95, 1.0)
	var goal_line_z := field_half_length * sign_z
	var box_depth := 6.2 * sign_z
	var small_box_depth := 2.9 * sign_z
	add_child(create_visual_box("%sPenaltyTop" % prefix, Vector3(12.0, 0.03, 0.12), Vector3(0, 0.02, goal_line_z - box_depth), line_color))
	add_child(create_visual_box("%sPenaltyLeft" % prefix, Vector3(0.12, 0.03, abs(box_depth)), Vector3(-6.0, 0.02, goal_line_z - box_depth * 0.5), line_color))
	add_child(create_visual_box("%sPenaltyRight" % prefix, Vector3(0.12, 0.03, abs(box_depth)), Vector3(6.0, 0.02, goal_line_z - box_depth * 0.5), line_color))
	add_child(create_visual_box("%sGoalTop" % prefix, Vector3(5.2, 0.03, 0.12), Vector3(0, 0.02, goal_line_z - small_box_depth), line_color))
	add_child(create_visual_box("%sGoalLeft" % prefix, Vector3(0.12, 0.03, abs(small_box_depth)), Vector3(-2.6, 0.02, goal_line_z - small_box_depth * 0.5), line_color))
	add_child(create_visual_box("%sGoalRight" % prefix, Vector3(0.12, 0.03, abs(small_box_depth)), Vector3(2.6, 0.02, goal_line_z - small_box_depth * 0.5), line_color))


func build_boundaries() -> void:
	var wall_color := Color(0.18, 0.27, 0.31, 1.0)
	add_child(create_static_box("LeftWall", Vector3(0.8, 5.5, field_half_length * 2.0 + 18.0), Vector3(-field_half_width - 1.1, 2.75, 0), wall_color))
	add_child(create_static_box("RightWall", Vector3(0.8, 5.5, field_half_length * 2.0 + 18.0), Vector3(field_half_width + 1.1, 2.75, 0), wall_color))
	add_child(create_static_box("NorthWall", Vector3(field_half_width * 2.0 + 3.8, 5.5, 0.8), Vector3(0, 2.75, field_half_length + 4.9), wall_color))
	add_child(create_static_box("SouthWall", Vector3(field_half_width * 2.0 + 3.8, 5.5, 0.8), Vector3(0, 2.75, -field_half_length - 4.9), wall_color))

	var board_color := Color(0.08, 0.14, 0.2, 1.0)
	add_child(create_visual_box("NorthBoards", Vector3(field_half_width * 2.0 + 2.2, 1.3, 0.24), Vector3(0, 0.65, field_half_length + 0.95), board_color))
	add_child(create_visual_box("SouthBoards", Vector3(field_half_width * 2.0 + 2.2, 1.3, 0.24), Vector3(0, 0.65, -field_half_length - 0.95), board_color))
	add_child(create_visual_box("LeftBoards", Vector3(0.24, 1.3, field_half_length * 2.0 + 1.5), Vector3(-field_half_width - 0.95, 0.65, 0), board_color))
	add_child(create_visual_box("RightBoards", Vector3(0.24, 1.3, field_half_length * 2.0 + 1.5), Vector3(field_half_width + 0.95, 0.65, 0), board_color))


func build_goals() -> void:
	add_child(create_goal_structure("SouthGoal", Vector3(0, 0, -field_half_length + 0.35), -1.0))
	add_child(create_goal_structure("NorthGoal", Vector3(0, 0, field_half_length - 0.35), 1.0))


func create_goal_structure(name: String, origin: Vector3, sign_z: float) -> Node3D:
	var root := Node3D.new()
	root.name = name
	root.position = origin

	var post_color := Color(0.96, 0.97, 1.0, 1.0)
	var net_color := Color(0.92, 0.95, 1.0, 0.2)
	var post_width := 0.18
	var goal_width := 7.4
	var goal_height := 3.0
	var goal_depth := 3.4

	root.add_child(create_static_box("Crossbar", Vector3(goal_width, post_width, post_width), Vector3(0, goal_height, 0), post_color))
	root.add_child(create_static_box("LeftPost", Vector3(post_width, goal_height, post_width), Vector3(-goal_width * 0.5, goal_height * 0.5, 0), post_color))
	root.add_child(create_static_box("RightPost", Vector3(post_width, goal_height, post_width), Vector3(goal_width * 0.5, goal_height * 0.5, 0), post_color))

	root.add_child(create_static_box("BackNetCollision", Vector3(goal_width, goal_height, 0.12), Vector3(0, goal_height * 0.5, sign_z * goal_depth), Color(1, 1, 1, 0.02), false))
	root.add_child(create_static_box("LeftNetCollision", Vector3(0.12, goal_height, goal_depth), Vector3(-goal_width * 0.5, goal_height * 0.5, sign_z * goal_depth * 0.5), Color(1, 1, 1, 0.02), false))
	root.add_child(create_static_box("RightNetCollision", Vector3(0.12, goal_height, goal_depth), Vector3(goal_width * 0.5, goal_height * 0.5, sign_z * goal_depth * 0.5), Color(1, 1, 1, 0.02), false))

	root.add_child(create_translucent_panel("BackNet", Vector3(goal_width, goal_height, 0.02), Vector3(0, goal_height * 0.5, sign_z * goal_depth), net_color))
	root.add_child(create_translucent_panel("TopNet", Vector3(goal_width, goal_depth, 0.02), Vector3(0, goal_height, sign_z * goal_depth * 0.5), net_color, Vector3(90, 0, 0)))
	root.add_child(create_translucent_panel("LeftNet", Vector3(goal_depth, goal_height, 0.02), Vector3(-goal_width * 0.5, goal_height * 0.5, sign_z * goal_depth * 0.5), net_color, Vector3(0, 90, 0)))
	root.add_child(create_translucent_panel("RightNet", Vector3(goal_depth, goal_height, 0.02), Vector3(goal_width * 0.5, goal_height * 0.5, sign_z * goal_depth * 0.5), net_color, Vector3(0, 90, 0)))

	return root


func build_stands() -> void:
	var stand_color := Color(0.56, 0.62, 0.68, 1.0)
	add_child(create_visual_box("NorthStand", Vector3(field_half_width * 2.0 + 12.0, 5.5, 8.0), Vector3(0, 2.75, field_half_length + 10.0), stand_color))
	add_child(create_visual_box("SouthStand", Vector3(field_half_width * 2.0 + 12.0, 5.5, 8.0), Vector3(0, 2.75, -field_half_length - 10.0), stand_color))
	add_child(create_visual_box("WestStand", Vector3(8.0, 5.5, field_half_length * 2.0 + 6.0), Vector3(-field_half_width - 8.5, 2.75, 0), stand_color))
	add_child(create_visual_box("EastStand", Vector3(8.0, 5.5, field_half_length * 2.0 + 6.0), Vector3(field_half_width + 8.5, 2.75, 0), stand_color))
	add_child(create_visual_box("RoofRing", Vector3(field_half_width * 2.0 + 24.0, 0.8, field_half_length * 2.0 + 24.0), Vector3(0, 10.2, 0), Color(0.13, 0.18, 0.24, 1.0)))


func build_crowd() -> void:
	var crowd := MultiMeshInstance3D.new()
	crowd.name = "Crowd"
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	var crowd_mesh := SphereMesh.new()
	crowd_mesh.radius = 0.18
	crowd_mesh.height = 0.36
	multimesh.mesh = crowd_mesh
	var transforms: Array[Transform3D] = []

	for side in [-1.0, 1.0]:
		for row in 6:
			for seat in 42:
				var x: float = lerp(-field_half_width - 4.5, field_half_width + 4.5, float(seat) / 41.0)
				var z: float = side * (field_half_length + 7.8 + row * 0.55)
				var y: float = 2.7 + row * 0.24
				transforms.append(Transform3D(Basis(), Vector3(x, y, z)))
		for row in 6:
			for seat in 62:
				var z_side: float = lerp(-field_half_length + 4.0, field_half_length - 4.0, float(seat) / 61.0)
				var x_side: float = side * (field_half_width + 7.2 + row * 0.5)
				var y_side: float = 2.7 + row * 0.24
				transforms.append(Transform3D(Basis().rotated(Vector3.UP, PI * 0.5), Vector3(x_side, y_side, z_side)))

	multimesh.instance_count = transforms.size()
	for i in transforms.size():
		multimesh.set_instance_transform(i, transforms[i])
	crowd.multimesh = multimesh

	var crowd_material := StandardMaterial3D.new()
	crowd_material.albedo_color = Color(0.93, 0.72, 0.32, 1.0)
	crowd_material.vertex_color_use_as_albedo = false
	crowd.material_override = crowd_material
	add_child(crowd)


func create_static_box(name: String, size: Vector3, position: Vector3, color: Color, visible: bool = true) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = name
	body.position = position

	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)

	if visible:
		var mesh_instance := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = size
		mesh_instance.mesh = box
		var material := StandardMaterial3D.new()
		material.albedo_color = color
		material.roughness = 0.92
		mesh_instance.set_surface_override_material(0, material)
		body.add_child(mesh_instance)

	return body


func create_visual_box(name: String, size: Vector3, position: Vector3, color: Color) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = name
	mesh_instance.position = position
	var box := BoxMesh.new()
	box.size = size
	mesh_instance.mesh = box
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.9
	mesh_instance.set_surface_override_material(0, material)
	return mesh_instance


func create_translucent_panel(name: String, size: Vector3, position: Vector3, color: Color, rotation_degrees_vector: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var panel := MeshInstance3D.new()
	panel.name = name
	panel.position = position
	panel.rotation_degrees = rotation_degrees_vector
	var plane := PlaneMesh.new()
	plane.size = Vector2(size.x, size.y)
	panel.mesh = plane
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	panel.set_surface_override_material(0, material)
	return panel
