extends "res://Scripts/Base/Character.gd"

var scytheActive = false
var scytheRotation = 0
var mousePos = Vector2.ZERO
var scytheTimerID

func getSharedData ():
	var data = {}
	data["position"] = position
	data["skin"] = skin
	data["team"] = team
	data["playerName"] = playerName
	data["animation"] = animation
	data["scytheRotation"] = scytheRotation
	data["scytheActive"] = scytheActive
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

func scytheTimerTimeout ():
	var optimizedPos = Vars.optimizeVector(position + Vector2(32,32),64)
	var vec = (mousePos - optimizedPos).normalized()
	vec = Vars.optimizeVector(optimizedPos + vec * 64 + Vector2(32,32), 64)
	dirtToPos(vec)

func dirtToPos (pos):
	if !Vars.rooms[room].dirts.has(pos):
		Vars.tryPlaceDirt(room,id,pos,team)
	elif Vars.rooms[room].dirts[pos].team != team:
		Vars.tryChangeDirt(room,id,pos,team)

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
	newUniqueTimerID()
	scytheTimerID = uniqueTimerID
	timers[scytheTimerID] = CustomTimer.new()
	timers[scytheTimerID].time = 0.005
	timers[scytheTimerID].connect("timeout",self,"scytheTimerTimeout")
	
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
	
	skills[3] = preload("res://Scripts/Skills/Villager/VillagerRSkill.gd").new()
	skills[3].id = 3
	skills[3].main = main
	skills[3].characterScript = self
