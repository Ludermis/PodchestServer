extends "res://Scripts/Base/Character.gd"

var scytheActive = false
var scytheRotation = 0

func getSharedData ():
	var data = {}
	data["position"] = position
	data["skin"] = skin
	data["team"] = team
	data["playerName"] = playerName
	data["animation"] = animation
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
	characterName = "Villager"
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
	Physics2DServer.body_set_collision_layer(body, 1)
	Physics2DServer.body_set_collision_mask(body, 0)
	Physics2DServer.body_set_state(body, Physics2DServer.BODY_STATE_TRANSFORM, Transform2D(0, Vector2(position.x, position.y)))
	
	skills[1] = preload("res://Scripts/Skills/Villager/VillagerQSkill.gd").new()
	skills[1].id = 1
	skills[1].main = main
	skills[1].characterScript = self
	
	skills[2] = preload("res://Scripts/Skills/Villager/VillagerESkill.gd").new()
	skills[2].id = 2
	skills[2].main = main
	skills[2].characterScript = self
