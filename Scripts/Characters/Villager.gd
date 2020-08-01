extends "res://Scripts/Base/Character.gd"

var scytheActive = false
var scytheRotation = 0

func getSharedData ():
	var data = {}
	data["position"] = position
	data["skin"] = skin
	data["team"] = team
	data["playerName"] = playerName
	data["id"] = id
	return data

func update (delta):
	movementHandler(delta)
	
	for i in Vars.rooms[room].playerIDS:
		main.rpc_id(i,"objectUpdated",-1,id,getSharedData())

func init():
	characterName = "Villager"
	body = Physics2DServer.body_create()
	Physics2DServer.body_set_mode(body, Physics2DServer.BODY_MODE_CHARACTER)
	shape = CircleShape2D.new()
	shape.radius = 6.5
	Physics2DServer.body_add_shape(body, shape, Transform2D(0,Vector2(0,-4.5)))
	Physics2DServer.body_set_space(body, Vars.rooms[room].space)
	Physics2DServer.body_set_param(body,Physics2DServer.BODY_PARAM_FRICTION,0)
	Physics2DServer.body_set_collision_layer(body, 1)
	Physics2DServer.body_set_collision_mask(body, 0)
	Physics2DServer.body_set_state(body, Physics2DServer.BODY_STATE_TRANSFORM, Transform2D(0, Vector2(position.x, position.y)))
