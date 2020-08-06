extends "res://Scripts/Base/Character.gd"

var clocks = []

func getSharedData ():
	var data = {}
	data["pos"] = position
	data["skin"] = skin
	data["team"] = team
	data["playerName"] = playerName
	data["animation"] = animation
	data["canMove"] = canMove
	data["maxSpeed"] = maxSpeed
	data["acceleration"] = acceleration
	data["id"] = id
	return data

func update (delta):
	inputHandler(delta)
	movementHandler(delta)
	skillSystem(delta)
	impactSystem(delta)
	for i in timers:
		timers[i].update(delta)
	
	Vars.rooms[room].updateObject(id,getSharedData())

func init():
	characterName = "Xedarin"
	newUniqueTimerID()
	timers[uniqueTimerID] = CustomTimer.new()
	timers[uniqueTimerID].time = 0.1
	timers[uniqueTimerID].connect("timeout",self,"_on_DirectionTimer_timeout")
	timers[uniqueTimerID].start()
	newUniqueTimerID()
	timers[uniqueTimerID] = CustomTimer.new()
	timers[uniqueTimerID].time = 0.1
	timers[uniqueTimerID].connect("timeout",self,"_on_DirtTimer_timeout")
	timers[uniqueTimerID].start()
	
	body = Physics2DServer.body_create()
	Vars.rooms[room].objectsByRID[body] = self
	Physics2DServer.body_set_mode(body, Physics2DServer.BODY_MODE_CHARACTER)
	shape = CircleShape2D.new()
	shape.radius = 6.5
	Physics2DServer.body_add_shape(body, shape, Transform2D(0,Vector2(0,-4.5)))
	Physics2DServer.body_set_space(body, Vars.rooms[room].space)
	Physics2DServer.body_set_param(body,Physics2DServer.BODY_PARAM_FRICTION,0)
	Physics2DServer.body_set_param(body,Physics2DServer.BODY_PARAM_LINEAR_DAMP,0)
	Physics2DServer.body_set_collision_layer(body, 1)
	Physics2DServer.body_set_collision_mask(body, 0)
	Physics2DServer.body_set_state(body, Physics2DServer.BODY_STATE_TRANSFORM, Transform2D(0, position))
	
	area = Physics2DServer.area_create()
	Vars.rooms[room].objectsByRID[area] = self
	areaShape = RectangleShape2D.new()
	areaShape.extents = Vector2(8 * 4, 14 * 4)
	Physics2DServer.area_add_shape(area, areaShape, Transform2D(0,Vector2(0,-12)))
	Physics2DServer.area_set_space(area, Vars.rooms[room].space)
	Physics2DServer.area_set_collision_layer(area, 1)
	Physics2DServer.area_set_collision_mask(area, 1)
	Physics2DServer.area_set_transform(area,Transform2D(0,position))
	Physics2DServer.area_set_monitorable(area, true)
	
	skills[1] = preload("res://Scripts/Skills/Xedarin/XedarinQSkill.gd").new()
	skills[1].id = 1
	skills[1].main = main
	skills[1].characterScript = self
	
	skills[2] = preload("res://Scripts/Skills/Xedarin/XedarinESkill.gd").new()
	skills[2].id = 2
	skills[2].main = main
	skills[2].characterScript = self
	
	skills[3] = preload("res://Scripts/Skills/Xedarin/XedarinRSkill.gd").new()
	skills[3].id = 3
	skills[3].main = main
	skills[3].characterScript = self
