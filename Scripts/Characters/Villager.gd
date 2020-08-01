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

func _init():
	characterName = "Villager"

func update (delta):
	if pressed["left"]:
		position.x -= delta * 256
	if pressed["right"]:
		position.x += delta * 256
	if pressed["up"]:
		position.y -= delta * 256
	if pressed["down"]:
		position.y += delta * 256
	
	for i in Vars.rooms[room].playerIDS:
		main.rpc_id(i,"objectUpdated",-1,id,getSharedData())

func readyCustom():
	pass

func _ready():
	pass
