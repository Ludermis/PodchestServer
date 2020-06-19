extends Node2D


func _ready():
	randomize()
	Server.startServer()

func _process(delta):
	for i in Vars.rooms:
		Vars.rooms[i].update()

remote func playerJoined (who, msg):
	if msg == "quick1v1":
		var foundRoom = -1
		for i in Vars.rooms:
			if Vars.rooms[i].type == msg && Vars.rooms[i].playerCount < Vars.rooms[i].maxPlayers:
				foundRoom = Vars.rooms[i].id
		if foundRoom == -1:
			var room = preload("res://Scripts/Network/Room.gd").new()
			room.main = get_tree().root.get_node("Main")
			room.id = Vars.roomUniqueID
			room.type = "quick1v1"
			room.gameLength = 90
			room.ready()
			Vars.rooms[room.id] = room
			Vars.players[who]["room"] = room.id
			Vars.rooms[Vars.players[who]["room"]].playerJoined(who)
		else:
			Vars.players[who]["room"] = foundRoom
			Vars.rooms[Vars.players[who]["room"]].playerJoined(who)
	if msg == "quick2v2":
		var foundRoom = -1
		for i in Vars.rooms:
			if Vars.rooms[i].type == msg && Vars.rooms[i].playerCount < Vars.rooms[i].maxPlayers:
				foundRoom = Vars.rooms[i].id
		if foundRoom == -1:
			var room = preload("res://Scripts/Network/Room.gd").new()
			room.main = get_tree().root.get_node("Main")
			room.id = Vars.roomUniqueID
			room.type = "quick2v2"
			room.gameLength = 90
			room.minPlayers = 4
			room.maxPlayers = 4
			room.ready()
			Vars.rooms[room.id] = room
			Vars.players[who]["room"] = room.id
			Vars.rooms[Vars.players[who]["room"]].playerJoined(who)
		else:
			Vars.players[who]["room"] = foundRoom
			Vars.rooms[Vars.players[who]["room"]].playerJoined(who)

remote func demandOnline(who):
	rpc_id(who,"updateStats",{"rooms": Vars.rooms.size(), "playerCount": Vars.playerCount})

remote func leaveRoom (who):
	Vars.rooms[Vars.players[who]["room"]].leaveRoom(who)

remote func demandGameTime (who):
	Vars.rooms[Vars.players[who]["room"]].demandGameTime(who)

remote func readyToGetObjects(who):
	Vars.rooms[Vars.players[who]["room"]].readyToGetObjects(who)

remote func dirtCreated (who, pos, color):
	Vars.rooms[Vars.players[who]["room"]].dirtCreated(who,pos,color)

remote func dirtChanged (who, pos, color):
	Vars.rooms[Vars.players[who]["room"]].dirtChanged(who,pos,color)

remote func updatePosition (who, newPosition):
	Vars.rooms[Vars.players[who]["room"]].updatePosition(who,newPosition)
