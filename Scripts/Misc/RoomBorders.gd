extends Node

var main
var position
var room
var body
var shape1
var shape2

func init():
	body = Physics2DServer.body_create()
	Physics2DServer.body_set_mode(body, Physics2DServer.BODY_MODE_STATIC)
	shape1 = RectangleShape2D.new()
	shape1.extents = Vector2(Vars.rooms[room].mapSizeX * Vars.rooms[room].gridSize / 2 + 128,2)
	shape2 = RectangleShape2D.new()
	shape2.extents = Vector2(2,Vars.rooms[room].mapSizeY * Vars.rooms[room].gridSize / 2 + 128)
	Vars.rooms[room].objectsByRID[body] = self
	Physics2DServer.body_add_shape(body, shape1, Transform2D(0,Vector2(Vars.rooms[room].mapSizeX * Vars.rooms[room].gridSize / 2,16)))
	Physics2DServer.body_add_shape(body, shape1, Transform2D(0,Vector2(Vars.rooms[room].mapSizeX * Vars.rooms[room].gridSize / 2,-Vars.rooms[room].mapSizeY * Vars.rooms[room].gridSize + 32)))
	Physics2DServer.body_add_shape(body, shape2, Transform2D(0,Vector2(-16,-Vars.rooms[room].mapSizeY * Vars.rooms[room].gridSize / 2)))
	Physics2DServer.body_add_shape(body, shape2, Transform2D(0,Vector2(Vars.rooms[room].mapSizeX * Vars.rooms[room].gridSize - 48,-Vars.rooms[room].mapSizeY * Vars.rooms[room].gridSize / 2)))
	Physics2DServer.body_set_space(body, Vars.rooms[room].space)
	Physics2DServer.body_set_collision_layer(body, 1)
	Physics2DServer.body_set_collision_mask(body, 1)
	Physics2DServer.body_set_state(body, Physics2DServer.BODY_STATE_TRANSFORM, Transform2D(0, Vector2(position.x, position.y)))

func destroy ():
	Vars.rooms[room].objectsByRID.erase(body)
	Physics2DServer.free_rid(body)
