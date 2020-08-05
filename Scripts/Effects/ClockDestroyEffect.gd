extends Node

var id
var position
var room
var team
var lifeTimeRemaining = 1.5

func getSharedData ():
	var data = {}
	data["id"] = id
	data["position"] = position
	data["team"] = team
	return data

func _ready():
	pass

func update (delta):
	lifeTimeRemaining -= delta
	if lifeTimeRemaining <= 0:
		destroy()

func destroy ():
	Vars.rooms[room].removeObject(id)
