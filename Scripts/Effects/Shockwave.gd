extends Node

var id
var position
var room
var lifeTimeRemaining = 1.0

func getSharedData ():
	var data = {}
	data["id"] = id
	data["position"] = position
	return data

func _ready():
	pass

func update (delta):
	lifeTimeRemaining -= delta
	if lifeTimeRemaining <= 0:
		destroy()

func destroy ():
	Vars.rooms[room].removeObject(id)
